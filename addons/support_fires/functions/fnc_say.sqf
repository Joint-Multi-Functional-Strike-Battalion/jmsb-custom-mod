#include "script_component.hpp"
/*
 * Author: YonV
 * Server: what an asset says - shot, splash, rounds complete, on station,
 * lost - sent to its side by remoteExec (FUNC(sayLocal)), which a client takes
 * only from the server (review S7: it was a global CBA event, so any client
 * could put words in an asset's mouth on his whole side's rail).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The words, without the callsign <STRING>
 * 2: Priority, "normal" or "high" <STRING> (optional, default "normal")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "missile away", "normal"] call jmfsb_support_fires_fnc_say
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_text", "", [""]], ["_priority", "normal", [""]]];

if (!isServer || {isNull _logic} || _text isEqualTo "") exitWith {};

[_logic, _text, _priority] remoteExecCall [QFUNC(sayLocal), _logic getVariable [QGVAR(side), sideUnknown]];
