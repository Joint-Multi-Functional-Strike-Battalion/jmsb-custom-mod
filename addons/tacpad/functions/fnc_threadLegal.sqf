#include "script_component.hpp"
/*
 * Author: YonV
 * The cards this player may file into a thread now - the reader's one rule for
 * every place that offers them: ACK, the quick-reply row (FUNC(readerQuick)),
 * + TEMPLATE (FUNC(composePicker)), the FLASH banner's reply and the net
 * view's composer. The server decides again (EFUNC(messaging,srvThreadFor)).
 *
 * THE REPLIES THE THREAD'S STATE TAKES (EFUNC(messaging,templateIds)); none
 * once it is over.
 *
 * THE CLASS OF A CARD (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09 - the
 * template options EFUNC(messaging,registerTemplate) keeps):
 *
 *   assetOnly    what the asset says (SHOT, WHEELS DOWN, STATUS REPLY ...)
 *                - jmfsb_support_fnc_assetCard, with ROGER, WILCO, ON TASK and
 *                CANTCO: never offered in a thread an AI asset answers, nor to
 *                the issuer of a support card in his own thread to a player
 *                crew (the crew answers with them)
 *   answerOnly   HOT, COLD, CORRECT ... - only as an answer to the asset's
 *                question: offered only when the caller says it is building
 *                that question's answers (argument 2 - FUNC(readerQuickTiles)'s
 *                QUICK REPLY row, the phone's quick keys)
 *   assetThread  FRAGO, STATUS, HOLD, ABORT, RTB, ROGER - only in a thread an
 *                AI asset answers
 *   roots        only where the thread's CURRENT order card is one of them
 *                (EFUNC(messaging,currentOrder) over the cached bodies, else
 *                the thread's root): the landing commands in a transport's
 *                thread, the CAS commands in a flight's, ESCORT in every
 *                transport's
 *
 * EACH STARTER IS THE NEXT TASKING (rule 1, 2026-11-09). In a thread an AI
 * asset answers, its issuer is also offered the ROOT cards that asset flies
 * after the thread's current order (jmfsb_support_fnc_threadCards, for the
 * current card and the root).
 *
 * A REPORT HOSTS THE REQUEST (rule 3, decision 4). In a TIC, SALUTE or MIST
 * thread (REPORT_HOSTS) with no asset in it yet, anyone it reached is offered
 * the support starters (REPORT_STARTERS): the composer asks which asset on its
 * TO line and files it into the thread (FUNC(starterInReport)).
 *
 * AN AI ASSET'S THREAD is one with an asset's box among its boxes
 * (SUPPORT_BOX_PREFIX) - its own box, or a report it was pulled into.
 *
 * Arguments:
 * 0: Thread id <STRING>
 * 1: The thread, when the caller holds it - else the cached one <HASHMAP> (optional, default empty)
 * 2: Answering the asset's question - answerOnly cards kept <BOOL> (optional, default false)
 *
 * Return Value:
 * Template ids <ARRAY of STRINGs>
 *
 * Example:
 * private _legal = ["T0004"] call jmfsb_tacpad_fnc_threadLegal
 *
 * Public: No
 */

params [["_threadId", "", [""]], ["_thread", createHashMap, [createHashMap]], ["_answering", false, [false]]];

if (_threadId isEqualTo "" || isNil QEFUNC(messaging,templateIds)) exitWith {[]};

private _cached = (missionNamespace getVariable [QEGVAR(messaging,cache), createHashMap]) getOrDefault [_threadId, []];
if (_thread isEqualTo createHashMap) then {
    _thread = _cached param [0, createHashMap];
};
private _bodies = (_cached param [1, []]) apply {
    if (_x isEqualType []) then {createHashMapFromArray _x} else {_x}
};
private _rows = missionNamespace getVariable [QEGVAR(messaging,index), []];
private _rowAt = _rows findIf {
    _x isEqualType createHashMap && {(_x getOrDefault ["threadId", ""]) isEqualTo _threadId}
};
private _row = createHashMap;
if (_rowAt >= 0) then {_row = _rows select _rowAt};

private _status = _thread getOrDefault ["status", _row getOrDefault ["status", ""]];
if ((_thread getOrDefault ["closed", false]) isEqualTo true || _status in THREAD_OVER_STATES) exitWith {[]};

private _legal = ["reply", _status] call EFUNC(messaging,templateIds);

private _rootId = _thread getOrDefault ["rootTemplateId", _row getOrDefault ["templateId", ""]];
private _current = ([_bodies] call EFUNC(messaging,currentOrder)) param [0, ""];
if (_current isEqualTo "") then {_current = _rootId};
private _boxId = _row getOrDefault ["boxId", ""];
private _mine = (getPlayerUID player) isEqualTo (_thread getOrDefault ["issuerUid", ""]);

// An AI asset's thread: an asset's box among the thread's boxes.
private _boxes = (_thread getOrDefault ["boxes", []]) + [_boxId];
private _assetBoxAt = _boxes findIf {
    _x isEqualType "" && {(toUpper (_x select [0, count SUPPORT_BOX_PREFIX])) isEqualTo SUPPORT_BOX_PREFIX}
};
private _asset = _assetBoxAt >= 0;
private _assetBox = _boxes param [_assetBoxAt max 0, ""];
// A report the asset was pulled into: its issuer is whoever filed the request.
if (_asset && _rootId in REPORT_HOSTS) then {
    private _requestAt = _bodies findIf {(_x getOrDefault ["templateId", ""]) isEqualTo _current};
    if (_requestAt >= 0) then {_mine = (getPlayerUID player) isEqualTo ((_bodies select _requestAt) getOrDefault ["fromUid", ""])};
};

// The class of each card.
_legal = _legal select {
    private _t = [_x] call EFUNC(messaging,template);
    private _roots = _t getOrDefault ["roots", []];
    (_answering || !(_t getOrDefault ["answerOnly", false]))
    && {_asset || !(_t getOrDefault ["assetThread", false])}
    && {_roots isEqualTo [] || {_current in _roots} || {_rootId in _roots}}
};

if (_asset && _mine && !isNil QEFUNC(support,threadCards)) then {
    {_legal pushBackUnique _x} forEach (([_assetBox, _current] call EFUNC(support,threadCards)) + ([_assetBox, _rootId] call EFUNC(support,threadCards)));
};

// A report hosting a support request: the starters, to anyone it reached.
if (!_asset && _rootId in REPORT_HOSTS && !isNil QEFUNC(support,mailboxes)) then {
    {
        if (([_x] call EFUNC(messaging,template)) isNotEqualTo createHashMap) then {_legal pushBackUnique _x};
    } forEach REPORT_STARTERS;
};

private _support = (QUICK_SUPPORT findIf {(_x select 0) isEqualTo _current}) >= 0;
if ((_asset || (_mine && _support)) && !isNil QEFUNC(support,assetCard)) then {
    _legal = _legal select {!([_x] call EFUNC(support,assetCard))};
};

_legal
