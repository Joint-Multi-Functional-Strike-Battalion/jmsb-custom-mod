#include "script_component.hpp"
/*
 * Author: YonV
 * What the observer hears, on his notify rail: sent by the server
 * (FUNC(say)) by remoteExec and taken only from it (review S7).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The words, without the callsign <STRING>
 * 2: Priority, "normal" or "high" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "missile away", "normal"] remoteExecCall ["jmfsb_support_fires_fnc_sayLocal", west]
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_text", "", [""]], ["_priority", "normal", [""]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("sayLocal: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (isNull _logic || _text isEqualTo "") exitWith {};
if ((_logic getVariable [QGVAR(side), sideUnknown]) isNotEqualTo (side group player)) exitWith {};

["SUPPORT", format ["%1 %2", _logic getVariable [QGVAR(callsign), "FIRES"], _text], _priority] call EFUNC(messaging,notify);
