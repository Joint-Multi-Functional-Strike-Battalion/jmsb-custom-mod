#include "script_component.hpp"
/*
 * Author: YonV
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
private _line = ["line"] call FUNC(theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _myUid = getPlayerUID player;
private _freeId = "freetext";

// Each reply's lines, worked out once: [message, [[text, isHeader, asks], ...],
// key/value rows]. A typed reply is its words alone; a template reply is its
// filled lines as key/value rows (below); a template with nothing filled is
// its own title.
//
// WHAT THE ASSET ASKS READS FIRST (docs/DESIGN_SUPPORT_MESSAGING.md 7, user
// 2026-11-01): a `prompt` card is its question alone, at the title size on
// the accent - its answers are the quick-reply tiles under the thread
// (FUNC(readerQuickTiles)), not a line of card ids here.
private _askKey = ([QUICK_PROMPT, QUICK_PROMPT_TEXT] call EFUNC(messaging,fieldKeys)) param [0, ""];
private _replies = (_messages select [1, count _messages]) apply {
    private _id = _x getOrDefault ["templateId", ""];
    private _asked = "";
    if (_id isEqualTo QUICK_PROMPT && _askKey isNotEqualTo "") then {
        _asked = (createHashMapFromArray (_x getOrDefault ["payload", []])) getOrDefault [_askKey, ""];
    };
    if !(_asked isEqualType "") then {_asked = ""};
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
    if (trim _asked isNotEqualTo "") then {
        _out = [[toUpper (trim _asked), false, true]];
    };
    // A FILED CARD IS ONE KEY/VALUE COLUMN (user, 2026-11-02: "the 2 column
    // view in the message history is hard to read"), as the thread's own card
    // is - FUNC(readerKv) - not its line headers over their answers. A typed
    // reply and the asset's question stay as they were.
    private _kv = [];
    if (_id isNotEqualTo _freeId && trim _asked isEqualTo "") then {_kv = [_x, false] call FUNC(readerKvRows)};
    if (_kv isNotEqualTo []) then {_out = []};
    [_x, _out, _kv]
};

// What fits, counted from the newest - an estimate, one row per line; the
// drawing below still stops at the floor if a long line wraps further.
private _headH = _rowH * 1.1;
private _gap = _padY * 3;
private _room = _floor - _top;
private _first = count _replies;
private _used = 0;
for "_i" from (count _replies - 1) to 0 step -1 do {
    private _need = _headH + (count ((_replies # _i) # 1) + count ((_replies # _i) # 2)) * _rowH + _gap;
    if (_used + _need > _room && {_first < count _replies}) exitWith {};
    _used = _used + _need;
    _first = _i;
};

private _x0 = _sx + RULE_THICK * pixelW + _pad * 4;
private _w0 = _sw - (_x0 - _sx);
private _rowY = _top;

if (_first > 0) then {
    // Singular at one (tablet review 2026-11-01, 2.7).
    [_root, [_x0, _rowY, _w0, _rowH * 0.8], format ["%1 EARLIER %2 - OPEN THE NET VIEW FOR ALL", _first, ["REPLIES", "REPLY"] select (_first isEqualTo 1)], _dim, READER_K_SIZE, true, "left", true] call FUNC(drawText);
    _rowY = _rowY + _rowH;
};

{
    if (_forEachIndex < _first) then {continue};
    if (_rowY + _headH > _floor) exitWith {};
    _x params ["_msg", "_lines", "_kv"];
    private _last = _forEachIndex isEqualTo (count _replies - 1);

    private _id = _msg getOrDefault ["templateId", ""];
    private _author = toUpper (_msg getOrDefault ["fromCallsign", "?"]);
    // YOURS BY UID AND NAME (user, 2026-11-06 screenshot: every BOXCAR reply
    // tagged YOU). A support asset's answers are filed under the issuer's uid
    // with the asset's call sign (jmfsb_support_fnc_srvFileAs), so the uid
    // alone made the asset's words read as his.
    private _mine = (_msg getOrDefault ["fromUid", ""]) isEqualTo _myUid
        && {_author isEqualTo toUpper format ["%1 %2", groupId group player, name player]};

    // --- author, tag, time ---------------------------------------------------
    // MEASURED, NOT GUESSED (user, 2026-11-06: "i can not read them"): the
    // name's width came from its letter count, so a long one ran under the
    // tag, and the tag's from a tracked glyph estimate that cut YOU to Y O.
    // Each is drawn, then sized to the width the engine gives its text.
    private _authorCtrl = [_root, [_x0, _rowY, _w0 * 0.6, _headH], _author, _ink, READER_AUTHOR_SIZE, true] call FUNC(drawText);
    private _authorW = (ctrlTextWidth _authorCtrl) + _pad * 2;
    _authorCtrl ctrlSetPosition [_x0, _rowY, _authorW, _headH];
    _authorCtrl ctrlCommit 0;

    private _accentTag = _id isNotEqualTo _freeId && _id isNotEqualTo "";
    private _tag = switch (true) do {
        case (_mine): {"YOU"};
        case (_accentTag): {toUpper (([_id] call EFUNC(messaging,template)) getOrDefault ["short", _id])};
        default {_msg getOrDefault ["fromRole", ""]};
    };
    private _tx = _x0 + _authorW + _pad * 2;
    if (_tag isNotEqualTo "") then {
        private _tagH = _headH * 0.75;
        private _tagY = _rowY + (_headH - _tagH) * 0.5;
        // The fill first so the word draws over it; both resized once the
        // word is measured.
        private _fill = [_root, [_tx, _tagY, _w0 * 0.3, _tagH], [_surface, _tint] select _accentTag] call FUNC(drawFill);
        private _word = [_root, [_tx, _tagY, _w0 * 0.3, _tagH], _tag, [_muted, _accentText] select _accentTag, READER_K_SIZE, true, "center", true] call FUNC(drawText);
        private _tagW = (ctrlTextWidth _word) + READER_CHIP_PAD_PX * pixelW;
        {
            _x ctrlSetPosition [_tx, _tagY, _tagW, _tagH];
            _x ctrlCommit 0;
        } forEach [_fill, _word];
        _tx = _tx + _tagW + _pad * 2;
    };
    // The time is a value: untracked (tablet review 2026-11-01, 2.3).
    [_root, [_tx, _rowY, _w0 * 0.3, _headH], [_msg getOrDefault ["sentTime", 0]] call FUNC(clock), _muted, READER_K_SIZE, true] call FUNC(drawText);
    _rowY = _rowY + _headH;

    // --- body ----------------------------------------------------------------
    {
        _x params ["_text", "_isHead", ["_asks", false]];
        if (_rowY + _rowH * 0.7 > _floor) exitWith {};
        private _ctrl = if (_asks) then {
            [_root, [_x0, _rowY, _w0, _rowH], _text, _accentText, READER_TITLE_SIZE, true] call FUNC(drawText)
        } else {
            [
                _root, [_x0, _rowY, _w0, _rowH],
                _text, [_ink, _muted] select _isHead, [READER_BODY_SIZE, READER_K_SIZE] select _isHead, _isHead, "left", _isHead
            ] call FUNC(drawText)
        };
        private _lineH = ([_rowH, _rowH * 0.8] select _isHead) max ((ctrlTextHeight _ctrl) + _rowH * 0.1);
        (ctrlPosition _ctrl) params ["_lx", "_ly", "_lw"];
        _ctrl ctrlSetPosition [_lx, _ly, _lw, _lineH];
        _ctrl ctrlCommit 0;
        _rowY = _rowY + _lineH;
    } forEach _lines;

    // A filed card's rows, and a thin rule between it and the next message.
    if (_kv isNotEqualTo []) then {
        _rowY = [_root, [_x0, _rowY, _w0], _kv, _floor] call FUNC(readerKv);
        if (!_last) then {
            [_root, [_x0, _rowY + _gap * 0.5, _w0, RULE_THIN * pixelH], _line] call FUNC(drawFill);
        };
    };

    _rowY = _rowY + _gap;
} forEach _replies;

// The spine: a 2 px rule down the left of everything drawn.
if (_rowY - _gap > _top) then {
    [_root, [_sx, _top, RULE_THICK * pixelW, (_rowY - _gap) - _top], _dim] call FUNC(drawFill);
};

_rowY
