#include "script_component.hpp"
/*
 * Author: YonV
 * Server: registers code to run when an ALiVE commander takes an objective
 * (FUNC(eventListener), OPCOM_CAPTURE).
 *
 * Not a CBA event (review R1): any client could raise the old
 * "jmfsb_adapter_alive_capture" event to put a fake FRONT message on every
 * screen. The hooks live in localNamespace, which is not networked. Local
 * calls only.
 *
 * Arguments:
 * 0: Code, run with [sideText <STRING>, objectiveID <STRING>, pos <ARRAY>,
 *    size <NUMBER>] as _this <CODE>
 *
 * Return Value:
 * None
 *
 * Example:
 * [{params ["_sideText", "", "_pos"]; diag_log _pos}] call jmfsb_adapter_alive_fnc_onCapture
 *
 * Public: Yes
 */

params [["_code", {}, [{}]]];

if (!isServer || isRemoteExecuted) exitWith {};
if (_code isEqualTo {}) exitWith {};

private _hooks = localNamespace getVariable [QGVAR(captureHooks), []];
_hooks pushBack _code;
localNamespace setVariable [QGVAR(captureHooks), _hooks];
