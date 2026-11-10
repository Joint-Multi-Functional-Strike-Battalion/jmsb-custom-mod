#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a run accepted by FUNC(request) starts, at once (was the delayed
 * half of FUNC(request); the Response Delay is retired, 2026-11-02).
 *
 * THE DRONE IS MADE NOW (user, 2026-11-02: "all support aircraft needs to be
 * virtual till tasked, then they spawn in at alt over the support module
 * location"): in the air over the module at the hold altitude, engines on and
 * flying, clear of any other aircraft (FUNC(spawnDrone),
 * EFUNC(support,spawnAirborne)), full of fuel and stores. Then the run - for a
 * strike the card's ingress point first when it gave one, then in through the
 * target and out to the egress; a loiter or a strike held for CLEARED HOT
 * orbits the grid. When it is over it flies home and is removed
 * (FUNC(recover)).
 *
 * WHERE IT COMES FROM. An unset ingress point is the module's side of the
 * target, where the drone is made. The run-in floor: a point too close leaves
 * no room to line up, so it is pushed back along its own bearing.
 * WHERE IT GOES. Unset egress carries straight on through the target on the
 * ingress line, never closer than the floor, so the asset is not handed back
 * with its aircraft over the section that called it. ATL THROUGHOUT: height
 * above the ground under the aircraft.
 *
 * Then the run watch (FUNC(runTick)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target grid, ATL <ARRAY>
 * 2: Ingress point, [] for auto <ARRAY>
 * 3: Egress point, [] for auto <ARRAY>
 * 4: Who asked <OBJECT>
 * 5: Store, "" for the heaviest aboard <STRING>
 * 6: "strike" or "loiter" <STRING>
 * 7: The thread the run answers, "" for none <STRING>
 * 8: The run's state <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(launch), [_logic, _pos, [], [], _caller, "", "strike", "", _run], 0] call CBA_fnc_waitAndExecute
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_pos", [], [[]]],
    ["_ingress", [], [[]]],
    ["_egress", [], [[]]],
    ["_caller", objNull, [objNull]],
    ["_mag", "", [""]],
    ["_mode", MODE_STRIKE, [""]],
    ["_threadId", "", [""]],
    ["_run", createHashMap, [createHashMap]]
];

// The module may have been deleted since the order.
if (isNull _logic) exitWith {};

private _cls = _logic getVariable [QGVAR(cls), ""];
private _side = _logic getVariable [QGVAR(side), west];
private _dist = _logic getVariable [QGVAR(spawnDistance), REACH_DEF_DISTANCE];
// THE SUPPORT CORE'S TACTICAL HEIGHT (user, 2026-11-01: "atack alt need to be
// 4k m atl"): a strike at the attack altitude, a loiter at the hold's.
private _alt = [_cls, [FLY_ATTACK, FLY_STATION] select (_mode isEqualTo MODE_LOITER)] call EFUNC(support,flightHeight);
// A DRONE LOITERS OVER THE GRID (user, 2026-11-01): exempt from the off-map hold.
private _hold = +_pos;
private _radius = _logic getVariable [QGVAR(searchRadius), 300];
private _callsign = _logic getVariable [QGVAR(callsign), "CAS"];
// Where the drone is made: over the module.
(getPosATL _logic) params ["_mx", "_my"];
private _base = [_mx, _my, 0];

private _start = [+_base, +_ingress] select (_ingress isNotEqualTo []);
if (_start distance2D _pos < _dist) then {
    _start = _pos getPos [_dist, _pos getDir _start];
};
private _end = if (_egress isNotEqualTo []) then {+_egress} else {
    _pos getPos [_dist, (_start getDir _pos)]
};
if (_end distance2D _pos < _dist) then {
    _end = _pos getPos [_dist, _pos getDir _end];
};
_start set [2, _alt];
_end set [2, _alt];

private _ingressHdg = _start getDir _pos;
// THE WAY OUT, for every ending: the target-to-egress line.
private _egressHdg = _pos getDir _end;

// How long it may stay: a strike's patience, a loiter's hour, and a thread's
// strike its time on station for the answers (step 5).
private _patience = [CAS_RUN_TIMEOUT, CAS_LOITER_TIMEOUT] select (_mode isEqualTo MODE_LOITER);
if (_threadId isNotEqualTo "" && _mode isEqualTo MODE_STRIKE) then {_patience = CAS_THREAD_TIMEOUT};
{_run set _x} forEach [
    ["pos", _pos],
    ["end", _end],
    ["egressHdg", _egressHdg],
    // The bearing the first pass comes in on (FUNC(runTick), the pass lines
    // up on it); spent with that pass - a re-attack comes in from where it is.
    ["inDir", _pos getDir _start],
    ["until", CBA_missionTime + _patience],
    ["distance", _dist],
    ["mag", _mag]
];

// Made over the module at the hold altitude, pointed at its first leg.
private _firstLeg = [_pos, _start] select (_ingress isNotEqualTo []);
private _veh = [_logic, _base, [_cls, FLY_STATION] call EFUNC(support,flightHeight), _base getDir _firstLeg] call FUNC(spawnDrone);
if (isNull _veh) exitWith {
    WARNING_2("%1 could not put '%2' in the air - run abandoned",_callsign,_cls);
    _logic setVariable [QGVAR(status), [_logic] call FUNC(idleStatus), true];
    _logic setVariable [QGVAR(plan), [], true];
    [format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], "DECLINED", "could not get airborne", _callsign, false, _threadId] call EFUNC(support,state);
};
private _grp = group driver _veh;
[_grp] call CBA_fnc_clearWaypoints;
_veh flyInHeight _alt;

_logic setVariable [QGVAR(vehicle), _veh, true];
// THE WORD ON THE ROW: a loiter says so from the moment it starts.
_logic setVariable [QGVAR(status), [STATUS_MISSION, MODE_LOITER] select (_mode isEqualTo MODE_LOITER), true];

// WHAT IT WAS ASKED TO SHOOT WITH, and WHO ASKED - read off the airframe by
// the pass (FUNC(passBegin)) and FUNC(onStation) minutes later. It starts
// clean: not on station, nothing released.
_veh setVariable [QGVAR(ordnance), _mag];
_veh setVariable [QGVAR(caller), _caller, true];
_veh setVariable [QGVAR(onStation), false, true];
_veh setVariable [QGVAR(released), false];

// WHAT IT IS UP THERE TO DO, AS WAYPOINTS. A strike flies to the card's
// ingress point first when it gave one, then the pass takes it in on the
// target (the run watch, its own orders) and out to the egress. A loiter,
// and a strike held for CLEARED HOT, orbit the grid releasing nothing until
// the run watch sends it in.
private _loiter = _mode isEqualTo MODE_LOITER;
private _held = !_loiter && !(_logic getVariable [QGVAR(cleared), true]);
// No strike has run in yet: the run watch begins the pass on its first tick
// - at once for a cleared strike, after CLEARED HOT for a held one.
_veh setVariable [QGVAR(runIn), false];
if (_loiter || _held) then {
    private _wp = _grp addWaypoint [_hold, 0];
    _wp setWaypointType "LOITER";
    _wp setWaypointLoiterRadius CAS_LOITER_RADIUS;
    _wp setWaypointSpeed "NORMAL";
    _grp setCurrentWaypoint _wp;
} else {
    private _legs = [_pos, _end];
    if (_ingress isNotEqualTo []) then {_legs = [_start] + _legs};
    {
        private _wp = _grp addWaypoint [_x, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed "FULL";
        if (_forEachIndex isEqualTo 0) then {_grp setCurrentWaypoint _wp};
    } forEach _legs;
};

INFO_4("%1 airborne: %2 inbound on %3 deg to %4",_callsign,_cls,round _ingressHdg,_mode);

[FUNC(runTick), CAS_ACQUIRE_STEP, [_veh, _logic, _pos, _radius, _side, _end, _egressHdg, CBA_missionTime + _patience, _callsign, _mode, _hold, _threadId, _run]] call CBA_fnc_addPerFrameHandler;
