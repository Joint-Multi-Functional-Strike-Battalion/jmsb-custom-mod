#include "script_component.hpp"
/*
 * Author: JMSB
 * Registers code to run on this machine when a delivery receipt arrives for
 * it (FUNC(ack), FUNC(ackLocal)) - TAC//SUPPORT's verdict row and notify rail.
 *
 * Not a CBA event (review R1): any client can raise any CBA event on every
 * machine, so the jmfsb_support_ack event was a fake receipt anyone could put
 * on every board. The hooks live in localNamespace, which is not networked.
 * Local calls only: a remote-executed call is dropped.
 *
 * Arguments:
 * 0: Code, run with [assetId <STRING>, ok <BOOL>, said <STRING>] <CODE>
 *
 * Return Value:
 * None
 *
 * Example:
 * [{params ["_assetId", "_ok", "_said"]; systemChat _said}] call jmfsb_support_fnc_onAck
 *
 * Public: Yes
 */

params [["_code", {}, [{}]]];

if (isRemoteExecuted) exitWith {};
if (_code isEqualTo {}) exitWith {};

private _hooks = localNamespace getVariable [QGVAR(ackHooks), []];
_hooks pushBack _code;
localNamespace setVariable [QGVAR(ackHooks), _hooks];
