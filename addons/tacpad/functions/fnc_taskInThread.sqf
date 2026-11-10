#include "script_component.hpp"
/*
 * Author: YonV
 * A new task for the asset, in its own thread (2026-11-02): the composer on a
 * ROOT card the thread's asset takes there, filed INTO the thread - the tile
 * an asset's question offers (FURTHER TASKING? - CAS; HOLD, RTB OR NEXT LIFT?
 * - LIFT REQUEST) and the card + TEMPLATE offers its issuer. SEND SITREP's way
 * (FUNC(sitrepAfterTic)): one press opens the card, the line beside SEND says
 * where it goes. The asset answers it in the thread with a fresh WILCO (the
 * provider's "task" - jmfsb_support_fnc_srvFollowUp).
 *
 * Only a card the thread takes now from this player (FUNC(threadLegal)) - the
 * thread may have closed since the row was drawn.
 *
 * Arguments:
 * 0: Thread id <STRING>
 * 1: Card id <STRING>
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * ["T0004", "cas"] call jmfsb_tacpad_fnc_taskInThread
 *
 * Public: No
 */

params [["_threadId", "", [""]], ["_cardId", "", [""]]];

if (_threadId isEqualTo "" || _cardId isEqualTo "") exitWith {false};
if (isNil QEFUNC(messaging,template)) exitWith {false};

// A report with no asset in it yet (2026-11-09): the request goes to an asset
// picked on the TO line, with the report's point (FUNC(starterInReport)).
private _host = ((missionNamespace getVariable [QEGVAR(messaging,cache), createHashMap]) getOrDefault [_threadId, []]) param [0, createHashMap];
private _hostAsset = ((_host getOrDefault ["boxes", []]) findIf {
    _x isEqualType "" && {(toUpper (_x select [0, count SUPPORT_BOX_PREFIX])) isEqualTo SUPPORT_BOX_PREFIX}
}) >= 0;
if (!_hostAsset && (_host getOrDefault ["rootTemplateId", ""]) in REPORT_HOSTS) exitWith {
    [_threadId, _cardId] call FUNC(starterInReport)
};

private _template = [_cardId] call EFUNC(messaging,template);
private _short = toUpper (_template getOrDefault ["short", _cardId]);
if !(_cardId in ([_threadId] call FUNC(threadLegal))) exitWith {
    ["COMPOSE", format [TASK_NOT_TAKEN, _short], "high"] call EFUNC(messaging,notify);
    false
};

// Who it goes to: the asset the thread is filed to, by its call sign.
private _rows = missionNamespace getVariable [QEGVAR(messaging,index), []];
private _rowAt = _rows findIf {
    _x isEqualType createHashMap && {(_x getOrDefault ["threadId", ""]) isEqualTo _threadId}
};
private _to = "";
if (_rowAt >= 0 && !isNil QEFUNC(support,boxName)) then {
    _to = [(_rows select _rowAt) getOrDefault ["boxId", ""]] call EFUNC(support,boxName);
};

private _opened = [_threadId, _cardId] call FUNC(composeOpen);
if (_opened) then {GVAR(composeNote) = format [TASK_IN_THREAD_NOTE, _threadId, _to]};

_opened
