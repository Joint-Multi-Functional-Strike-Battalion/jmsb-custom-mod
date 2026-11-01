#include "script_component.hpp"
/*
 * Author: JMSB
 * A priority chip - FLASH, PRIORITY or ROUTINE - sized to its word, drawn by
 * the one chip primitive (FUNC(drawChip)): FLASH the accent filled, PRIORITY
 * the accent outline, ROUTINE an outline, so the one that matters is the only
 * loud thing on a row (handoff 1a).
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

(switch (_priority) do {
    case "high": {["FLASH", CHIP_ACCENT_FILL]};
    case "medium": {["PRIORITY", CHIP_ACCENT_OUTLINE]};
    default {["ROUTINE", CHIP_OUTLINE]};
}) params ["_label", "_style"];

[_parent, _at, _h, _label, _style, 0, READER_K_SIZE] call FUNC(drawChip)
