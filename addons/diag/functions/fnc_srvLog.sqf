#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: writes a client's log line (FUNC(log) with sendToServer) into the
 * server's RPT, tagged with the machine, player and Steam id that sent it.
 *
 * Reached by remoteExec (review R1). It was the "jmfsb_log_text" CBA event,
 * so any client could write any line into the server's RPT, passed off as the
 * server's own. The tag comes from the engine's remoteExecutedOwner, never
 * from the line.
 *
 * Arguments:
 * 0: The line <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["[jmfsb] LOG: something"] remoteExecCall ["jmfsb_diag_fnc_srvLog", 2]
 *
 * Public: No
 */

params [["_line", "", [""]]];

if (!isServer || _line isEqualTo "") exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_unit", "_uid"];
private _who = if (isNull _unit) then {""} else {name _unit};
diag_log text format ["[client %1 %2 %3] %4", _owner, _who, _uid, _line];
