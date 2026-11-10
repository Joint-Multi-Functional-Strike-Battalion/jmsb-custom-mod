#include "script_component.hpp"
/*
 * Author: YonV
 * One tasking, from a mission script or anything else: gate, validate,
 * dispatch to the provider that owns the asset, book the cooldown.
 *
 *   1. the tasking tag gate (FUNC(canTask)) - for every task, RTB included
 *   2. the asset id names a registered provider, and that provider still
 *      lists it
 *   3. unless the task is "rtb": the core cooldown ledger, then the
 *      provider's own "available" code if it has one
 *   4. the provider's "task" code, [assetId, task, pos, params]
 *   5. accepted: a cooldown it returned is booked on the server
 *      (FUNC(bookCooldown), by remoteExec), the row's call sign is sent
 *      for the asset's thread (FUNC(srvCallsign), by remoteExec), and
 *      QGVAR(tasked) is raised on this machine only (review S7/P8)
 *
 * RUNS WHERE IT IS CALLED. Today's providers task from the requesting client
 * and hand their heavy work to the server themselves (the CAS drones fly on
 * the server), so the core does not move
 * the call. The acknowledgement comes back later through FUNC(ack).
 *
 * Arguments:
 * 0: Asset id <STRING>
 * 1: Task token <STRING> - "rtb" recalls
 * 2: Position <ARRAY> (optional, default [] - the provider decides what none means)
 * 3: Parameters - the parameter array (README) <ARRAY> (optional, default [])
 *
 * Return Value:
 * 0: Accepted <BOOL>
 * 1: Why not, or the provider's own words when accepted ("" allowed) <STRING>
 *
 * Example:
 * ["cas:0", "SAD", getPosATL player, []] call jmfsb_support_fnc_request
 *
 * Public: Yes
 */

params [["_assetId", "", [""]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]]];

INFO_4("request: asset '%1' task '%2' pos %3 prm %4",_assetId,_task,_pos,_prm);

([player] call FUNC(canTask)) params ["_may", "_gateWhy"];
if (!_may) exitWith {[false, _gateWhy]};

if (_assetId isEqualTo "" || _task isEqualTo "") exitWith {
    WARNING("request: refused - no asset or no task");
    [false, "no task"]
};

([_assetId] call FUNC(provider)) params ["_kind", "_decl"];
if (_kind isEqualTo "") exitWith {
    WARNING_1("request: refused - no provider answers for '%1'",_assetId);
    [false, "no provider answers for that asset"]
};

private _rows = [] call (_decl get "assets");
if (isNil "_rows" || {!(_rows isEqualType [])} || {_rows findIf {(_x param [0, ""]) isEqualTo _assetId} < 0}) exitWith {
    WARNING_2("request: refused - '%1' no longer lists '%2'",_kind,_assetId);
    [false, "that unit is gone"]
};

private _isRtb = _task isEqualTo TASK_RTB;
if (!_isRtb) then {
    private _readyAt = (missionNamespace getVariable [QGVAR(readyAt), createHashMap]) getOrDefault [_assetId, 0];
    if (_readyAt > CBA_missionTime) exitWith {
        _gateWhy = format ["rearming - %1s", ceil (_readyAt - CBA_missionTime)];
    };
    if ("available" in _decl) then {
        ([_assetId] call (_decl get "available")) params [["_ok", true, [true]], ["_why", "", [""]]];
        if (!_ok) then {_gateWhy = [_why, "not available"] select (_why isEqualTo "")};
    };
};
if (_gateWhy isNotEqualTo "") exitWith {
    INFO_2("request: refused - %1: %2",_assetId,_gateWhy);
    [false, _gateWhy]
};

private _res = [_assetId, _task, _pos, _prm] call (_decl get "task");
if (isNil "_res" || {!(_res isEqualType [])}) exitWith {
    WARNING_2("request: provider '%1' gave no answer for '%2'",_kind,_assetId);
    [false, "the provider gave no answer"]
};
_res params [["_ok", false, [false]], ["_why", "", [""]], ["_cooldown", 0, [0]]];

if (_ok) then {
    if (_cooldown > 0 && !_isRtb) then {
        // By remoteExec, so the server knows who books it (review S6).
        [_assetId, _cooldown] remoteExecCall [QFUNC(bookCooldown), SERVER_OWNER];
    };
    // THE CALL SIGN THE ASSET ANSWERS ITS THREAD UNDER (2026-11-01). The
    // server cannot ask `assets` (it answers for `player`, null on a
    // dedicated server), so the row's own name is sent by remoteExec, checked
    // there like the cooldown (FUNC(srvCallsign)).
    private _callsign = (_rows select (_rows findIf {(_x param [0, ""]) isEqualTo _assetId})) param [2, ""];
    if (_callsign isEqualType "" && _callsign isNotEqualTo "") then {
        [_assetId, _callsign] remoteExecCall [QFUNC(srvCallsign), SERVER_OWNER];
    };
    // Local only (review S7/P8): nothing listens elsewhere, and a global
    // event's requester is whatever the raiser says. A count that must be
    // trusted belongs on the provider's server end, which knows the sender.
    [QGVAR(tasked), [_assetId, _task, _pos, _kind, player]] call CBA_fnc_localEvent;
    INFO_3("request: '%1' accepted '%2' for %3",_kind,_task,_assetId);
} else {
    INFO_3("request: '%1' refused %2 - %3",_kind,_assetId,_why);
};

[_ok, _why]
