#include "script_component.hpp"
/*
 * Author: JMSB
 * The watch on a transport helicopter while it is out, every AIR_TICK
 * seconds. A new order (the module's serial moved on) is planned first
 * (FUNC(transportPlan)); then the current one is flown:
 *
 *   "transit"  flying the legs - each VIA point, the final approach point -
 *              and then to the point. On final, a requested landing signal
 *              is looked for round the LZ and landed on when seen. Arrived:
 *              FUNC(transportArrive) starts whatever the task does there
 *   anything after that is FUNC(transportStep)'s - landing, waiting on the
 *              ground, roping, casting, jumping, carrying a load, holding
 *
 * Home ends the watch: a synced helicopter is shut down, repaired, refuelled,
 * re-armed and re-crewed on its stand; a class one is removed once it is
 * empty.
 *
 * AN AIRFRAME THAT CANNOT FLY - pilot dead, too shot up to move - is written
 * off, or it would hold the asset for ever. A synced one is counted lost
 * like a wreck, so the module's Respawn Delay replaces it on its stand
 * (FUNC(lost), FUNC(respawn)) the way Simplex replaces a stuck vehicle.
 *
 * Arguments:
 * 0: [logic, helicopter, state] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(transportTick), 1, [_logic, _veh, _st]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

// Fuel share at which the helicopter goes home whatever it was told.
#define BINGO_FUEL 0.15

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

// Never swept here: players may be aboard. A class airframe counts as lost
// and is let go of, so a later wreck is not counted twice.
if (!canMove _veh || {!alive driver _veh}) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    WARNING_1("%1 transport cannot fly - sortie written off",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")]);
    [_logic, _veh] call FUNC(lost);
    _veh setVariable [QGVAR(owner), objNull, true];
    [_logic] call FUNC(finish);
};

private _serial = _logic getVariable [QGVAR(serial), 0];
if (_serial isNotEqualTo (_st get "serial")) then {
    _st set ["serial", _serial];
    [_logic, _veh, _st, _logic getVariable [QGVAR(order), []]] call FUNC(transportPlan);
};

private _task = _st getOrDefault ["task", TASK_HOME];
private _target = _st getOrDefault ["target", getPosATL _veh];
private _requester = _st getOrDefault ["requester", objNull];

if (fuel _veh < BINGO_FUEL && _task isNotEqualTo TASK_HOME) exitWith {
    [_logic, _st, "bingo fuel, returning to base"] call FUNC(transportHome);
};

if ((_st get "phase") isNotEqualTo "transit") exitWith {
    [_logic, _veh, _st, _handle] call FUNC(transportStep);
};

// THE LEGS FIRST, in order.
private _legs = _st getOrDefault ["legs", []];
if (_legs isNotEqualTo []) exitWith {
    if (_veh distance2D (_legs select 0) > ARRIVE_RING) exitWith {};
    _legs deleteAt 0;
    [_veh, _legs param [0, _target], _st getOrDefault ["speed", "NORMAL"]] call FUNC(moveTo);
};

// ON FINAL, THE SIGNAL. Looked for once, from SIGNAL_LOOK out: seen, it is
// the new LZ; not seen, the grid stands.
private _signal = _st getOrDefault ["signal", SIGNAL_NONE];
if (_signal isNotEqualTo SIGNAL_NONE && {!(_st getOrDefault ["signalLooked", false])} && {_veh distance2D _target < SIGNAL_LOOK}) then {
    _st set ["signalLooked", true];
    private _seen = [_target, _signal] call FUNC(findSignal);
    if (_seen isEqualTo []) then {
        [_logic, format ["no %1 seen at %2, landing on the grid", toLower (SIGNAL_WORDS select _signal), mapGridPosition _target], "normal", _requester] call FUNC(say);
    } else {
        _target = _seen;
        _st set ["target", _seen];
        [_veh, _seen, _st getOrDefault ["speed", "NORMAL"]] call FUNC(moveTo);
        [_logic, format ["visual on your signal at %1, landing on it", mapGridPosition _seen], "high", _requester] call FUNC(say);
    };
};

private _ring = [ARRIVE_RING, PARADROP_LEAD + (speed _veh / 3.6) * count (fullCrew [_veh, "cargo"])] select (_task isEqualTo TASK_PARADROP);
if (_veh distance2D _target > _ring) exitWith {};

[_logic, _veh, _st] call FUNC(transportArrive);
