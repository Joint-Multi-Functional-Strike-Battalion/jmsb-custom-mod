#include "script_component.hpp"
/*
 * Author: JMSB
 * A provider's delivery receipt: the asset took the order, or has not taken it
 * yet. Raised as QGVAR(ack) [assetId, ok, said] - TAC//SUPPORT puts it in the
 * verdict row and the notify rail.
 *
 * Local by default, because today's providers watch for the receipt on the
 * client that sent the order. A provider whose work runs on the server passes
 * the requester and the event goes to his machine.
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Acknowledged <BOOL>
 * 2: What to tell the requester <STRING>
 * 3: Requester <OBJECT> (optional, default objNull - raise it here)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["cas:0", true, "REAPER 1 acknowledged - wilco"] call jmfsb_support_fnc_ack
 *
 * Public: Yes
 */

params [["_assetId", "", [""]], ["_ok", true, [true]], ["_said", "", [""]], ["_to", objNull, [objNull]]];

// Hoisted: a comma inside a macro argument reads as an argument separator.
private _word = ["not acknowledged", "acknowledged"] select _ok;
INFO_3("ack: %1 %2 - %3",_assetId,_word,_said);

if (isNull _to || {local _to}) exitWith {
    [QGVAR(ack), [_assetId, _ok, _said]] call CBA_fnc_localEvent;
};
[QGVAR(ack), [_assetId, _ok, _said], _to] call CBA_fnc_targetEvent;
