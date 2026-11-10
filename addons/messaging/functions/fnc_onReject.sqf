#include "script_component.hpp"
/*
 * Author: YonV
 * Registers code to run on this machine when the server refuses something
 * this player sent (FUNC(cltReject)). For screens that show the refusal -
 * TAC//MSG's composer puts the card back.
 *
 * Not a CBA event (review S7): any client can raise any CBA event on every
 * machine, so a refusal on one would be a fake refusal anyone can send. The
 * hooks live in localNamespace, which is not networked, and run only from
 * FUNC(cltReject), which takes its call only from the server. Local calls
 * only: a remote-executed call is dropped.
 *
 * Arguments:
 * 0: Code, run with [templateId <STRING>, why <STRING>] <CODE>
 *
 * Return Value:
 * None
 *
 * Example:
 * [{params ["_templateId", "_why"]; systemChat _why}] call jmfsb_messaging_fnc_onReject
 *
 * Public: Yes
 */

params [["_code", {}, [{}]]];

if (isRemoteExecuted) exitWith {};
if (_code isEqualTo {}) exitWith {};

private _hooks = localNamespace getVariable [QGVAR(rejectHooks), []];
_hooks pushBack _code;
localNamespace setVariable [QGVAR(rejectHooks), _hooks];
