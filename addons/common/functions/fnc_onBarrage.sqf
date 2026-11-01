#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: registers code to run when a virtual barrage is fired here
 * (FUNC(fireBarrage)) - the enemy's counter-battery radar reports it
 * (jmfsb_reaction_fnc_cbVirtual).
 *
 * Not a CBA event (review R1): any client could raise the old
 * jmfsb_common_barrage event to file a fake counter-battery report. The hooks
 * live in localNamespace, which is not networked. Local calls only.
 *
 * Arguments:
 * 0: Code, run with [position <ARRAY>, rounds <NUMBER>, shell <STRING>] <CODE>
 *
 * Return Value:
 * None
 *
 * Example:
 * [{params ["_pos"]; diag_log _pos}] call jmfsb_common_fnc_onBarrage
 *
 * Public: Yes
 */

params [["_code", {}, [{}]]];

if (!isServer || isRemoteExecuted) exitWith {};
if (_code isEqualTo {}) exitWith {};

private _hooks = localNamespace getVariable [QGVAR(barrageHooks), []];
_hooks pushBack _code;
localNamespace setVariable [QGVAR(barrageHooks), _hooks];
