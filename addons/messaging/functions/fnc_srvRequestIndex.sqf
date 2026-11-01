#include "script_component.hpp"
/*
 * Author: JMSB
 * A client asks for its index (FUNC(request)), by remoteExecCall to the
 * server. The player named must be the sending machine's own (review S7): a
 * CBA event carries no sender, so anyone could have asked on anyone's behalf.
 * The rows go back to that player alone (FUNC(srvIndexPush)).
 *
 * Arguments:
 * 0: Player - the sender's own <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] remoteExecCall ["jmfsb_messaging_fnc_srvRequestIndex", 2]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!isServer) exitWith {};
if !([_unit] call EFUNC(common,senderIs)) exitWith {
    WARNING_2("srvRequestIndex: refused - machine %1 asked for %2's index",remoteExecutedOwner,_unit);
};

[_unit] call FUNC(srvIndexPush);
