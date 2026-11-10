#include "script_component.hpp"
/*
 * Author: YonV
 * A support request filed in a report (docs/DESIGN_MESSAGE_TEMPLATES.md, rule
 * 3 and decision 4, 2026-11-09: "a CAS, fires or CASEVAC request filed in a
 * TIC, SALUTE or MIST thread stays in that thread"). The composer opens on the
 * request card, INTO the report's thread, with:
 *
 *   TO       the support asset it goes to - the first asset of the card's type
 *            the support core lists for this player (FUNC(composeToSupport)),
 *            changed with CHANGE; the send carries it as the reply's
 *            addressee, which pulls that asset into the thread
 *            (FUNC(composeSend), the support core's srvFiled)
 *   a point  from a TIC its LOCATION, from a SALUTE its L - into the request's
 *            own anchor field (CAS line 6, CFF GRID's target, CASEVAC line 1)
 *   remarks  from a MIST, its lines into a CASEVAC's REMARKS
 *
 * Only a card the thread takes now (FUNC(threadLegal)).
 *
 * Arguments:
 * 0: The report's thread <STRING>
 * 1: The request card <STRING>
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * ["T0004", "cas"] call jmfsb_tacpad_fnc_starterInReport
 *
 * Public: No
 */

params [["_threadId", "", [""]], ["_cardId", "", [""]]];

if (_threadId isEqualTo "" || _cardId isEqualTo "") exitWith {false};
if (isNil QEFUNC(messaging,template)) exitWith {false};

private _template = [_cardId] call EFUNC(messaging,template);
private _short = toUpper (_template getOrDefault ["short", _cardId]);
if !(_cardId in ([_threadId] call FUNC(threadLegal))) exitWith {
    ["COMPOSE", format [TASK_NOT_TAKEN, _short], "high"] call EFUNC(messaging,notify);
    false
};

private _cached = (missionNamespace getVariable [QEGVAR(messaging,cache), createHashMap]) getOrDefault [_threadId, []];
private _thread = _cached param [0, createHashMap];
private _bodies = (_cached param [1, []]) apply {
    if (_x isEqualType []) then {createHashMapFromArray _x} else {_x}
};
private _root = _bodies param [0, createHashMap];
private _rootId = _thread getOrDefault ["rootTemplateId", _root getOrDefault ["templateId", ""]];
private _rootValues = createHashMapFromArray (_root getOrDefault ["payload", []]);

private _values = [];

// The report's point into the request's anchor.
private _anchor = _template getOrDefault ["anchor", ""];
private _pointAt = REPORT_POINT_KEYS findIf {(_x select 0) isEqualTo _rootId};
if (_anchor isNotEqualTo "" && _pointAt >= 0) then {
    private _point = _rootValues getOrDefault [(REPORT_POINT_KEYS select _pointAt) select 1, ""];
    if (_point isEqualTo "" || {_point isEqualTo []}) then {_point = [_threadId] call FUNC(autoAnchor)};
    if (_point isNotEqualTo "" && {_point isNotEqualTo []}) then {_values pushBack [_anchor, _point]};
};

// A MIST's lines into a CASEVAC's remarks.
if (_rootId isEqualTo REPORT_MIST && _cardId isEqualTo REPORT_MIST_CARD) then {
    private _text = [REPORT_MIST, _root getOrDefault ["payload", []], false] call EFUNC(messaging,render);
    private _lines = (_text splitString endl) apply {trim _x} select {_x isNotEqualTo ""};
    if (_lines isNotEqualTo []) then {_values pushBack [REPORT_MIST_REMARKS, _lines joinString REPORT_MIST_SEP]};
};

// TO: the first asset of the card's type this player may task.
private _to = "";
if (!isNil QEFUNC(support,mailboxes)) then {
    ([true, _cardId] call FUNC(composeToSupport)) params ["_show", "_forCard", "_rows"];
    if (_show && _forCard && _rows isNotEqualTo []) then {_to = (_rows select 0) param [0, ""]};
};

private _opened = [_threadId, _cardId, false, _to, _values] call FUNC(composeOpen);
if (_opened) then {GVAR(composeNote) = format [REPORT_NOTE, _threadId, _short]};

_opened
