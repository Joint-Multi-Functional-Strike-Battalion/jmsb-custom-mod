#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, self test T4: the server says when it removed or re-added him on
 * the C2 channel; logged with the time since the test started here, to set
 * against the membership changes fnc_selfTestFrame saw.
 *
 * Arguments:
 * 0: What "removed" | "added" <STRING>
 * 1: Server time <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["added", serverTime] call jmfsb_adapter_von_fnc_testResult
 *
 * Public: No
 */

params [["_what", "", [""]], ["_serverTime", 0, [0]]];

private _start = GVAR(test) getOrDefault ["start", diag_tickTime];
INFO_3("VON T4 custom channel: server %1 you at server time %2, %3 ms after the test started here",_what,_serverTime,round ((diag_tickTime - _start) * MS_PER_S));
