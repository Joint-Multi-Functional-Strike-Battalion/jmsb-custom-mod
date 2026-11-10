#include "script_component.hpp"
/*
 * Author: YonV
 * THE BATTERY of one node, once per tick (user, 2026-10-30: sets run down
 * over hours and get swapped or charged from a vehicle - a logistics reason
 * to go back to the trucks). A set with a battery of its own (profile
 * batteryWh > 0) drains while it is on - BATTERY_TX_FACTOR times faster
 * while keyed - at the rate the Battery life setting gives the handheld's
 * BATTERY_REF_WH, scaled by its own Wh; a set powered by its host (-1), or
 * the setting at 0, never drains. In a vehicle with its engine running the
 * holder's set charges, full in BATTERY_CHARGE_S. Flat, the set switches
 * itself off (the mesh drops it, jmfsb_rf_batteryFlat is raised) and comes
 * back when it has charge again or is swapped (FUNC(batterySwap)).
 *
 * Arguments:
 * 0: Node id <STRING>
 * 1: Node <HASHMAP>
 * 2: Its state <HASHMAP>
 * 3: Its holder, objNull for none <OBJECT>
 * 4: Seconds since the last tick <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_id, _node, _state, _holder, _dt] call jmfsb_rf_fnc_batteryTick
 *
 * Public: No
 */

params ["_id", "_node", "_state", "_holder", "_dt"];

private _wh = (GVAR(profiles) get (_node get "profile")) get "batteryWh";
if (_wh <= 0 || GVAR(batteryHours) <= 0 || _dt <= 0) exitWith {};

private _level = _node getOrDefault ["battery", 1];
private _charging = !isNull _holder && {!isNull objectParent _holder} && {isEngineOn objectParent _holder};
if (_charging) then {
    _level = (_level + _dt / BATTERY_CHARGE_S) min 1;
} else {
    if (_state get "on") then {
        private _rate = (BATTERY_REF_WH / _wh) / (GVAR(batteryHours) * SECONDS_PER_HOUR);
        if (_state get "tx") then {_rate = _rate * BATTERY_TX_FACTOR};
        _level = (_level - _dt * _rate) max 0;
    };
};
_node set ["battery", _level];

if (_level <= 0 && {_state get "on"}) exitWith {
    _state set ["on", false];
    _node set ["flat", true];
    TRACE_1("battery flat",_id);
    [QGVAR(batteryFlat), [_id]] call CBA_fnc_localEvent;
};
if ((_node getOrDefault ["flat", false]) && _level >= BATTERY_STEP) then {
    _state set ["on", true];
    _node set ["flat", false];
};
