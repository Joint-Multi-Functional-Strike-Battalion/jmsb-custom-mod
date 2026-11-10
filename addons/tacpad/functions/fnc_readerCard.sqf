#include "script_component.hpp"
/*
 * Author: YonV
 * The submitted template at the head of a thread, as the read-only form it was
 * sent as (handoff 1a): an ink header bar, then the filled lines, off the
 * template's own line definitions - so a template added to the registry
 * renders here for free.
 *
 * ONE COLUMN, LABEL THEN VALUE (user, 2026-11-02: "the 2 column view in the
 * message history is hard to read"). A line report was split into two columns
 * of number / label / value - lines 1-5 down the left, the rest down the right
 * - and read across a rule in the middle. Each filled line is now one
 * key/value row (FUNC(readerKvRows), FUNC(readerKv)): the label in a column as
 * wide as the longest label, the value right after it at the body size, a long
 * answer under its label across the card. Empty optional lines are left out.
 * A grid answer is the critical value and is set bold in the accent.
 *
 * Arguments:
 * 0: Content group <CONTROL>
 * 1: The thread's first message <HASHMAP>
 * 2: [x, y, width] of the card <ARRAY>
 *
 * Return Value:
 * Y under the card; the given y when the message has no template lines <NUMBER>
 *
 * Example:
 * _rowY = [_root, _rootMsg, [_x, _rowY, _w]] call jmfsb_tacpad_fnc_readerCard
 *
 * Public: No
 */

params [["_root", controlNull, [controlNull]], ["_msg", createHashMap, [createHashMap]], ["_at", [0, 0, 0], [[]], 3]];

_at params ["_cx", "_top", "_cardW"];

if (isNull _root) exitWith {_top};

private _template = [_msg getOrDefault ["templateId", ""]] call EFUNC(messaging,template);
if ((_template getOrDefault ["lines", []]) isEqualTo []) exitWith {_top};

([] call FUNC(theme)) params ["_ground", "_ink"];

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _inset = READER_INSET * _pad;

// ------------------------------------------------------------ header bar ---
private _barH = _rowH * 1.2;
[_root, [_cx, _top, _cardW, _barH], _ink] call FUNC(drawFill);
[
    _root, [_cx + _inset, _top, _cardW * 0.6, _barH],
    format ["TEMPLATE - %1", _template getOrDefault ["title", "REPORT"]], _ground, READER_K_SIZE, true, "left", true
] call FUNC(drawText);
[
    _root, [_cx + _cardW * 0.5, _top, _cardW * 0.5 - _inset, _barH],
    format ["%1 - %2", _msg getOrDefault ["fromCallsign", "?"], [_msg getOrDefault ["sentTime", 0]] call FUNC(clock)],
    _ground, READER_K_SIZE, true, "right", true
] call FUNC(drawText);

// ------------------------------------------------------------- the lines ---
private _bodyTop = _top + _barH + READER_INSET * _padY;
private _rows = [_msg, true] call FUNC(readerKvRows);
private _bottom = ([_root, [_cx + _inset, _bodyTop, _cardW - 2 * _inset], _rows] call FUNC(readerKv)) + READER_INSET * _padY;

// The frame last, once the height is known; its foot is the rule between the
// card and the replies under it.
[_root, [_cx, _top, _cardW, _bottom - _top], _ink, RULE_THICK] call FUNC(drawFrame);

_bottom
