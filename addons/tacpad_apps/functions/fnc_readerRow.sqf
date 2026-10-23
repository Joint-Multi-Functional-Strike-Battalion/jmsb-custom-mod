#include "script_component.hpp"
/*
 * Author: JMSB
 * One traffic entry, drawn the way the design draws it:
 *
 *     [FLASH] 9-LINE                                            04:12
 *     MEDEVAC - GRID 043 118
 *     6 REPLIES - 3 UNREAD
 *
 * THE BADGE HUGS ITS WORD. It used to be a filled block 30% of the panel wide
 * with the word floating somewhere inside it, padded with literal spaces in the
 * markup - the single thing that made the reader read as a mock-up of the design
 * rather than the design. The chip is now measured off the glyph advance, so
 * FLASH and ROUTINE are each exactly as wide as they need to be.
 *
 * FLASH is the only filled chip. PRIORITY and ROUTINE are 1px outlines, because
 * the design spends its one loud colour on the thing that has to be answered now
 * and a list where three precedences all shout has no precedence at all.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Row index, in ROW units <NUMBER>
 * 2: Index entry <HASHMAP>
 * 3: Called with [control] when clicked <CODE>
 *
 * Return Value:
 * Rows consumed <NUMBER>
 *
 * Public: No
 */

params [
    ["_body", controlNull, [controlNull]],
    ["_index", 0, [0]],
    ["_entry", createHashMap, [createHashMap]],
    ["_onClick", {}, [{}]]
];

if (isNull _body) exitWith {0};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _scale = EGVAR(tacpad,textScale);
private _rowH = ROW_H * _scale * HOST_H;
private _w = (ctrlPosition _body) # 2;
private _pad = PAD * HOST_W;
private _y = _index * _rowH;

private _rows = 3;
private _h = _rows * _rowH;

private _priority = _entry get "priority";
private _flash = _priority == "high";
// The engine has two precedences, "high" and "normal"; the design draws three.
// Normal is ROUTINE, not PRIORITY - badging every ordinary report PRIORITY is
// how a precedence system stops meaning anything. PRIORITY is left wired for a
// template that asks for it.
private _badge = switch (_priority) do {
    case "high": {"FLASH"};
    case "medium": {"PRIORITY"};
    default {"ROUTINE"};
};

// Uppercase - the engine's states always are; lowercase matched nothing.
private _closed = (_entry get "status") in ["CLOSED", "ABORTED"];
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

// A closed thread is still readable, just not competing for attention.
private _bodyInk = [_ink, [_ink # 0, _ink # 1, _ink # 2, 0.55]] select _closed;

// FLASH takes the accent-100 wash and the 4px accent left border the design
// gives its selected row. Both, not one: the wash finds the row and the border
// says which edge of the list it belongs to.
if (_flash) then {
    [_body, [0, _y, _w, _h], [_accent # 0, _accent # 1, _accent # 2, 0.12]] call EFUNC(tacpad,drawFill);
    [_body, [0, _y, 4 * pixelW, _h], _accent] call EFUNC(tacpad,drawFill);
};

private _left = _pad + ([0, 4 * pixelW] select _flash);

// The chip, measured rather than guessed. The label is tracked, so it is drawn
// as 2n-1 glyphs, and RobotoCondensedBold advances about 0.46 of its height per
// glyph - converted through the pixel scales because the height is in Y units
// and the width it has to become is in X units.
private _chipSize = TEXT_LABEL;
private _chipFontH = TEXT_BASE * pixelH * pixelGrid * HOST_K * _scale * _chipSize;
private _chipTextW = (2 * count (toArray _badge) - 1) * 0.46 * _chipFontH * pixelW / pixelH;
private _chipPad = 3 * pixelW;
private _chipW = _chipTextW + 4 * _chipPad;
private _chipH = _rowH * 0.62;
private _chipY = _y + (_rowH - _chipH) * 0.5;

if (_flash) then {
    [_body, [_left, _chipY, _chipW, _chipH], _accent] call EFUNC(tacpad,drawFill);
} else {
    [_body, [_left, _chipY, _chipW, _chipH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
};

[_body, [_left + 2 * _chipPad, _chipY, _chipW, _chipH], _badge, ([_mute, _ground] select _flash), _chipSize, true, "left", true] call EFUNC(tacpad,drawText);

// The template's short name sits after the chip, and the time hard right.
private _type = ([_entry getOrDefault ["templateId", ""]] call EFUNC(messaging,template)) getOrDefault ["short", ""];
[
    _body,
    [_left + _chipW + 2 * _chipPad, _y, _w * 0.45, _rowH],
    _type,
    ([_mute, _accent] select _flash),
    _chipSize, true, "left", true
] call EFUNC(tacpad,drawText);

[
    _body,
    [_w * 0.5, _y, _w * 0.5 - _pad, _rowH],
    [_entry get "lastActivity"] call EFUNC(tacpad,clock),
    _mute, _chipSize, true, "right"
] call EFUNC(tacpad,drawText);

// The subject carries the weight - it is what the reader is actually for.
[_body, [_left, _y + _rowH * 0.9, _w - _left - _pad, _rowH], _entry get "subject", _bodyInk, TEXT_TITLE, true] call EFUNC(tacpad,drawText);

// The reply meta. The index carries no preview text, so this is the design's
// "6 REPLIES - 3 UNREAD" line rather than an invented first line of the report.
private _unread = _entry get "unread";
private _claimed = _entry get "claimedBy";
private _replies = _entry getOrDefault ["replies", 0];
private _meta = [];
if (_replies > 0) then {_meta pushBack format ["%1 REPLIES", _replies]};
if (_unread > 0) then {_meta pushBack format ["%1 UNREAD", _unread]};
if (_claimed != "") then {_meta pushBack "CLAIMED"};
if (_closed) then {_meta pushBack "CLOSED"};

[
    _body,
    [_left, _y + 2 * _rowH * 0.95, _w - _left - _pad, _rowH],
    _meta joinString " - ",
    ([_mute, _accent] select (_unread > 0)),
    TEXT_LABEL, true, "left", true
] call EFUNC(tacpad,drawText);

// 1px between entries. A row boundary, not a region boundary - the design
// spends 2px only where one part of the screen ends and another begins.
[_body, [0, _y + _h - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

private _hit = [_body, [0, _y, _w, _h], _onClick] call EFUNC(tacpad,drawHit);
_hit setVariable [QGVAR(threadId), _entry get "threadId"];

_rows
