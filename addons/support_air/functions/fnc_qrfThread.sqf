#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a REACT/QRF LINK-UP card (`qrf`) filed to a QRF module's box
 * (2026-11-01, DESIGN_SUPPORT_MESSAGING step 7) - from FUNC(srvThread). The
 * core has asked the issuer's tasking gate and his side already; this asks the
 * module's own questions again (FUNC(reach), FUNC(check)).
 *
 * THE CARD, field by field (EFUNC(support,readOrder), kind "qrf"):
 *   Line 2     the link-up point - where the squad is put down; none: "NO
 *              TARGET LOCATION"
 *   Line 1     who links up with whom, repeated in the WILCO
 *   Line 3 / 4 / 5 / REMARKS
 *              STATIC LINE when one of them says STATIC, PARA or JUMP and the
 *              module flies it; else AIR ASSAULT when it flies that; else
 *              what it flies
 *   Line 5     the action on arrival: JOIN - the squad joins the issuer's
 *              group; DEFEND, HOLD, CORDON, BLOCK, SECURE, CCP - it holds the
 *              point; anything else - the module's On The Ground
 *
 * THE THREAD: ROGER (the core), WILCO "ETA m:ss - <method> - <who>", WHEELS UP
 * and ON TASK at the launch (FUNC(qrfLaunch)); an air assault circles the
 * point until the mark is verified and it is CLEARED TO LAND (user,
 * 2026-11-02, FUNC(qrfTick)); WHEELS DOWN where it lands or ropes, then SQUAD DOWN AT <grid> - <n> MEN -
 * HOLDING / YOURS - LINKED UP? (received / close) when the squad is on the
 * ground (FUNC(qrfLanded)); the answer closes it (FUNC(qrfReply)), D9 too
 * (FUNC(threadTimeout)).
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 * 1: Thread <HASHMAP>
 * 2: Its root message <HASHMAP>
 * 3: The issuer <OBJECT>
 *
 * Return Value:
 * [ok, why]; [] for a card this provider does not fly <ARRAY>
 *
 * Example:
 * ["air:3", _thread, _message, _issuer] call jmfsb_support_air_fnc_qrfThread
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
    WARNING_1("qrfThread: refused - remote call from machine %1",remoteExecutedOwner);
    []
};

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, WHY_LOST]};

private _order = [_thread, _message] call EFUNC(support,readOrder);
if ((_order getOrDefault ["kind", ""]) isNotEqualTo ORDER_LINKUP) exitWith {[]};

private _threadId = _thread getOrDefault ["id", ""];
private _callsign = _logic getVariable [QGVAR(callsign), "QRF"];

private _linkup = _order getOrDefault ["linkup", []];
if (_linkup isEqualTo []) exitWith {[false, WHY_NO_TARGET]};
// ONE THREAD AT A TIME. One left waiting for its link-up is closed.
private _was = _logic getVariable [QGVAR(qrfJob), createHashMap];
if ((_was getOrDefault ["step", ""]) isEqualTo JOB_LINKUP) then {
    [_logic, "CLOSED", _was getOrDefault ["line", SAID_RETASKED], _was get "thread"] call FUNC(threadState);
    _logic setVariable [QGVAR(qrfJob), nil];
    _logic setVariable [QGVAR(threadHold), nil];
};
if (count (_logic getVariable [QGVAR(qrfJob), createHashMap]) > 0) exitWith {[false, WHY_TASKED]};

([_assetId, _linkup] call FUNC(reach)) params ["_can", "_eta", "_reachWhy"];
if (!_can) exitWith {[false, _reachWhy]};

// THE METHOD.
private _allowed = _logic getVariable [QGVAR(allowed), []];
private _text = toUpper ([_order get "route", _order get "attachments", _order get "action", _order get "remarks"] joinString " ");
private _static = (QRF_STATIC_WORDS findIf {_x in _text}) >= 0;
private _task = _allowed param [0, TASK_STATIC];
if (TASK_ASSAULT in _allowed) then {_task = TASK_ASSAULT};
if (_static && TASK_STATIC in _allowed) then {_task = TASK_STATIC};

([_logic, _task, _linkup, [], _issuer] call FUNC(check)) params ["_ok", "_checkWhy", "_at"];
if (!_ok) exitWith {[false, toUpper _checkWhy]};

// ON THE GROUND: the card's action, else the module's.
private _action = _order getOrDefault ["action", ""];
private _onLanding = -1;
if ((QRF_DEFEND_WORDS findIf {_x in _action}) >= 0) then {_onLanding = ON_LANDING_DEFEND};
if ((QRF_JOIN_WORDS findIf {_x in _action}) >= 0) then {_onLanding = ON_LANDING_JOIN};

_logic setVariable [QGVAR(qrfJob), createHashMapFromArray [
    ["thread", _threadId],
    ["issuer", _issuer],
    ["onLanding", _onLanding],
    ["step", JOB_FLYING],
    ["line", ""],
    // An air assault circles its landing point until cleared (user,
    // 2026-11-02, FUNC(qrfTick), FUNC(liftCleared)).
    ["landing", ""],
    ["landAt", []]
]];
_logic setVariable [QGVAR(sortieThread), _threadId];
INFO_4("qrfThread: %1 %2 at %3 for %4",_callsign,_task,mapGridPosition _at,name _issuer);

// WILCO first: the module's own "copy" (FUNC(say)) is a receipt too, and the
// first one said is the one the thread keeps.
private _method = [DECL_ASSAULT select 1, DECL_STATIC select 1] select (_task isEqualTo TASK_STATIC);
private _words = [[_eta] call EFUNC(support,etaText), _method, toUpper ((_order getOrDefault ["who", ""]) select [0, DESCRIPTION_MAX])];
[_assetId, "ACCEPTED", (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP, _callsign, false, _threadId] call EFUNC(support,state);
// ITS LANDING POINT IN THE SIDE'S AiTR (user, 2026-11-02: "in AiTR lz and drop
// zones need to be highlighted") - an LZ, or the static line's DZ - until the
// squad is down (FUNC(qrfLanded)).
[_threadId, [[[ZONE_QRF, ZONE_QRF_DROP] select (_task isEqualTo TASK_STATIC), _at, _callsign]], side group _issuer] call EFUNC(support,zones);

[_logic, _task, _at, [], _issuer] call FUNC(qrfOrder);
if ((_logic getVariable [QGVAR(status), STATUS_IDLE]) isNotEqualTo STATUS_LAUNCHING) then {
    [_logic, "DECLINED", WHY_TASKED, _threadId] call FUNC(threadState);
    _logic setVariable [QGVAR(qrfJob), nil];
    _logic setVariable [QGVAR(sortieThread), nil];
};
[true, ""]
