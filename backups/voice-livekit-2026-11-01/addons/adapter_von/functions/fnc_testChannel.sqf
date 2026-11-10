#include "script_component.hpp"
/*
 * Author: YonV
 * Server, self test T4: takes a player off the C2 custom channel now and
 * puts him back after TEST_READD_S, telling him the server time of each, so
 * his client can log when it saw them.
 *
 * Reached by remoteExec from FUNC(selfTest); the player must be the sender's
 * own (review S7: it was a CBA event, so any client could take any player
 * off C2, over and over).
 *
 * Arguments:
 * 0: Player <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] remoteExecCall ["jmfsb_adapter_von_fnc_testChannel", 2]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!isServer || {VON_NOT_THE_SYSTEM} || {isNull _unit}) exitWith {};
if !([_unit] call EFUNC(common,senderIs)) exitWith {
    WARNING_1("testChannel: refused - machine %1 named a player not its own",remoteExecutedOwner);
};
private _id = GVAR(customs) getOrDefault [KEY_C2, CUSTOM_NONE];
if (_id <= CUSTOM_NONE) exitWith {};

// The answers go by remoteExec, taken only from the server (review R1: the
// testResult CBA event let any client forge T4 lines in anyone's RPT).
_id radioChannelRemove [_unit];
["removed", serverTime] remoteExecCall [QFUNC(testResult), _unit];
[{
    params ["_id", "_unit"];
    _id radioChannelAdd [_unit];
    ["added", serverTime] remoteExecCall [QFUNC(testResult), _unit];
}, [_id, _unit], TEST_READD_S] call CBA_fnc_waitAndExecute;
