#include "script_component.hpp"
/*
 * Author: YonV
 * Server: CLEARED TO LAND for a transport's lift or a QRF's air assault
 * circling its landing point (user, 2026-11-02: "either way transport needs
 * final permission to land") - the support core's landing wait calls this
 * (EFUNC(support,lzClear)). The job is marked cleared, with where: the mark
 * the caller verified, or the grid after NO SMOKE. The watch lands it on its
 * next tick (FUNC(liftTick), FUNC(qrfTick)).
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 * 1: Thread id <STRING>
 * 2: Where it lands <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["air:1", "T0042", _at] call jmfsb_support_air_fnc_liftCleared
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_threadId", "", [""]], ["_at", [], [[]]]];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("liftCleared: refused - remote call from machine %1",remoteExecutedOwner);
};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {};
private _qrf = (_logic getVariable [QGVAR(kind), ""]) isEqualTo KIND_QRF;
private _job = _logic getVariable [[QGVAR(liftJob), QGVAR(qrfJob)] select _qrf, createHashMap];
if ((_job getOrDefault ["thread", ""]) isNotEqualTo _threadId) exitWith {};
if ((_job getOrDefault ["landing", ""]) isNotEqualTo LANDING_CIRCLING) exitWith {};

_job set ["landing", LANDING_CLEARED];
if (count _at >= 2) then {_job set ["landAt", _at]};
INFO_3("liftCleared: %1 cleared to land at %2 (%3)",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],mapGridPosition _at,_threadId);
