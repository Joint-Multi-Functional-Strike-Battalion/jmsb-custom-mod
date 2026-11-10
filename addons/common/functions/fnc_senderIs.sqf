#include "script_component.hpp"
/*
 * Author: YonV
 * Server: whether the remote-executed call now running came from the machine
 * that owns this unit - so a caller, requester or author passed in the
 * arguments is the sender himself and not someone he names (review S5, R1).
 * This machine's own calls and calls from the server pass.
 *
 * Only for code reached by remoteExec. A CBA event handler is not remote
 * executed, so this passes there: never use it behind a CBA event.
 *
 * Arguments:
 * 0: The unit the call claims to come from <OBJECT>
 *
 * Return Value:
 * The sender is that unit's machine <BOOL>
 *
 * Example:
 * [_caller] call jmfsb_common_fnc_senderIs
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (!isRemoteExecuted) exitWith {true};
if (remoteExecutedOwner isEqualTo SERVER_OWNER) exitWith {true};

!isNull _unit && {(owner _unit) isEqualTo remoteExecutedOwner}
