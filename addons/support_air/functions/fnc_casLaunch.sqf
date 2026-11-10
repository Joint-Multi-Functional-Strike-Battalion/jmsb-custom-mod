#include "script_component.hpp"
/*
 * Author: YonV
 * Puts a CAS sortie in the air and starts its watch (FUNC(casTick)).
 *
 * TWO WAYS TO FLY IT, by task:
 *
 *   ATTACK RUN and LOITER - the AI flies and nothing else. CARELESS, BLUE,
 *   targeting off: the same reasoning as the CAS drones (addons/cas
 *   FUNC(request)) - air AI handed a target decides for itself whether to
 *   shoot it, so every release is the drones' pass (FUNC(casStrike),
 *   2026-11-05: lined up on the ingress bearing, dived on the aim, the salvo
 *   on a solution) and nothing else.
 *
 *   SAD - the crew is let off the leash: COMBAT, RED, targeting on, holding
 *   an orbit over the grid. The watch adds the passes on what is painted or
 *   known (FUNC(casStrike)) so a SAD that the AI is shy about still puts
 *   ordnance down.
 *
 * WHERE IT COMES FROM - VIRTUAL UNTIL TASKED (user, 2026-11-02: "all support
 * aircraft needs to be virtual till tasked, then they spawn in at alt over the
 * support module location"). A CLASS aircraft is made now, over the module, at
 * its height - a helicopter nap of the earth, a jet at 4000 m - engines on and
 * flying (FUNC(spawnAircraft)), full of fuel and stores. A SYNCED aircraft
 * takes off from its stand. Either one with an INGRESS picked flies to the
 * run-in point on that bearing first and turns in from there. When the sortie
 * is over it flies home to the module - a class aircraft is removed there,
 * virtual again; a synced one is parked (FUNC(homeTick)).
 *
 * TACTICAL (user, 2026-11-01). The height is the support core's: a
 * helicopter flies nap of the earth throughout, on station too; a fixed-wing
 * attacks at 4000 m ATL and, on a SAD or LOITER, holds 8 km off the map
 * (EFUNC(support,holdPoint)) - the flow's station: it flies there from the
 * module, not to the grid, and comes in from there to strike (FUNC(casTick)).
 * Dark away from its airfield (FUNC(prepareAircraft)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: "sad", "loiter" or "run" <STRING>
 * 2: Target position ATL <ARRAY>
 * 3: Orbit radius (a helicopter's), SAD search radius, m <NUMBER>
 * 4: Passes, for a run <NUMBER>
 * 5: Magazine class to use, "" for the heaviest aboard <STRING>
 * 6: Who asked <OBJECT>
 * 7: Options - "ingress", "egress" (points, [] for auto), "danger" (BOOL), "clear" (BOOL, hold a run short until CLEARED HOT), "stationTime" (s), "flow" (FUNC(casFlow)'s pairs) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "run", _pos, 500, 2, "", player, createHashMap] call jmfsb_support_air_fnc_casLaunch
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_mode", "run", [""]],
    ["_pos", [], [[]]],
    ["_radius", RADIUS_MIN, [0]],
    ["_passes", 1, [0]],
    ["_mag", "", [""]],
    ["_requester", objNull, [objNull]],
    ["_opts", createHashMap, [createHashMap]]
];

if (isNull _logic) exitWith {};

// RECALLED BEFORE IT WAS MADE: the sortie never flew.
if (_logic getVariable [QGVAR(abort), false]) exitWith {
    _logic setVariable [QGVAR(plan), [], true];
    _logic setVariable [QGVAR(abort), false, true];
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    [_logic, "stood down", "normal", _requester] call FUNC(say);
    [_logic, "DECLINED", "stood down"] call FUNC(threadState);
};

// THE LEGS. In on the ingress bearing, out on the egress bearing.
private _ingress = _opts getOrDefault ["ingress", []];
private _egress = _opts getOrDefault ["egress", []];
private _home = _logic getVariable [QGVAR(home), getPosATL _logic];
private _inDir = _pos getDir ([_ingress, _home] select (_ingress isEqualTo []));
private _outDir = if (_egress isEqualTo []) then {_inDir + 180} else {_pos getDir _egress};
private _runIn = _logic getVariable [QGVAR(runIn), 3000];

private _synced = _logic getVariable [QGVAR(synced), objNull];
private _fromStand = alive _synced;

// THE TACTICAL PROFILE (user, 2026-11-01). A fixed-wing on a SAD or LOITER
// holds off the map - the flow's station.
private _what = [_logic getVariable [QGVAR(cls), ""], _synced] select _fromStand;
private _fw = !(_what isKindOf "Helicopter");
private _station = _fw && _mode isNotEqualTo "run";
private _hold = [_what, _pos] call EFUNC(support,holdPoint);
private _alt = [_what, [FLY_ATTACK, FLY_STATION] select _station] call EFUNC(support,flightHeight);

// An INGRESS picked: the run-in point on its bearing is flown to first.
private _entry = if (_ingress isNotEqualTo []) then {_pos getPos [_runIn, _inDir]} else {[]};
private _firstTo = [[_pos, _hold] select _station, _entry] select (_entry isNotEqualTo []);
private _veh = if (_fromStand) then {_synced} else {
    [_logic, _firstTo, _alt] call FUNC(spawnAircraft)
};

// A launch that fails never flew.
if (!alive _veh) exitWith {
    _logic setVariable [QGVAR(plan), [], true];
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    [_logic, "could not launch", "high", _requester, false] call FUNC(say);
    [_logic, "DECLINED", "could not launch"] call FUNC(threadState);
};

private _grp = [_logic, _veh] call FUNC(prepareAircraft);
if (isNull _grp) exitWith {
    _logic setVariable [QGVAR(plan), [], true];
    if (!_fromStand) then {[_veh] call FUNC(sweep)};
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    [_logic, "has no crew", "high", _requester, false] call FUNC(say);
    [_logic, "DECLINED", "has no crew"] call FUNC(threadState);
};

[_grp, _mode] call FUNC(casPosture);

// DRONE ESCORTS (user, 2026-11-02: "always for fix wings", a helicopter's by
// the request's LZ security): made beside it over the module, they fly the
// hold and the strike with it and are removed with it (the support core's
// escort watch).
[_logic, _veh, _pos, format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], _logic getVariable [QGVAR(side), west]] call FUNC(escortLaunch);

// What the pass reads off the airframe (EFUNC(cas,passBegin)); a release
// held for friendlies is said once a sortie (FUNC(casStrike)).
_veh setVariable [QEGVAR(cas,ordnance), _mag];
_logic setVariable [QGVAR(heldSaid), false];

_veh engineOn true;
[_veh, _alt] call EFUNC(support,flyAt);
if (_entry isEqualTo []) then {
    [_veh, _firstTo, ["NORMAL", "FULL"] select (_mode isEqualTo "run")] call FUNC(moveTo);
} else {
    [_veh, _entry, "FULL"] call FUNC(moveTo);
};

_logic setVariable [QGVAR(vehicle), _veh, true];
_logic setVariable [QGVAR(status), "inbound", true];
_logic setVariable [QGVAR(ticking), true];

private _plan = [];
if (_entry isNotEqualTo []) then {_plan pushBack [_entry, PLAN_IN]};
if (_station) then {_plan pushBack [_hold, PLAN_HOLD]};
_plan pushBack [_pos, toUpper _mode];
_plan pushBack [_pos getPos [_runIn, _outDir], PLAN_OUT];
_logic setVariable [QGVAR(plan), _plan, true];

private _st = createHashMapFromArray [
    ["phase", ["in", "entry"] select (_entry isNotEqualTo [])],
    ["mode", _mode],
    ["pos", _pos],
    ["radius", _radius],
    ["passes", _passes],
    ["requester", _requester],
    ["until", CBA_missionTime + SORTIE_TIMEOUT],
    ["next", 0],
    ["entry", _entry],
    // The bearing every pass of the run comes in on (FUNC(casRun), the pass
    // lines up on it); a run re-tasked comes in from where it is.
    ["inDir", _inDir],
    ["outDir", [-1, _outDir] select (_egress isNotEqualTo [])],
    // The card's egress point, flown when the BDA says EGRESS (user,
    // 2026-11-02; FUNC(threadReply), FUNC(casTick) "egressOut").
    ["egress", _egress],
    ["danger", _opts getOrDefault ["danger", false]],
    ["fw", _fw],
    ["hold", _hold],
    // From a thread (2026-11-01, FUNC(srvThread)): a run held short until
    // CLEARED HOT, and the time on station the REQUEST ON STATION asked for -
    // CAS time on station still limits a task (user, 2026-11-02).
    ["clear", _opts getOrDefault ["clear", false]],
    ["stationTime", _opts getOrDefault ["stationTime", _logic getVariable [QGVAR(stationTime), 600]]]
];
// THE SORTIE'S STATE, server only (step 5, 2026-11-01): a thread's answers
// move it - a re-attack's target, a run re-tasked, the words it goes home
// with (FUNC(threadReply), FUNC(casRetask), FUNC(threadTimeout)).
// THE CAS FLOW (2026-11-09, FUNC(casFlow)): a thread's run waits for its
// READBACK, carries its type of control and TOT.
{_st set _x} forEach (_opts getOrDefault ["flow", []]);
_logic setVariable [QGVAR(sortieState), _st];

INFO_3("%1 airborne for %2 on %3",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_mode,mapGridPosition _pos);
[_logic, format ["airborne, inbound %1", mapGridPosition _pos], "normal", _requester] call FUNC(say);
// ON TASK in the asset's thread, if one was filed to it (2026-11-01).
[_logic, "IN_PROGRESS"] call FUNC(threadState);

[FUNC(casTick), AIR_TICK, [_logic, _veh, _st]] call CBA_fnc_addPerFrameHandler;
