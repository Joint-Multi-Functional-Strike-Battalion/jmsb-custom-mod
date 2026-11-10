#include "script_component.hpp"
/*
 * Author: YonV
 * What the side hears, on its notify rail: an air asset's line, so a strike
 * or a QRF is not something that silently happens somewhere. The requester already
 * has it as the support core's acknowledgement and is not told twice.
 *
 * Sent by the server (FUNC(say)) by remoteExec to the module's side and taken
 * only from the server (review S7: it was a global CBA event, so any client
 * could put words on his whole side's rail).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The line, with the callsign <STRING>
 * 2: Notify priority - "normal" or "high" <STRING>
 * 3: Who asked, objNull for nobody in particular <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "HAWK 1 inbound", "high", _requester] remoteExecCall ["jmfsb_support_air_fnc_sayLocal", west]
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_text", "", [""]], ["_prio", "normal", [""]], ["_requester", objNull, [objNull]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("sayLocal: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (isNull _logic || _text isEqualTo "") exitWith {};
if ((_logic getVariable [QGVAR(side), sideUnknown]) isNotEqualTo (side group player)) exitWith {};
if (!isNull _requester && {player isEqualTo _requester}) exitWith {};

["SUPPORT", _text, _prio] call EFUNC(messaging,notify);
