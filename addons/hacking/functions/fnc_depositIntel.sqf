#include "script_component.hpp"
/*
 * Author: JMSB
 * Banks every carried intel item into this drop - the drop's ACE action.
 * Carried intel is worth nothing until it is in a case.
 *
 * THE SERVER COUNTS (review S7). This asks; FUNC(srvDeposit) checks the
 * sender stands at a real drop, counts the intel his unit carries by its own
 * view of his inventory, banks that, and has this machine take the items out
 * (FUNC(depositTake)). No count travels from here.
 *
 * Arguments:
 * 0: The drop <OBJECT>
 * 1: The player <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_target, _player] call jmfsb_hacking_fnc_depositIntel
 *
 * Public: No
 */

params [["_drop", objNull, [objNull]], ["_unit", objNull, [objNull]]];

if (isNull _unit || {isNull _drop}) exitWith {};

[_drop] remoteExecCall [QFUNC(srvDeposit), SERVER_OWNER];
