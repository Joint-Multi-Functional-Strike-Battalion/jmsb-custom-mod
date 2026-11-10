#include "script_component.hpp"
/*
 * Author: YonV
 * Client: the server's answer to "what RF nodes can my set hear"
 * (FUNC(rfReach)), kept for the tacpad HACK board. Sent by the server to this
 * machine alone, by remoteExec; taken only from the server (review S7), so
 * no client can put a false node list on another man's board.
 *
 * Arguments:
 * 0: The nodes, as FUNC(rfReach) returns them <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_list] remoteExecCall ["jmfsb_hacking_fnc_rfReached", _unit]
 *
 * Public: No
 */

params [["_list", [], [[]]]];

if !([] call EFUNC(common,fromServer)) exitWith {};

GVAR(rfReach) = _list;
GVAR(rfReachTime) = CBA_missionTime;
