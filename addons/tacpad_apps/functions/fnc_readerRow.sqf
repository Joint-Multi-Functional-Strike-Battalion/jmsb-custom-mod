#include "script_component.hpp"
/*
 * Author: YonV
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
 * ON THE PANEL'S OWN ROW RHYTHM (user, 2026-11-01: the docked reader was "kind
 * of squished"). The entry measured its rows off ROW_H while the panel counts
 * in ROW_H_SCREEN, so entries started above the rule under the net chips and
 * three lines were packed into rows shorter than their type. One row is
 * ROW_H_SCREEN here too, with a pad of air above and below the three lines;
 * the time and the reply meta are values, untracked, at the body size (R1).
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Row index, in ROW_H_SCREEN units <NUMBER>
 * 2: Index entry <HASHMAP>
 * 3: Called with [control] when clicked <CODE>
 *
 * Return Value:
 * Rows consumed, in ROW_H_SCREEN units <NUMBER>
 *
 * Public: No
 */

// The entry's lines: meta, subject, reply meta.
#define ENTRY_LINES 3

params [
    ["_body", controlNull, [controlNull]],
    ["_index", 0, [0]],
    ["_entry", createHashMap, [createHashMap]],
    ["_onClick", {}, [{}]]
];

if (isNull _body) exitWith {0};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _rowH = ROW_H_SCREEN;
private _w = (ctrlPosition _body) # 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _top = _index * _rowH;
// The first line starts a pad down; the entry ends a pad under the last.
private _y = _top + _padY;

private _h = ENTRY_LINES * _rowH + 2 * _padY;

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
    [_body, [0, _top, _w, _h], [_accent # 0, _accent # 1, _accent # 2, 0.12]] call EFUNC(tacpad,drawFill);
    [_body, [0, _top, 4 * pixelW, _h], _accent] call EFUNC(tacpad,drawFill);
};

private _left = _pad * 2 + ([0, 4 * pixelW] select _flash);

// The chip is the chip primitive's (FUNC(drawChip)), measured off its own
// word: a precedence is a short label, so it stays tracked.
private _chipH = _rowH * CHIP_H_K;
private _chipY = _y + (_rowH - _chipH) * 0.5;
private _chipW = [_body, [_left, _chipY], _chipH, _badge, [CHIP_OUTLINE, CHIP_ACCENT_FILL] select _flash] call EFUNC(tacpad,drawChip);

// The template's short name sits after the chip, and the time hard right.
private _type = ([_entry getOrDefault ["templateId", ""]] call EFUNC(messaging,template)) getOrDefault ["short", ""];
[
    _body,
    [_left + _chipW + _pad * 2, _y, _w * 0.45, _rowH],
    _type,
    ([_mute, _accent] select _flash),
    TEXT_LABEL, true, "left", true
] call EFUNC(tacpad,drawText);

// The time is a value: untracked, at the body size (review 2026-11-01, R1).
[
    _body,
    [_w * 0.5, _y, _w * 0.5 - _pad * 2, _rowH],
    [_entry get "lastActivity"] call EFUNC(tacpad,clock),
    _mute, TEXT_BODY, true, "right", false, FONT_MONO
] call EFUNC(tacpad,drawText);

// The subject carries the weight - it is what the reader is actually for.
[_body, [_left, _y + _rowH, _w - _left - _pad * 2, _rowH], _entry get "subject", _bodyInk, TEXT_TITLE, true] call EFUNC(tacpad,drawText);

// The reply meta. The index carries no preview text, so this is the design's
// "6 REPLIES - 3 UNREAD" line rather than an invented first line of the report.
private _unread = _entry get "unread";
private _claimed = _entry get "claimedBy";
private _replies = _entry getOrDefault ["replies", 0];
private _meta = [];
// Plural only when the count is not one (review 2026-11-01, item 2.7).
if (_replies > 0) then {_meta pushBack format ["%1 %2", _replies, ["REPLIES", "REPLY"] select (_replies isEqualTo 1)]};
if (_unread > 0) then {_meta pushBack format ["%1 UNREAD", _unread]};
if (_claimed != "") then {_meta pushBack "CLAIMED"};
if (_closed) then {_meta pushBack "CLOSED"};

// Counts are values: untracked, at the body size (review 2026-11-01, R1).
[
    _body,
    [_left, _y + 2 * _rowH, _w - _left - _pad * 2, _rowH],
    _meta joinString " - ",
    ([_mute, _accent] select (_unread > 0)),
    TEXT_BODY, true
] call EFUNC(tacpad,drawText);

// 1px between entries. A row boundary, not a region boundary - the design
// spends 2px only where one part of the screen ends and another begins.
[_body, [0, _top + _h - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

private _hit = [_body, [0, _top, _w, _h], _onClick] call EFUNC(tacpad,drawHit);
_hit setVariable [QGVAR(threadId), _entry get "threadId"];

_h / _rowH
