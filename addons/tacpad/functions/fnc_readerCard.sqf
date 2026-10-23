#include "script_component.hpp"
/*
 * Author: JMSB
 * The submitted template at the head of a thread, as the read-only form it was
 * sent as (handoff 1a): an ink header bar, then number / label / value rows,
 * off the template's own line definitions - so a template added to the
 * registry renders here for free.
 *
 * TWO COLUMNS WHEN IT IS A LINE REPORT, ONE WHEN IT IS PROSE. A 9-line reads
 * as two columns of short answers - lines 1-5 down the left, the rest down the
 * right, each column top to bottom. An OPORD section is paragraphs, and split
 * in half it would be two columns of three words a line; a card with any
 * answer longer than READER_CARD_SPLIT_CHARS stays one column.
 *
 * A LINE IS AS TALL AS ITS ANSWER - drawn, measured, grown - so a long answer
 * never runs over the row under it. A grid answer is the critical value and is
 * set bold in the body-size accent.
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
private _lines = _template getOrDefault ["lines", []];
if (_lines isEqualTo []) exitWith {_top};

([] call FUNC(theme)) params ["_ground", "_ink"];
private _muted = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);
private _accentText = ["accentText"] call FUNC(theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * GVAR(textScale) * GVAR(uiScale) * HOST_H;
private _payload = createHashMapFromArray (_msg getOrDefault ["payload", []]);

// ------------------------------------------------------------ the answers ---
// [number, label, value, critical] per line, worked out before anything is
// drawn - the column split depends on how long the answers are.
private _rows = [];
{
    _x params ["", "", ["_lineLabel", ""], ["_fields", []]];

    private _parts = [];
    private _critical = false;
    {
        private _v = _payload getOrDefault [_x getOrDefault ["key", ""], ""];
        if (_v isEqualTo "" || _v isEqualTo false) then {continue};

        if ((_x getOrDefault ["type", ""]) isEqualTo "grid") then {
            _critical = true;
            if (_v isEqualType [] && {count _v >= 2}) then {_v = mapGridPosition _v};
        };

        private _prefix = _x getOrDefault ["prefix", ""];
        if (_v isEqualTo true) then {
            _parts pushBack ([_prefix, _x getOrDefault ["hint", ""]] select (_prefix == ""));
        } else {
            _parts pushBack format ["%1%2", _prefix, _v];
        };
    } forEach _fields;

    // The label usually carries its own number ("1. SITUATION"); the number
    // column is only filled where it does not.
    private _number = ["", str (_forEachIndex + 1)] select !((_lineLabel select [0, 1]) in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]);
    _rows pushBack [_number, _lineLabel, [_parts joinString " - ", "-"] select (_parts isEqualTo []), _critical && {_parts isNotEqualTo []}];
} forEach _lines;

private _split = count _rows >= READER_CARD_SPLIT_MIN
    && {(_rows findIf {count (_x # 2) > READER_CARD_SPLIT_CHARS}) < 0};

// ------------------------------------------------------------ header bar ---
private _barH = _rowH * 1.2;
[_root, [_cx, _top, _cardW, _barH], _ink] call FUNC(drawFill);
[
    _root, [_cx + _pad * 3, _top, _cardW * 0.6, _barH],
    format ["TEMPLATE - %1", _template getOrDefault ["title", "REPORT"]], _ground, READER_K_SIZE, true, "left", true
] call FUNC(drawText);
[
    _root, [_cx + _cardW * 0.5, _top, _cardW * 0.5 - _pad * 3, _barH],
    format ["%1 - %2", _msg getOrDefault ["fromCallsign", "?"], [_msg getOrDefault ["sentTime", 0]] call FUNC(clock)],
    _ground, READER_K_SIZE, true, "right", true
] call FUNC(drawText);

// --------------------------------------------------------------- columns ---
private _bodyTop = _top + _barH + _padY;
private _colW = [_cardW, (_cardW - RULE_THICK * pixelW) / 2] select _split;
private _leftCount = [count _rows, ceil ((count _rows) / 2)] select _split;

private _fnc_column = {
    params ["_colX", "_slice"];
    private _rowY = _bodyTop;
    private _numW = [0, _colW * READER_CARD_NUM_W] select ((_slice findIf {(_x # 0) isNotEqualTo ""}) >= 0);
    private _labelW = _colW * READER_CARD_LABEL_W;
    private _valueX = _colX + _pad * 3 + _numW + _labelW;
    private _valueW = _colX + _colW - _valueX - _pad * 3;
    {
        _x params ["_number", "_label", "_value", "_critical"];
        if (_number isNotEqualTo "") then {
            [_root, [_colX + _pad * 3, _rowY, _numW, _rowH], _number, _muted, READER_K_SIZE, true, "left", true] call FUNC(drawText);
        };
        [_root, [_colX + _pad * 3 + _numW, _rowY, _labelW - _pad, _rowH], _label, _muted, READER_K_SIZE, true, "left", true] call FUNC(drawText);

        private _ctrl = [
            _root, [_valueX, _rowY, _valueW, _rowH], _value,
            [[_ink, _accentText] select _critical, _dim] select (_value isEqualTo "-"), READER_BODY_SIZE, _critical
        ] call FUNC(drawText);
        private _lineH = _rowH max ((ctrlTextHeight _ctrl) + _rowH * 0.25);
        _ctrl ctrlSetPosition [_valueX, _rowY, _valueW, _lineH];
        _ctrl ctrlCommit 0;
        _rowY = _rowY + _lineH + _padY;
    } forEach _slice;
    _rowY
};

private _bottom = [_cx, _rows select [0, _leftCount]] call _fnc_column;
if (_split) then {
    _bottom = _bottom max ([_cx + _colW + RULE_THICK * pixelW, _rows select [_leftCount, count _rows]] call _fnc_column);
    [_root, [_cx + _colW, _top + _barH, RULE_THICK * pixelW, _bottom - _top - _barH], _ink] call FUNC(drawFill);
};

// The frame last, once the height is known.
[_root, [_cx, _top, _cardW, _bottom - _top], _ink, RULE_THICK] call FUNC(drawFrame);

_bottom
