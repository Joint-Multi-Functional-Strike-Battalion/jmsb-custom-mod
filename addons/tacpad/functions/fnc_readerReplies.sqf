#include "script_component.hpp"
/*
 * Author: JMSB
 * The reply spine under a thread's card (handoff 1a): one column hung off a
 * 2 px rule, each reply its author, a tag and the time over its body.
 *
 * THE TAG SAYS WHAT KIND OF REPLY IT WAS. A reply sent as a template (WILCO,
 * ON TASK) carries the template's short name on an accent tag - it moved the
 * thread's state, and that is worth seeing at a glance; a typed reply carries
 * the sender's job on a neutral tag. This player's own replies are tagged YOU,
 * which replaces the left/right split the reader used to make the same point.
 *
 * NEWEST ALWAYS SHOWS. When the spine holds more than the room left above the
 * composer, it is the oldest replies that go, with a line saying how many - a
 * thread is answered at its bottom.
 *
 * Arguments:
 * 0: Content group <CONTROL>
 * 1: The thread's messages, root first <ARRAY>
 * 2: [x, top, width, floor] - the floor is where the composer starts <ARRAY>
 *
 * Return Value:
 * Y under the last reply <NUMBER>
 *
 * Example:
 * [_root, _messages, [_bx, _rowY, _bw, _floor]] call jmfsb_tacpad_fnc_readerReplies
 *
 * Public: No
 */

params [["_root", controlNull, [controlNull]], ["_messages", [], [[]]], ["_at", [0, 0, 0, 0], [[]], 4]];

_at params ["_sx", "_top", "_sw", "_floor"];

if (isNull _root || {count _messages < 2}) exitWith {_top};

([] call FUNC(theme)) params ["", "_ink"];
private _muted = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);
private _surface = ["surface"] call FUNC(theme);
private _tint = ["accentTint"] call FUNC(theme);
private _accentText = ["accentText"] call FUNC(theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _myUid = getPlayerUID player;
private _freeId = "freetext";

// Each reply's lines, worked out once: [message, [[text, isHeader], ...]].
// A typed reply is its words alone; a template reply keeps its line headers,
// muted, over the answers; a template with no fields is its own title.
private _replies = (_messages select [1, count _messages]) apply {
    private _id = _x getOrDefault ["templateId", ""];
    private _body = [_id, _x getOrDefault ["payload", []], false] call EFUNC(messaging,render);
    private _raw = (_body splitString endl) select {trim _x isNotEqualTo ""};
    private _out = [];
    {
        private _isHead = (_forEachIndex mod 2) isEqualTo 0;
        if (!_isHead || _id isNotEqualTo _freeId) then {_out pushBack [_x, _isHead]};
    } forEach _raw;
    if (_out isEqualTo []) then {
        _out = [[([_id] call EFUNC(messaging,template)) getOrDefault ["title", ""], false]];
    };
    [_x, _out]
};

// What fits, counted from the newest - an estimate, one row per line; the
// drawing below still stops at the floor if a long line wraps further.
private _headH = _rowH * 1.1;
private _gap = _padY * 3;
private _room = _floor - _top;
private _first = count _replies;
private _used = 0;
for "_i" from (count _replies - 1) to 0 step -1 do {
    private _need = _headH + count ((_replies # _i) # 1) * _rowH + _gap;
    if (_used + _need > _room && {_first < count _replies}) exitWith {};
    _used = _used + _need;
    _first = _i;
};

private _x0 = _sx + RULE_THICK * pixelW + _pad * 4;
private _w0 = _sw - (_x0 - _sx);
private _rowY = _top;

if (_first > 0) then {
    [_root, [_x0, _rowY, _w0, _rowH * 0.8], format ["%1 EARLIER REPLIES - OPEN THE NET VIEW FOR ALL", _first], _dim, READER_K_SIZE, true, "left", true] call FUNC(drawText);
    _rowY = _rowY + _rowH;
};

private _tagFont = ([READER_K_SIZE] call FUNC(textH)) / 1.25;
private _authorFont = ([READER_AUTHOR_SIZE] call FUNC(textH)) / 1.25;

{
    if (_forEachIndex < _first) then {continue};
    if (_rowY + _headH > _floor) exitWith {};
    _x params ["_msg", "_lines"];

    private _id = _msg getOrDefault ["templateId", ""];
    private _mine = (_msg getOrDefault ["fromUid", ""]) isEqualTo _myUid;
    private _author = toUpper (_msg getOrDefault ["fromCallsign", "?"]);

    // --- author, tag, time ---------------------------------------------------
    private _authorW = (count _author) * CARD_GLYPH_W * _authorFont * pixelW / pixelH + _pad * 2;
    [_root, [_x0, _rowY, _authorW, _headH], _author, _ink, READER_AUTHOR_SIZE, true] call FUNC(drawText);

    private _accentTag = _id isNotEqualTo _freeId && _id isNotEqualTo "";
    private _tag = switch (true) do {
        case (_mine): {"YOU"};
        case (_accentTag): {toUpper (([_id] call EFUNC(messaging,template)) getOrDefault ["short", _id])};
        default {_msg getOrDefault ["fromRole", ""]};
    };
    private _tx = _x0 + _authorW + _pad * 2;
    if (_tag isNotEqualTo "") then {
        private _tagW = (2 * count _tag - 1) * READER_CHIP_GLYPH * _tagFont * pixelW / pixelH + READER_CHIP_PAD_PX * pixelW;
        private _tagH = _headH * 0.75;
        private _tagY = _rowY + (_headH - _tagH) * 0.5;
        [_root, [_tx, _tagY, _tagW, _tagH], [_surface, _tint] select _accentTag] call FUNC(drawFill);
        [_root, [_tx, _tagY, _tagW, _tagH], _tag, [_muted, _accentText] select _accentTag, READER_K_SIZE, true, "center", true] call FUNC(drawText);
        _tx = _tx + _tagW + _pad * 2;
    };
    [_root, [_tx, _rowY, _w0 * 0.3, _headH], [_msg getOrDefault ["sentTime", 0]] call FUNC(clock), _muted, READER_K_SIZE, true, "left", true] call FUNC(drawText);
    _rowY = _rowY + _headH;

    // --- body ----------------------------------------------------------------
    {
        _x params ["_text", "_isHead"];
        if (_rowY + _rowH * 0.7 > _floor) exitWith {};
        private _ctrl = [
            _root, [_x0, _rowY, _w0, _rowH],
            _text, [_ink, _muted] select _isHead, [READER_BODY_SIZE, READER_K_SIZE] select _isHead, _isHead, "left", _isHead
        ] call FUNC(drawText);
        private _lineH = ([_rowH, _rowH * 0.8] select _isHead) max ((ctrlTextHeight _ctrl) + _rowH * 0.1);
        (ctrlPosition _ctrl) params ["_lx", "_ly", "_lw"];
        _ctrl ctrlSetPosition [_lx, _ly, _lw, _lineH];
        _ctrl ctrlCommit 0;
        _rowY = _rowY + _lineH;
    } forEach _lines;

    _rowY = _rowY + _gap;
} forEach _replies;

// The spine: a 2 px rule down the left of everything drawn.
if (_rowY - _gap > _top) then {
    [_root, [_sx, _top, RULE_THICK * pixelW, (_rowY - _gap) - _top], _dim] call FUNC(drawFill);
};

_rowY
