#include "script_component.hpp"
/*
 * Author: JMSB
 * The server refused something this player sent. Told to him and nobody else.
 * It is the server's half of the validation the client already ran, so it only
 * fires when the two disagreed - a stale template, or a thread that changed
 * state while the form was open.
 *
 * Sent by remoteExecCall from the server (FUNC(srvSubmit), FUNC(srvClaim)) and
 * taken only from the server (review S7). It then runs the hooks registered
 * with FUNC(onReject), so a screen that shows the refusal (TAC//MSG's
 * composer) still hears it. Not a CBA event: any client could raise that one
 * and fake a refusal on every screen.
 *
 * Arguments:
 * 0: Template id, or what was refused <STRING>
 * 1: Why <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["casevac", "no addressee"] remoteExecCall ["jmfsb_messaging_fnc_cltReject", _unit]
 *
 * Public: No
 */

params [["_templateId", "", [""]], ["_why", "", [""]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {};

private _template = [_templateId] call FUNC(template);
[_template getOrDefault ["short", "MESSAGE"], _why, "high"] call FUNC(notify);

// AND IN CHAT. The notification stack is an RscTitles layer, so anything
// drawn as a dialog is in front of it - and the screen a refusal is about is
// always a dialog. A message that says why nothing happened is worthless if it
// is behind the thing that did nothing.
systemChat format ["[%1] %2", _template getOrDefault ["short", "MESSAGE"], _why];

{
    [_templateId, _why] call _x;
} forEach (localNamespace getVariable [QGVAR(rejectHooks), []]);
