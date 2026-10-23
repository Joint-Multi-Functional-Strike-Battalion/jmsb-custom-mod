#include "script_component.hpp"
/*
 * Author: JMSB
 * The watch on one CAS sortie, every AIR_TICK seconds. Phases:
 *
 *   "entry"    a synced aircraft flying to its ingress point before it
 *              turns in (FUNC(casLaunch))
 *   "in"       inbound. A RUN releases in CAS_RELEASE_RING of the grid
 *              (FUNC(casStrike)) and turns out the run-in distance past it;
 *              a SAD or LOITER enters an orbit of the requested radius and
 *              goes on station
 *   "out"      turning out after a pass on the egress bearing (straight
 *              through without one); far enough, it comes round for the
 *              next one - by the ingress point when there is one - or goes
 *              home when the passes are flown
 *   "station"  orbiting. A SAD looks for something to hit every CAS_SAD_EVERY
 *              seconds; a LOITER holds weapons tight. A new SAD or LOITER
 *              moves the orbit (FUNC(casOrder)); a minute before the time
 *              on station is up the side is told, and then it leaves
 *   home legs  FUNC(homeTick)
 *
 * Recall, the sortie running out of time and the aircraft running dry all
 * send it home; a wreck ends the sortie where it lies. A release held for
 * friendlies near the aim (no DANGER CLOSE) is said once and flown dry.
 *
 * Arguments:
 * 0: [logic, aircraft, state] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(casTick), 1, [_logic, _veh, _st]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params ["_logic", "_veh", "_st"];

if (isNull _logic) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_veh] call FUNC(sweep);
};

if (!alive _veh) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_logic] call FUNC(finish);
};

private _phase = _st get "phase";
if (_phase in ["home", "homing", "parking"]) exitWith {
    if ([_logic, _veh, _st] call FUNC(homeTick)) then {[_handle] call CBA_fnc_removePerFrameHandler};
};

private _requester = _st get "requester";

if ((_logic getVariable [QGVAR(abort), false]) || {CBA_missionTime > (_st get "until")}) exitWith {
    _logic setVariable [QGVAR(abort), false, true];
    [_logic, "off station, returning to base", "normal", _requester] call FUNC(say);
    _st set ["phase", "home"];
};

private _plane = _veh isKindOf "Plane";
private _fnc_orbit = {
    // A JET DOES NOT ORBIT AT "LIMITED". The first loiter flown (RPT 2026-10-20)
    // put an A-164 down 87 s after it came on station with no killer: slow and
    // tight in a turn is a stall. Planes orbit at normal speed and no tighter
    // than PLANE_ORBIT_MIN; helicopters keep the slow orbit.
    [_veh, _st get "pos", ["LIMITED", "NORMAL"] select _plane, "LOITER", [_st get "radius", (_st get "radius") max PLANE_ORBIT_MIN] select _plane] call FUNC(moveTo);
};

// REPOSITIONED ON STATION (FUNC(casOrder)): the same sortie, a new grid. The
// time on station keeps running.
private _move = _logic getVariable [QGVAR(reposition), []];
if (_move isNotEqualTo [] && _phase isEqualTo "station") then {
    _logic setVariable [QGVAR(reposition), nil];
    _move params ["_newMode", "_newPos", "_newRadius", "_newAlt", "_newMag", "_newDanger", "_who"];
    {_st set _x} forEach [["mode", _newMode], ["pos", _newPos], ["radius", _newRadius], ["danger", _newDanger], ["requester", _who], ["next", 0], ["heldSaid", false]];
    _requester = _who;
    [group driver _veh, _newMode] call FUNC(casPosture);
    _veh setVariable [QEGVAR(cas,ordnance), _newMag];
    _veh flyInHeight _newAlt;
    call _fnc_orbit;
    _logic setVariable [QGVAR(plan), [[_newPos, toUpper _newMode]], true];
};

private _mode = _st get "mode";
private _pos = _st get "pos";
private _radius = _st get "radius";
private _d = _veh distance2D _pos;

// One release. A release held because friendlies are near the aim is said
// once a sortie, and the pass is flown dry.
private _fnc_strike = {
    params ["_search", "_how"];
    private _res = [_logic, _veh, _pos, _search, _how, _requester, _st getOrDefault ["danger", false]] call FUNC(casStrike);
    if (_res isEqualTo "unsafe" && {!(_st getOrDefault ["heldSaid", false])}) then {
        _st set ["heldSaid", true];
        [_logic, format ["holding - friendlies within %1 m of the target, call DANGER CLOSE to clear it", _logic getVariable [QGVAR(friendlyRange), 0]], "high", _requester, false] call FUNC(say);
    };
    _res
};

switch (_phase) do {
    case "entry": {
        if (_veh distance2D (_st get "entry") > CAS_ENTRY_RING) exitWith {};
        [_veh, _pos, ["NORMAL", "FULL"] select (_mode isEqualTo "run")] call FUNC(moveTo);
        _st set ["phase", "in"];
        _logic setVariable [QGVAR(status), ["inbound", "attacking"] select (_mode isEqualTo "run"), true];
    };
    case "in": {
        if (_mode isEqualTo "run") exitWith {
            if (_d > CAS_RELEASE_RING) exitWith {};
            if (([_logic getVariable [QGVAR(searchRadius), 0], "run"] call _fnc_strike) isEqualTo "dry") exitWith {
                [_logic, "is Winchester, returning to base", "normal", _requester] call FUNC(say);
                _st set ["phase", "home"];
            };
            private _outDir = _st getOrDefault ["outDir", -1];
            if (_outDir < 0) then {_outDir = _veh getDir _pos};
            [_veh, _pos getPos [_logic getVariable [QGVAR(runIn), 3000], _outDir], "FULL"] call FUNC(moveTo);
            _st set ["phase", "out"];
            _logic setVariable [QGVAR(status), "off target", true];
        };

        if (_d > _radius + CAS_STATION_EXTRA) exitWith {};
        call _fnc_orbit;
        _st set ["phase", "station"];
        _st set ["until", CBA_missionTime + (_logic getVariable [QGVAR(stationTime), 600])];
        _logic setVariable [QGVAR(status), "on station", true];
        [_logic, format ["on station over %1", mapGridPosition _pos], "normal", _requester] call FUNC(say);
    };
    case "out": {
        if (_d < 0.8 * (_logic getVariable [QGVAR(runIn), 3000])) exitWith {};
        private _passes = (_st get "passes") - 1;
        _st set ["passes", _passes];
        if (_passes <= 0) exitWith {
            [_logic, "run complete, returning to base", "normal", _requester] call FUNC(say);
            _st set ["phase", "home"];
        };
        private _entry = _st getOrDefault ["entry", []];
        if (_entry isNotEqualTo []) exitWith {
            [_veh, _entry, "FULL"] call FUNC(moveTo);
            _st set ["phase", "entry"];
            _logic setVariable [QGVAR(status), "re-attacking", true];
        };
        [_veh, _pos, "FULL"] call FUNC(moveTo);
        _st set ["phase", "in"];
        _logic setVariable [QGVAR(status), "attacking", true];
    };
    case "station": {
        if (!(_st getOrDefault ["warned", false]) && {(_st get "until") - CBA_missionTime < STATION_WARNING}) then {
            _st set ["warned", true];
            [_logic, "leaving the area in one minute", "normal", _requester] call FUNC(say);
        };
        if (_mode isNotEqualTo "sad" || {CBA_missionTime < (_st get "next")}) exitWith {};
        _st set ["next", CBA_missionTime + CAS_SAD_EVERY];
        if (([_radius, "sad"] call _fnc_strike) isEqualTo "dry") then {
            [_logic, "is Winchester, returning to base", "normal", _requester] call FUNC(say);
            _st set ["phase", "home"];
        };
    };
};
