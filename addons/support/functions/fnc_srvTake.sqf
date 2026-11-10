#include "script_component.hpp"
/*
 * Author: YonV
 * Server: an asset is given a thread (FUNC(srvFiled)) - the thread's root
 * filed to its box, or a starter filed into an open report that pulls it in
 * (2026-11-09, docs/DESIGN_MESSAGE_TEMPLATES.md rule 3). Split out of
 * srvFiled so both take the same path: the issuer asked again (review S6),
 * the asset's open thread set, RECEIPT after RECEIPT_HOLD s, and a task card
 * handed to the provider's "thread" hook - [assetId, thread, the order
 * message, issuer] -> [ok, why]; a refusal is the CANTCO and the asset goes
 * back to the thread it had.
 *
 * Arguments:
 * 0: Thread <HASHMAP>
 * 1: The order message - the root, or the starter filed into the thread <HASHMAP>
 * 2: Box ids to look for the asset's box in <ARRAY of STRINGs>
 * 3: The Steam id of the man the asset takes orders from <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_thread, _message, _boxIds, _issuerUid] call jmfsb_support_fnc_srvTake
 *
 * Public: No
 */

params [
    ["_thread", createHashMap, [createHashMap]],
    ["_message", createHashMap, [createHashMap]],
    ["_boxIds", [], [[]]],
    ["_issuerUid", "", [""]]
];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("srvTake: refused - remote call from machine %1",remoteExecutedOwner);
};

private _threadId = _thread getOrDefault ["id", ""];
private _at = allPlayers findIf {(getPlayerUID _x) isEqualTo _issuerUid};
private _issuer = objNull;
if (_at >= 0) then {_issuer = allPlayers select _at};
private _task = (_thread getOrDefault ["kind", ""]) isEqualTo THREAD_KIND_TASK;

private _prefixLength = count SUPPORT_BOX_PREFIX;
{
    if !(_x isEqualType "") then {continue};
    if ((toUpper (_x select [0, _prefixLength])) isNotEqualTo SUPPORT_BOX_PREFIX) then {continue};

    private _assetId = _x select [_prefixLength];
    ([_assetId] call FUNC(provider)) params ["_kind", "_decl"];
    if (_kind isEqualTo "") then {
        INFO_2("thread %1: filed to %2 - no support provider answers for that id",_threadId,_x);
        continue;
    };

    // THE ISSUER, asked again (review S6).
    if (isNull _issuer) then {
        INFO_2("thread %1: %2 - the issuer is not on the server",_threadId,_assetId);
        continue;
    };
    ([_issuer] call FUNC(canTask)) params ["_may", "_gateWhy"];
    if (!_may) then {
        WARNING_3("thread %1: %2 not taken - %3",_threadId,_assetId,_gateWhy);
        continue;
    };
    private _sideCode = _decl getOrDefault ["side", {}];
    if (_sideCode isNotEqualTo {}) then {
        private _assetSide = [_assetId] call _sideCode;
        if (isNil "_assetSide") then {_assetSide = sideUnknown};
        if (_assetSide isNotEqualTo (side group _issuer)) then {
            WARNING_3("thread %1: %2 not taken - it is not %3's side's asset",_threadId,_assetId,name _issuer);
            continue;
        };
    };

    private _open = localNamespace getVariable [QGVAR(threads), createHashMap];
    private _was = _open getOrDefault [_assetId, ""];
    _open set [_assetId, _threadId];
    localNamespace setVariable [QGVAR(threads), _open];
    // Every thread the asset was given, so a provider can answer the one it
    // means (FUNC(state)) while a newer one is the open thread.
    private _assets = localNamespace getVariable [QGVAR(threadAssets), createHashMap];
    _assets set [_threadId, _assetId];
    localNamespace setVariable [QGVAR(threadAssets), _assets];
    INFO_3("thread %1: %2's open thread (was '%3')",_threadId,_assetId,_was);

    // ROGER, WILCO IS ONE MESSAGE (user, 2026-11-01: "did get 2 messages roger
    // wilco which is one message"). The receipt waits RECEIPT_HOLD s: an
    // asset that takes it (or cannot) inside that answers once - FUNC(srvReply)
    // folds the ROGER into its WILCO, or leaves it off a CANTCO. A slow one
    // still says ROGER now and WILCO later.
    private _due = localNamespace getVariable [QGVAR(receiptsDue), createHashMap];
    localNamespace setVariable [QGVAR(receiptsDue), _due];
    _due set [[_threadId, _assetId], true];
    [{
        params ["_threadId", "_assetId"];
        private _due = localNamespace getVariable [QGVAR(receiptsDue), createHashMap];
        if !([_threadId, _assetId] in _due) exitWith {};
        _due deleteAt [_threadId, _assetId];
        [_assetId, STATE_RECEIPT, "", "", false, _threadId] call FUNC(state);
    }, [_threadId, _assetId], RECEIPT_HOLD] call CBA_fnc_waitAndExecute;

    // THE PROVIDER ACTS ON IT (2026-11-01) - a task card only.
    if (!_task) then {continue};
    private _hook = _decl getOrDefault ["thread", {}];
    if (_hook isEqualTo {}) then {continue};

    // A NO-FIRE AREA BLOCKS FIRES (2026-11-07, the C2 measures of
    // docs/DESIGN_WATCH_HUD.json): a fires or CAS task card from an issuer
    // standing inside one of his side's no-fire areas is the CANTCO, and the
    // provider never sees it.
    private _nfa = "";
    if (((_assetId splitString ":") param [0, ""]) in NO_FIRE_KINDS && {!isNil QEFUNC(c2,inNoFire)}) then {
        _nfa = [getPosATL _issuer, side group _issuer] call EFUNC(c2,inNoFire);
    };
    private _answer = if (_nfa isNotEqualTo "") then {
        [false, format ["REQUESTER INSIDE NO FIRE AREA %1", _nfa]]
    } else {
        [_assetId, _thread, _message, _issuer] call _hook
    };
    if (isNil "_answer") then {_answer = []};
    if !(_answer isEqualType []) then {_answer = []};
    if (count _answer < ANSWER_FIELDS) then {
        INFO_2("thread %1: %2's provider left the card - the thread stays at RECEIPT",_threadId,_assetId);
        continue;
    };
    _answer params [["_ok", false, [false]], ["_why", "", [""]]];
    if (_ok) then {
        INFO_2("thread %1: %2 takes it",_threadId,_assetId);
        continue;
    };

    // CANTCO, and the asset answers what it was on before.
    if (_why isEqualTo "") then {_why = WHY_UNABLE};
    INFO_3("thread %1: %2 cannot - %3",_threadId,_assetId,_why);
    [_assetId, STATE_DECLINED, _why, "", false, _threadId] call FUNC(state);
    if (_was isEqualTo "") then {
        _open deleteAt _assetId;
    } else {
        _open set [_assetId, _was];
    };
} forEach _boxIds;
