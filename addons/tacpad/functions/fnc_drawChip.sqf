#include "script_component.hpp"
/*
 * Author: YonV
 * THE CHIP (TAC//APP UI notes, 2026-10-30): one primitive for every small
 * labelled cell in the suite - the priority chips, the reader's net tabs,
 * the compose tags, the RADIO board's ticks - so they cannot drift apart.
 * The word is the monospace, tracked, at CHIP_SIZE_K of the label size;
 * the chip is sized to it unless a width is given. A name or call sign on a
 * chip is drawn untracked (tablet review 2026-11-01, 2.3: tracking is for
 * short labels only, never names).
 *
 * STATE IS THE STYLE, never the text colour alone:
 *   outline        available
 *   accentOutline  raised - PRIORITY
 *   accentFill     loud - FLASH, the selected tab
 *   inkFill        selected, ticked
 *   dim            not available
 *
 * Arguments:
 * 0: Parent group <CONTROL>
 * 1: [x, y] of the chip's top-left corner <ARRAY>
 * 2: Chip height <NUMBER>
 * 3: Label <STRING>
 * 4: Style, one of the CHIP_* styles <STRING> (optional, default CHIP_OUTLINE)
 * 5: Width, 0 to size it to the word <NUMBER> (optional, default 0)
 * 6: Label size, as a multiple of the body size <NUMBER> (optional, default TEXT_LABEL)
 * 7: Tracked - false for a name or call sign <BOOL> (optional, default true)
 *
 * Return Value:
 * Width drawn <NUMBER>
 *
 * Example:
 * private _w = [_body, [_x, _y], _h, "FLASH", "accentFill"] call jmfsb_tacpad_fnc_drawChip
 *
 * Public: Yes
 */

params [
    ["_parent", controlNull, [controlNull]],
    ["_at", [0, 0], [[]], 2],
    ["_h", 0, [0]],
    ["_label", "", [""]],
    ["_style", CHIP_OUTLINE, [""]],
    ["_width", 0, [0]],
    ["_size", TEXT_LABEL, [0]],
    ["_tracked", true, [false]]
];

if (isNull _parent) exitWith {0};

_at params ["_x", "_y"];

([] call FUNC(theme)) params ["_ground", "_ink", "_accent"];
private _dim = ["dim"] call FUNC(theme);

private _w = [_width, [_label, _size, _tracked] call FUNC(chipWidth)] select (_width <= 0);
private _rect = [_x, _y, _w, _h];

private _text = switch (_style) do {
    case CHIP_ACCENT_FILL: {
        [_parent, _rect, _accent] call FUNC(drawFill);
        _ground
    };
    case CHIP_INK_FILL: {
        [_parent, _rect, _ink] call FUNC(drawFill);
        _ground
    };
    case CHIP_ACCENT_OUTLINE: {
        [_parent, _rect, _accent, RULE_THIN] call FUNC(drawFrame);
        _accent
    };
    case CHIP_DIM: {
        [_parent, _rect, _dim, RULE_THIN] call FUNC(drawFrame);
        _dim
    };
    default {
        [_parent, _rect, _ink, RULE_THIN] call FUNC(drawFrame);
        _ink
    };
};

[_parent, _rect, _label, _text, _size * CHIP_SIZE_K, true, "center", _tracked, FONT_MONO] call FUNC(drawText);

_w
