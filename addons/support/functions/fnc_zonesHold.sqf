#include "script_component.hpp"
/*
 * Author: YonV
 * Server: keeps a thread's zones (FUNC(zones)) past its close while its
 * jumpers are still in the air - a jump's thread closes as the aircraft leaves
 * the DZ, which is when the stick needs the DZ most (user, 2026-11-02: "in AiTR
 * lz and drop zones need to be highlighted"). They go once every jumper is down
 * (alive and under ZONE_DOWN_AGL m) or dead, looked at every ZONE_HOLD_TICK s,
 * ZONE_HOLD_MAX s at most. Called before the provider closes the thread.
 *
 * Arguments:
 * 0: Thread id <STRING>
 * 1: The jumpers <ARRAY of OBJECTs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_threadId, _st get "jumpers"] call jmfsb_support_fnc_zonesHold
 *
 * Public: Yes
 */

params [["_threadId", "", [""]], ["_units", [], [[]]]];

if (!isServer || _threadId isEqualTo "") exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("zonesHold: refused - remote call from machine %1",remoteExecutedOwner);
};

private _all = localNamespace getVariable [QGVAR(zoneThreads), createHashMap];
private _entry = _all getOrDefault [_threadId, []];
if (_entry isEqualTo [] || {_entry select 2}) exitWith {};
_entry set [2, true];

[{
    params ["_args", "_handle"];
    _args params ["_threadId", "_units", "_until"];
    private _falling = _units findIf {!isNull _x && {alive _x} && {((getPos _x) select 2) > ZONE_DOWN_AGL}};
    if (_falling >= 0 && CBA_missionTime < _until) exitWith {};
    [_handle] call CBA_fnc_removePerFrameHandler;

    private _all = localNamespace getVariable [QGVAR(zoneThreads), createHashMap];
    private _entry = _all getOrDefault [_threadId, []];
    if (_entry isEqualTo [] || {!(_entry select 2)}) exitWith {};
    _entry set [2, false];
    [_threadId, []] call FUNC(zones);
}, ZONE_HOLD_TICK, [_threadId, _units select {_x isEqualType objNull}, CBA_missionTime + ZONE_HOLD_MAX]] call CBA_fnc_addPerFrameHandler;
