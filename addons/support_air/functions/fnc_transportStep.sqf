#include "script_component.hpp"
/*
 * Author: JMSB
 * One tick of a transport that has reached its point (FUNC(transportArrive)
 * started the phase):
 *
 *   "landing"     coming down; a landing that has not settled in
 *                 LANDING_PATIENCE is ordered again
 *   "down"        on the ground. PICKUP waits; LAND puts AI passengers out
 *                 and waits; LAND ENG OFF sits shut down; EXTRACT and PICKUP
 *                 > LZ wait for the requester's group (or the wait), then fly
 *                 it home or to the LZ
 *   "unload"      home, a class helicopter waiting for its last player to get
 *                 out before it is removed
 *   "ropeIn"      settling into the rope hover; over it, ropes out
 *   "roping"      ropes out until the cabin is empty or the wait is up, then
 *                 ropes cut and a hover held
 *   "castIn"      settling over the water; there, AI passengers out and a
 *                 slow drift forward
 *   "casting"     drifting until the cabin is empty or the wait is up, then
 *                 a climb back to the hover
 *   "jumping"     one jumper out per tick on a static line, players as well
 *                 (on their own machines); the stick out, home
 *   "hook"        settling over the load; low and close, it is hooked
 *   "slingCarry"  carrying it to the set-down point
 *   "slingLower"  lowering it there; low enough, or out of patience, cut
 *   "hold"        nothing to do until the next order
 *
 * AI passengers are put out where a task puts them out; players get out
 * themselves - except on a PARADROP, which is the requester asking for the
 * whole cabin to jump.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The helicopter <OBJECT>
 * 2: The watch's state <HASHMAP>
 * 3: The watch's PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh, _st, _handle] call jmfsb_support_air_fnc_transportStep
 *
 * Public: No
 */

// Where a sling helicopter starts coming down, m from the set-down point.
#define CARRY_APPROACH 200
// Clearance over the hook height that counts as low enough to hook or cut.
#define HOOK_SLACK 8

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_st", createHashMap, [createHashMap]], ["_handle", -1, [0]]];

private _task = _st getOrDefault ["task", TASK_HOME];
private _target = _st getOrDefault ["target", getPosATL _veh];
private _requester = _st getOrDefault ["requester", objNull];
private _since = _st getOrDefault ["since", CBA_missionTime];

private _cargo = (fullCrew [_veh, "cargo"]) apply {_x select 0};
private _over = {_veh distance2D _target < HOVER_RING && {speed _veh < HOVER_SPEED}};
private _low = {((getPos _veh) select 2) < _this + HOOK_SLACK};
private _fnc_hold = {
    params ["_line"];
    _veh flyInHeight (_st getOrDefault ["height", HOME_HEIGHT]);
    [_veh, _target, "LIMITED"] call FUNC(moveTo);
    _st set ["phase", "hold"];
    _logic setVariable [QGVAR(status), "holding", true];
    [_logic, _line, "normal", _requester] call FUNC(say);
};
private _fnc_putOut = {
    {
        if (!isPlayer _x) then {[QGVAR(putOut), [_x], _x] call CBA_fnc_targetEvent};
    } forEach _cargo;
};
private _fnc_waitDone = {CBA_missionTime > (_st getOrDefault ["waitUntil", 0])};

switch (_st get "phase") do {
    case "landing": {
        if !(isTouchingGround _veh && {speed _veh < SETTLED_SPEED}) exitWith {
            if (CBA_missionTime - _since > LANDING_PATIENCE) then {
                [_veh, _target, _st get "mode"] call FUNC(landAt);
                _st set ["since", CBA_missionTime];
            };
        };
        _st set ["phase", "down"];
        _st set ["waitUntil", CBA_missionTime + (_st getOrDefault ["wait", 0])];
        if (_task in [TASK_LAND, TASK_HOME]) then {call _fnc_putOut};

        switch (_task) do {
            case TASK_PICKUP: {
                _logic setVariable [QGVAR(status), "waiting", true];
                [_logic, format ["on the ground at %1, waiting", mapGridPosition _veh], "high", _requester] call FUNC(say);
            };
            case TASK_LAND: {
                _logic setVariable [QGVAR(status), "waiting", true];
                [_logic, format ["on the ground at %1, passengers out", mapGridPosition _veh], "high", _requester] call FUNC(say);
            };
            case TASK_LAND_OFF: {
                _veh engineOn false;
                _logic setVariable [QGVAR(status), "shut down", true];
                [_logic, format ["on the ground at %1, shut down", mapGridPosition _veh], "high", _requester] call FUNC(say);
            };
            case TASK_EXTRACT;
            case TASK_LIFT: {
                _logic setVariable [QGVAR(status), "waiting", true];
                [_logic, format ["on the ground at %1, waiting %2 sec for %3", mapGridPosition _veh, round (_st getOrDefault ["wait", 0]), groupId group _requester], "high", _requester] call FUNC(say);
            };
            default {
                if (!isNull (_logic getVariable [QGVAR(synced), objNull])) exitWith {
                    [_logic, _veh] call FUNC(rearm);
                    [_handle] call CBA_fnc_removePerFrameHandler;
                    [_logic, "down at base", "normal"] call FUNC(say);
                    [_logic] call FUNC(finish);
                };
                _st set ["phase", "unload"];
                _logic setVariable [QGVAR(status), "unloading", true];
                [_logic, "down at base", "normal"] call FUNC(say);
            };
        };
    };
    case "down": {
        if !(_task in [TASK_EXTRACT, TASK_LIFT]) exitWith {};
        private _group = (units group _requester) select {alive _x};
        private _aboard = _group isNotEqualTo [] && {_group findIf {vehicle _x isNotEqualTo _veh} < 0};
        if (!_aboard && {!(call _fnc_waitDone)}) exitWith {};
        private _n = count (_cargo select {alive _x});
        if (_task isEqualTo TASK_EXTRACT) exitWith {
            [_logic, _st, format ["lifting with %1 aboard, returning to base", _n]] call FUNC(transportHome);
        };
        // PICKUP > LZ: the second leg is a LAND on the LZ, flown as an order
        // of its own - same height, speed, door guns, lights, approach.
        private _order = +(_logic getVariable [QGVAR(order), []]);
        private _opts = +(_order param [7, createHashMap]);
        _opts set ["via", []];
        _opts set ["lz", []];
        _order set [0, TASK_LAND];
        _order set [1, _st getOrDefault ["lz", _target]];
        _order set [7, _opts];
        _logic setVariable [QGVAR(order), _order];
        _logic setVariable [QGVAR(serial), (_logic getVariable [QGVAR(serial), 0]) + 1];
        [_logic, format ["lifting with %1 aboard for the LZ at %2", _n, mapGridPosition (_order select 1)], "high", _requester] call FUNC(say);
    };
    case "unload": {
        if ((crew _veh) findIf {isPlayer _x} > -1) exitWith {};
        // A player's AI squadmate is put out on his client - ask again and wait
        // for him to be out rather than sweep him with the airframe.
        private _theirs = _cargo select {alive _x && {isPlayer leader group _x}};
        if (_theirs isNotEqualTo []) exitWith {
            {[QGVAR(putOut), [_x], _x] call CBA_fnc_targetEvent} forEach _theirs;
        };
        [_handle] call CBA_fnc_removePerFrameHandler;
        [_veh] call FUNC(sweep);
        [_logic] call FUNC(finish);
    };
    case "ropeIn": {
        if (!(call _over) && {CBA_missionTime - _since < LANDING_PATIENCE}) exitWith {};
        [_veh, false, false] call ace_fastroping_fnc_deployAI;
        _st set ["phase", "roping"];
        _st set ["waitUntil", CBA_missionTime + (_st getOrDefault ["wait", 0])];
        [_logic, format ["ropes out over %1", mapGridPosition _veh], "high", _requester] call FUNC(say);
    };
    case "roping": {
        if (_cargo isNotEqualTo [] && {!(call _fnc_waitDone)}) exitWith {};
        if ((_veh getVariable ["ace_fastroping_deployedRopes", []]) isNotEqualTo []) then {
            [_veh] call ace_fastroping_fnc_cutRopes;
        };
        ["ropes cut, holding a hover"] call _fnc_hold;
    };
    case "castIn": {
        if (!(call _over) && {CBA_missionTime - _since < LANDING_PATIENCE}) exitWith {};
        call _fnc_putOut;
        private _drift = HELOCAST_SPEED / 3.6 * ((_st getOrDefault ["wait", 0]) max 1);
        [_veh, _target getPos [_drift, getDir _veh], "LIMITED"] call FUNC(moveTo);
        _st set ["phase", "casting"];
        _st set ["waitUntil", CBA_missionTime + (_st getOrDefault ["wait", 0])];
        [_logic, format ["on the water at %1 - go", mapGridPosition _veh], "high", _requester] call FUNC(say);
    };
    case "casting": {
        if (_cargo isNotEqualTo [] && {!(call _fnc_waitDone)}) exitWith {};
        _target = getPosATL _veh;
        _st set ["target", _target];
        ["cabin is out, climbing to a hover"] call _fnc_hold;
    };
    case "jumping": {
        // Marked here, on the server: the jump happens on the jumper's own
        // machine and he may still read as aboard on the next tick.
        private _next = _cargo param [_cargo findIf {alive _x && {!(_x getVariable [QGVAR(jumped), false])}}, objNull];
        if (!isNull _next) exitWith {
            _next setVariable [QGVAR(jumped), true];
            [QGVAR(jumpOut), [_next, _veh], _next] call CBA_fnc_targetEvent;
        };
        [_logic, _st, "stick is out, returning to base"] call FUNC(transportHome);
    };
    case "hook": {
        private _load = _st getOrDefault ["load", objNull];
        if (!alive _load) exitWith {["the load is gone - holding"] call _fnc_hold};
        if (!(call _over && {SLING_HOOK_HEIGHT call _low}) && {CBA_missionTime - _since < SLING_PATIENCE}) exitWith {};
        if !(_veh setSlingLoad _load) exitWith {["cannot lift it - holding"] call _fnc_hold};
        _veh flyInHeight ((_st getOrDefault ["height", HOME_HEIGHT]) max SLING_CRUISE);
        _target = _st getOrDefault ["lz", _target];
        _st set ["target", _target];
        [_veh, _target, _st getOrDefault ["speed", "NORMAL"]] call FUNC(moveTo);
        _st set ["phase", "slingCarry"];
        _logic setVariable [QGVAR(status), "carrying", true];
        [_logic, format ["load hooked, carrying it to %1", mapGridPosition _target], "normal", _requester] call FUNC(say);
    };
    case "slingCarry": {
        if (isNull getSlingLoad _veh) exitWith {["has lost the load - holding"] call _fnc_hold};
        if (_veh distance2D _target > CARRY_APPROACH) exitWith {};
        _veh flyInHeight SLING_SET_DOWN;
        [_veh, _target, "LIMITED"] call FUNC(moveTo);
        _st set ["phase", "slingLower"];
        _st set ["since", CBA_missionTime];
        _logic setVariable [QGVAR(status), "setting down", true];
    };
    case "slingLower": {
        if (!(_veh distance2D _target < SLING_RING && {SLING_SET_DOWN call _low}) && {CBA_missionTime - _since < SLING_PATIENCE}) exitWith {};
        _veh setSlingLoad objNull;
        [format ["load set down at %1, holding", mapGridPosition _veh]] call _fnc_hold;
    };
};
