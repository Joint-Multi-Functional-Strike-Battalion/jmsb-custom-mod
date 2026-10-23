#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: forgets a drone that died, was picked up or was deleted, or whose
 * mode is being switched (FUNC(setMode)). Its RF node goes; a jammer stops
 * counting in FUNC(noise) at once and, with jmfsb_ew loaded, stops being an
 * EW emitter.
 *
 * Arguments:
 * 0: Node id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["drone40_1"] call jmfsb_drone40_fnc_remove
 *
 * Public: No
 */

params [["_id", "", [""]]];

private _entry = GVAR(drones) deleteAt _id;
if (isNil "_entry") exitWith {};

_entry params ["", "_role"];
if (_role isEqualTo ROLE_JAMMER) then {
    if (!isNil QEFUNC(ew,removeEmitter)) then {[_id] call EFUNC(ew,removeEmitter)};
} else {
    [_id] call EFUNC(rf,unregister);
};
TRACE_2("drone gone",_id,_role);
