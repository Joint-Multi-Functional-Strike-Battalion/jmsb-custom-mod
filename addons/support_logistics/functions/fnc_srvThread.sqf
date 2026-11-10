#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a card filed to a logistics module's box - the "thread" code this
 * addon hands the support core (2026-11-01, DESIGN_SUPPORT_MESSAGING step 7;
 * user: "per the doc i want to use the messaging system to call ai support").
 * The core has asked the issuer's tasking gate and his side already; this
 * finds the module by its id and asks its own questions again (FUNC(reach),
 * FUNC(check) - the order's own check).
 *
 * THE CARDS, field by field (EFUNC(support,readOrder)):
 *   `resupply`  Item N: the catalog item by name (FUNC(catalogFind)) - a pick
 *               of the pre-made crates in the composer since 2026-11-02
 *               (FUNC(catalogNames)) - and its COUNT (1 when empty); a name
 *               the catalog does not have:
 *               CANTCO "NO STORES <NAME>". The delivery point (none: "NO
 *               TARGET LOCATION"). METHOD: AIRDROP or SLING (none: the first
 *               the module flies; one it does not: "NO <METHOD>"; SLING only
 *               for what the hook lifts - FUNC(check)'s reason). MARKING: the
 *               word, and its colour for smoke and chemlights (MARK_COLOURS);
 *               a word the module does not know (PANEL, OTHER) is its own mark
 *   `airdrop`   a PARADROP since the report-card review (user, 2026-11-02,
 *               decision 3) - a transport's card: CANTCO "PARADROP IS A
 *               TRANSPORT CARD - SEND RESUPPLY". Supplies by air are a
 *               `resupply` with METHOD AIRDROP
 * Busy, turning round or spent: the reach card's words; over the capacity:
 * the check's.
 *
 * THE THREAD: ROGER (the core), WILCO "ETA m:ss - <what> - <method>", ON TASK
 * at the launch, then after the last item is down PACKAGE AWAY - CONFIRM
 * RECEIPT (received / notfound, FUNC(account)); the answer closes it
 * (FUNC(threadReply)), D9 too (FUNC(threadTimeout)). Nothing delivered: CLOSED
 * with why, no receipt.
 *
 * Arguments:
 * 0: Asset id, "logi:<n>" <STRING>
 * 1: Thread <HASHMAP>
 * 2: Its root message <HASHMAP>
 * 3: The issuer <OBJECT>
 *
 * Return Value:
 * [ok, why]; [] for a card this provider does not fly <ARRAY>
 *
 * Example:
 * ["logi:0", _thread, _message, _issuer] call jmfsb_support_logistics_fnc_srvThread
 *
 * Public: No
 */

params [
    ["_assetId", "", [""]],
    ["_thread", createHashMap, [createHashMap]],
    ["_message", createHashMap, [createHashMap]],
    ["_issuer", objNull, [objNull]]
];

if (!isServer) exitWith {[]};
if (isRemoteExecuted) exitWith {
    WARNING_1("srvThread: refused - remote call from machine %1",remoteExecutedOwner);
    []
};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, WHY_LOST]};
// NO AIRFRAME LEFT (user, 2026-11-02: "a respawn count for each support,
// default no respawns"): whatever the card.
if (_logic getVariable [QGVAR(gone), false]) exitWith {[false, WHY_NO_AIRFRAME]};

private _order = [_thread, _message] call EFUNC(support,readOrder);
private _kind = _order getOrDefault ["kind", ""];
if (_kind isEqualTo ORDER_DROP) exitWith {[false, WHY_PARADROP]};
if (_kind isNotEqualTo ORDER_SUPPLY) exitWith {[]};

private _threadId = _thread getOrDefault ["id", ""];
private _callsign = _logic getVariable [QGVAR(callsign), DEF_CALLSIGN];

// ONE THREAD AT A TIME. One left waiting for its receipt is closed.
private _was = _logic getVariable [QGVAR(threadJob), createHashMap];
if ((_was getOrDefault ["step", ""]) isEqualTo JOB_RECEIPT) then {
    [_logic, "CLOSED", _was getOrDefault ["line", SAID_RETASKED], _was get "thread"] call FUNC(threadState);
    _logic setVariable [QGVAR(threadJob), nil];
};
if (count (_logic getVariable [QGVAR(threadJob), createHashMap]) > 0) exitWith {[false, WHY_TASKED]};

private _point = _order getOrDefault ["point", []];
if (_point isEqualTo []) exitWith {[false, WHY_NO_TARGET]};
([_assetId, _point] call FUNC(reach)) params ["_can", "_eta", "_reachWhy"];
if (!_can) exitWith {[false, _reachWhy]};

// WHAT: the card's items by name.
private _catalog = _logic getVariable [QGVAR(catalog), []];
private _wanted = _order getOrDefault ["items", []];
private _cart = [];
private _unknown = "";
{
    _x params ["_name", "_count"];
    private _index = [_catalog, _name] call FUNC(catalogFind);
    if (_index < 0) exitWith {_unknown = toUpper _name};
    _cart pushBack [_index, _count];
} forEach _wanted;
if (_unknown isNotEqualTo "") exitWith {[false, format [WHY_NO_STORES_OF, _unknown]]};

// HOW: the card's method, else the first the module flies.
private _offered = ([_assetId, []] call FUNC(tasks)) apply {_x select 0};
private _method = _order getOrDefault ["method", ""];
private _task = _offered param [0, TASK_AIRDROP];
if (_method isNotEqualTo "") then {
    _task = _method;
    private _at = METHODS findIf {(_x select 0) isEqualTo _method};
    if (_at >= 0) then {_task = (METHODS select _at) select 1};
};
if !(_task in _offered) exitWith {[false, format [WHY_NO_METHOD, _method]]};

// THE MARKING: the word, and its colour where a colour has a class.
private _marking = _order getOrDefault ["marking", ""];
private _markIdx = (MARK_WORDS find _marking) max 0;
private _signal = "";
private _colours = MARK_COLOURS select {(_x select 0) isEqualTo _marking};
if (_colours isNotEqualTo []) then {
    private _colour = _order getOrDefault ["colour", ""];
    private _hit = ((_colours select 0) select 1) select {(_x select 0) isEqualTo _colour};
    if (_hit isNotEqualTo []) then {_signal = (_hit select 0) select 1};
};

private _prm = [];
_prm resize (SLOT_COUNT + 1);
_prm set [SLOT_CART, _cart];
_prm set [SLOT_MARK, _markIdx];
([_logic, _task, _point, _prm, _issuer] call FUNC(check)) params ["_ok", "_checkWhy", "_at", "_checked"];
if (!_ok) exitWith {[false, toUpper _checkWhy]};

// WILCO first: the module's own "copy" (FUNC(say)) is a receipt too, and the
// first one said is the one the thread keeps.
private _what = [[_catalog, _checked] call FUNC(cartNames)] call FUNC(countLine);
private _words = [[_eta] call EFUNC(support,etaText), toUpper _what, _task];
[_assetId, "ACCEPTED", (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP, _callsign, false, _threadId] call EFUNC(support,state);
// THE DELIVERY POINT IN THE SIDE'S AiTR from the WILCO (user, 2026-11-02) until
// the thread closes - the receipt, so it is there while the load is looked for.
[_threadId, [[[ZONE_RESUPPLY, ZONE_SLING] select (_task isEqualTo TASK_SLING), _at, _callsign]], side group _issuer] call EFUNC(support,zones);

if (_signal isEqualTo "") then {
    _signal = [MARK_CLASSES select _markIdx, _logic getVariable [QGVAR(signalClass), ""]] select (_markIdx isEqualTo 0);
};
_logic setVariable [QGVAR(threadJob), createHashMapFromArray [
    ["thread", _threadId],
    ["issuer", _issuer],
    ["step", JOB_FLYING],
    ["signal", _signal],
    ["line", ""],
    ["items", []]
]];
INFO_4("srvThread: %1 %2 %3 for %4",_callsign,_task,_what,name _issuer);

[_logic, _task, _at, _prm, _issuer, _checked, _signal] call FUNC(deliver);
if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isNotEqualTo STATUS_LAUNCHING) then {
    [_logic, "DECLINED", WHY_TASKED, _threadId] call FUNC(threadState);
    _logic setVariable [QGVAR(threadJob), nil];
};
[true, ""]
