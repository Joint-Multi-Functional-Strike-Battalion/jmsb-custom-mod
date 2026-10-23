#include "script_component.hpp"
/*
 * Author: JMSB
 * What an air asset says, server side: the requester gets it as the support
 * core's acknowledgement (EFUNC(support,ack) - the verdict row and the notify
 * rail of TAC//SUPPORT), everyone else on the side as a notification
 * (QGVAR(say), see XEH_postInit). One call, so the man who asked never hears
 * it twice.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The line, without the callsign <STRING>
 * 2: Notify priority - "normal" or "high" <STRING> (optional, default "normal")
 * 3: Who asked, objNull for nobody in particular <OBJECT> (optional, default objNull)
 * 4: Good news <BOOL> (optional, default true)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "inbound", "high", _requester] call jmfsb_support_air_fnc_say
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_line", "", [""]], ["_prio", "normal", [""]], ["_requester", objNull, [objNull]], ["_ok", true, [true]]];

if (isNull _logic) exitWith {};

private _text = format ["%1 %2", _logic getVariable [QGVAR(callsign), "AIR"], _line];
private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];

INFO_1("say: %1",_text);

if (!isNull _requester) then {
    [_assetId, _ok, _text, _requester] call EFUNC(support,ack);
};
[QGVAR(say), [_logic getVariable [QGVAR(side), sideUnknown], _text, _prio, _requester]] call CBA_fnc_globalEvent;
