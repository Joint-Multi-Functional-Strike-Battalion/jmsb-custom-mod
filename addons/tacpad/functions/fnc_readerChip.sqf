#include "script_component.hpp"
/*
 * Author: JMSB
 * A priority chip - FLASH, PRIORITY or ROUTINE - sized to its word. FLASH is
 * the accent filled; the other two are an outline with muted type, so the one
 * that matters is the only loud thing on a row (handoff 1a).
 *
 * Arguments:
 * 0: Parent group <CONTROL>
 * 1: [x, y] of the chip's top-left corner <ARRAY>
 * 2: Chip height <NUMBER>
 * 3: Thread priority as the engine stores it - "high", "medium", anything else <STRING>
 *
 * Return Value:
 * Width drawn <NUMBER>
 *
 * Example:
 * private _w = [_root, [_x, _y], _h, "high"] call jmfsb_tacpad_fnc_readerChip
 *
 * Public: No
 */

params [
    ["_parent", controlNull, [controlNull]],
    ["_at", [0, 0], [[]], 2],
    ["_h", 0, [0]],
    ["_priority", "", [""]]
];

if (isNull _parent) exitWith {0};

_at params ["_x", "_y"];

([] call FUNC(theme)) params ["_ground", "", "_accent"];
private _muted = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);

private _label = switch (_priority) do {
    case "high": {"FLASH"};
    case "medium": {"PRIORITY"};
    default {"ROUTINE"};
};
private _flash = _priority isEqualTo "high";

// Tracked text: every glyph is followed by a space, so a word of n letters is
// 2n - 1 advances wide - the same measure the list used before the restyle.
private _fontH = ([READER_K_SIZE] call FUNC(textH)) / 1.25;
private _w = (2 * count _label - 1) * READER_CHIP_GLYPH * _fontH * pixelW / pixelH + READER_CHIP_PAD_PX * pixelW;

if (_flash) then {
    [_parent, [_x, _y, _w, _h], _accent] call FUNC(drawFill);
} else {
    [_parent, [_x, _y, _w, _h], _dim, RULE_THIN] call FUNC(drawFrame);
};

[
    _parent, [_x, _y, _w, _h], _label,
    [_muted, _ground] select _flash, READER_K_SIZE, true, "center", true
] call FUNC(drawText);

_w
