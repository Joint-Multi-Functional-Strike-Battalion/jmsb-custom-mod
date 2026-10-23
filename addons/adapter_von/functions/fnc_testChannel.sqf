#include "script_component.hpp"
/*
 * Author: JMSB
 * Server, self test T4: takes a player off the C2 custom channel now and
 * puts him back after TEST_READD_S, telling him the server time of each, so
 * his client can log when it saw them.
 *
 * Arguments:
 * 0: Player <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call jmfsb_adapter_von_fnc_testChannel
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _id = GVAR(customs) getOrDefault [KEY_C2, CUSTOM_NONE];
if (!isServer || isNull _unit || _id <= CUSTOM_NONE) exitWith {};

_id radioChannelRemove [_unit];
[QGVAR(testResult), ["removed", serverTime], _unit] call CBA_fnc_targetEvent;
[{
    params ["_id", "_unit"];
    _id radioChannelAdd [_unit];
    [QGVAR(testResult), ["added", serverTime], _unit] call CBA_fnc_targetEvent;
}, [_id, _unit], TEST_READD_S] call CBA_fnc_waitAndExecute;
