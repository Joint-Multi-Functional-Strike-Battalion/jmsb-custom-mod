#include "..\script_component.hpp"
/*
 * Author: JMSB
 * The players' air defence actions on one AD vehicle, on this machine - from
 * the vehicle's own InitPost (FUNC(vehicleInit)), so joining players get them
 * with no message from the server.
 *
 *   SCROLL  "Air defence: next targeting mode" and mute / un-mute, within
 *           ADS_ACTION_RANGE of the vehicle - the engine checks the range
 *           before the condition, so away from the vehicle they cost nothing
 *   ACE     an "Air Defence" node, added once per CLASS (FUNC(aceActions))
 *
 * Shown to a player on a side friendly to the vehicle's while interception is on.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value: None
 *
 * Example:
 * [_vehicle] call jmfsb_adsite_fnc_actions
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

if (!hasInterface || {isNull _veh}) exitWith {};

[typeOf _veh] call FUNC(aceActions);

private _cond = format ["%1 && {alive _target} && {((side group _this) getFriend (side _target)) >= %2}", QGVAR(enabled), ADS_FRIEND];

_veh addAction ["<t color='#C2A878'>Air defence: next targeting mode</t>", {
    params ["_target"];
    [_target, ""] call FUNC(setMode);
}, nil, ADS_ACTION_PRIORITY, false, true, "", _cond, ADS_ACTION_RANGE];

_veh addAction ["<t color='#C2A878'>Air defence: mute alarm</t>", {
    params ["_target"];
    [_target, true] call FUNC(setMute);
}, nil, ADS_ACTION_PRIORITY, false, true, "", format ["%1 && {!(_target getVariable ['%2', false])}", _cond, QGVAR(muted)], ADS_ACTION_RANGE];

_veh addAction ["<t color='#C2A878'>Air defence: un-mute alarm</t>", {
    params ["_target"];
    [_target, false] call FUNC(setMute);
}, nil, ADS_ACTION_PRIORITY, false, true, "", format ["%1 && {_target getVariable ['%2', false]}", _cond, QGVAR(muted)], ADS_ACTION_RANGE];
