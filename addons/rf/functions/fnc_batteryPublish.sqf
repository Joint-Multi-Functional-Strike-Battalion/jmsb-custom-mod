#include "script_component.hpp"
/*
 * Author: JMSB
 * Tells each player how his batteries stand: jmfsb_rf_batteries on his unit,
 * [[node id, level 0..1], ...] for the sets he holds that have a battery
 * (FUNC(battery) reads it). Levels are quantised to BATTERY_STEP and the
 * variable is set - and so sent - only when the list changed: a set draining
 * over eight hours is twenty messages, not one a tick.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_rf_fnc_batteryPublish
 *
 * Public: No
 */

// [[holder, [[node id, level], ...]], ...]: a hashmap cannot key on an object.
private _byHolder = [];
{
    private _holder = _y get "holder";
    if (isNull _holder || {!isPlayer _holder}) then {continue};
    if (((GVAR(profiles) get (_y get "profile")) get "batteryWh") <= 0) then {continue};
    private _level = round ((_y getOrDefault ["battery", 1]) / BATTERY_STEP) * BATTERY_STEP;
    private _i = _byHolder findIf {(_x select 0) isEqualTo _holder};
    if (_i < 0) then {
        _byHolder pushBack [_holder, [[_x, _level]]];
    } else {
        ((_byHolder select _i) select 1) pushBack [_x, _level];
    };
} forEach GVAR(nodes);

{
    _x params ["_holder", "_list"];
    _list sort true;
    if ((_holder getVariable [QGVAR(batteries), []]) isNotEqualTo _list) then {
        _holder setVariable [QGVAR(batteries), _list, true];
    };
} forEach _byHolder;
