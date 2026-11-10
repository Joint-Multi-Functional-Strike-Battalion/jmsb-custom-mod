#include "script_component.hpp"
/*
 * Author: YonV
 * Whether the call now running came from the server or from this machine
 * itself. For work a client does on the server's word (review S7, R1): the
 * server checks the sender, then forwards by remoteExec, and the receiving
 * client accepts only this. A CBA target or global event cannot be trusted
 * here - any client can raise one.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * From the server or local <BOOL>
 *
 * Example:
 * if !([] call jmfsb_common_fnc_fromServer) exitWith {}
 *
 * Public: Yes
 */

!isRemoteExecuted || {remoteExecutedOwner isEqualTo SERVER_OWNER}
