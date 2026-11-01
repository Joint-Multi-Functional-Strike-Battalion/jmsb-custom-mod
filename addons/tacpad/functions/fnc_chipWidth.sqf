#include "script_component.hpp"
/*
 * Author: JMSB
 * How wide a chip's word is drawn (FUNC(drawChip)): tracked monospace, so a
 * word of n letters is 2n - 1 glyph advances, plus the air either side. One
 * formula, so a row of chips can be laid out before any is drawn.
 *
 * Arguments:
 * 0: Label <STRING>
 * 1: Label size, as a multiple of the body size <NUMBER> (optional, default TEXT_LABEL)
 *
 * Return Value:
 * Width, screen units <NUMBER>
 *
 * Example:
 * private _w = ["FLASH"] call jmfsb_tacpad_fnc_chipWidth
 *
 * Public: Yes
 */

params [["_label", "", [""]], ["_size", TEXT_LABEL, [0]]];

private _fontH = ([_size * CHIP_SIZE_K] call FUNC(textH)) / 1.25;

(2 * (count _label) - 1) * CHIP_GLYPH * _fontH * pixelW / pixelH + 2 * CHIP_PAD_PX * pixelW
