#include "script_component.hpp"
/*
 * Author: JMSB
 * One thread in the reader's list (handoff 1a, pane 2): the priority chip, the
 * template type and the time on the meta line; the subject; a preview; and the
 * reply meta. Selected is the accent tint with a 4 px accent bar down the left;
 * closed is the whole row in the dim tone. FLASH is said by the chip alone - a
 * tinted row means "the one you are reading" and nothing else.
 *
 * Arguments:
 * 0: Content group <CONTROL>
 * 1: Index row <HASHMAP>
 * 2: Row rectangle [x, y, w, h] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_root, _entry, [_lx, _ey, _listW, _entryH]] call jmfsb_tacpad_fnc_readerRow
 *
 * Public: No
 */

params [["_root", controlNull, [controlNull]], ["_entry", createHashMap, [createHashMap]], ["_rect", [0, 0, 0, 0], [[]], 4]];

if (isNull _root) exitWith {};

_rect params ["_rx", "_ry", "_rw", "_rh"];

([] call FUNC(theme)) params ["", "_ink", "_accent", "_line"];
private _muted = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);
private _deep = ["accentDeep"] call FUNC(theme);
private _accentText = ["accentText"] call FUNC(theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;

private _threadId = _entry getOrDefault ["threadId", ""];
private _selected = _threadId == GVAR(readerThread);
private _closed = (_entry getOrDefault ["status", ""]) in ["CLOSED", "ABORTED"];
private _unread = _entry getOrDefault ["unread", 0];

if (_selected) then {
    [_root, [_rx, _ry, _rw, _rh], ["accentTint"] call FUNC(theme)] call FUNC(drawFill);
    [_root, [_rx, _ry, READER_BAR_PX * pixelW, _rh], _accent] call FUNC(drawFill);
};

private _left = _rx + READER_INSET * _pad + ([0, READER_BAR_PX * pixelW] select _selected);
private _textW = _rx + _rw - READER_INSET * _pad - _left;
private _y = _ry + READER_INSET * _padY;

// A closed row steps every colour down to the dim tone - the design's 62 % row.
private _head = [_ink, _dim] select _closed;
private _body = [[_muted, _ink] select _selected, _dim] select _closed;
private _label = [[_muted, _deep] select _selected, _dim] select _closed;

// ------------------------------------------------------------- meta line ---
private _chipH = _rowH * 0.75;
private _chipW = [_root, [_left, _y], _chipH, _entry getOrDefault ["priority", ""]] call FUNC(readerChip);
private _type = ([_entry getOrDefault ["templateId", ""]] call EFUNC(messaging,template)) getOrDefault ["short", ""];
[_root, [_left + _chipW + _pad * 2, _y, _textW * 0.5, _chipH], _type, _label, READER_K_SIZE, true, "left", true] call FUNC(drawText);
[_root, [_left + _textW * 0.6, _y, _textW * 0.4, _chipH], [_entry getOrDefault ["lastActivity", 0]] call FUNC(clock), _label, READER_K_SIZE, true, "right", true] call FUNC(drawText);
_y = _y + _chipH + _padY;

// --------------------------------------------------------------- subject ---
[_root, [_left, _y, _textW, _rowH * 1.05], toUpper (_entry getOrDefault ["subject", ""]), _head, READER_SUBJECT_SIZE, true] call FUNC(drawText);
_y = _y + _rowH * 1.05;

// --------------------------------------------------------------- preview ---
// Off the cached copy when the thread has been fetched: the latest message, by
// whoever said it. The index carries no bodies, so an unfetched thread says what
// kind of report it is instead.
private _said = ((missionNamespace getVariable [QEGVAR(messaging,cache), createHashMap]) getOrDefault [_threadId, []]) param [1, []];
private _preview = if (_said isEqualTo []) then {
    ([_entry getOrDefault ["templateId", ""]] call EFUNC(messaging,template)) getOrDefault ["title", ""]
} else {
    private _last = _said select -1;
    format ["%1 - %2", _last getOrDefault ["fromCallsign", "?"], [_last] call FUNC(readerPreview)]
};
[_root, [_left, _y, _textW, _rowH * 0.9], _preview, _body, READER_PREVIEW_SIZE] call FUNC(drawText);
_y = _y + _rowH * 0.9 + _padY;

// ------------------------------------------------------------ reply meta ---
private _meta = [];
private _replies = _entry getOrDefault ["replies", 0];
_meta pushBack format ["%1 %2", _replies, ["REPLIES", "REPLY"] select (_replies isEqualTo 1)];
if (_unread > 0) then {_meta pushBack format ["%1 UNREAD", _unread]};
if (_closed) then {_meta pushBack "CLOSED"};

private _metaInk = [_label, _accentText] select (_unread > 0 && !_selected && !_closed);
[_root, [_left, _y, _textW, _rowH * 0.8], _meta joinString " - ", _metaInk, READER_K_SIZE, true, "left", true] call FUNC(drawText);

[_root, [_rx, _ry + _rh - RULE_THIN * pixelH, _rw, RULE_THIN * pixelH], _line] call FUNC(drawFill);

// ----------------------------------------------------------------- press ---
private _hit = [_root, [_rx, _ry, _rw, _rh], {
    params ["_ctrl"];
    private _id = _ctrl getVariable [QGVAR(threadId), ""];
    if (_id == "") exitWith {};

    GVAR(readerThread) = _id;

    // A dropdown belongs to the thread it was opened on.
    GVAR(readerMarkers) = false;

    [_id, {{[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame}] call EFUNC(messaging,open);
    {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
}] call FUNC(drawHit);
_hit setVariable [QGVAR(threadId), _threadId];
