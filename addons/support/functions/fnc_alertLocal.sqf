#include "script_component.hpp"
/*
 * Author: YonV
 * The issuer's own popup for what a support asset needs from him now - the
 * upper-right notifications (EFUNC(messaging,notify)), FLASH colour (user,
 * 2026-11-01: "an alert to pop smoke when its close"). Sent by the server
 * (FUNC(inbound)) by remoteExecCall to the issuer's machine and taken only
 * from the server.
 *
 * Arguments:
 * 0: What it says, with the asset's call sign <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["RAVEN 1 MIN OUT - POP SMOKE"] remoteExecCall ["jmfsb_support_fnc_alertLocal", _issuer]
 *
 * Public: No
 */

params [["_text", "", [""]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("alertLocal: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (_text isEqualTo "") exitWith {};

[ALERT_TITLE, _text, PRIORITY_FLASH] call EFUNC(messaging,notify);
