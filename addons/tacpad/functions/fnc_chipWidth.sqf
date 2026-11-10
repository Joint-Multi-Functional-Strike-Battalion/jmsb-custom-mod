#include "script_component.hpp"
/*
 * Author: YonV
 * How wide a chip's word is drawn (FUNC(drawChip)): monospace, so a tracked
 * word of n letters is 2n - 1 glyph advances and an untracked one n, plus the
 * air either side. One formula, so a row of chips can be laid out before any
 * is drawn. A word longer than TRACK_MAX_CHARS is never tracked (FUNC(retext))
 * and is measured that way (tablet review 2026-11-01, 2.3).
 *
 * Arguments:
 * 0: Label <STRING>
 * 1: Label size, as a multiple of the body size <NUMBER> (optional, default TEXT_LABEL)
 * 2: Tracked <BOOL> (optional, default true)
 *
 * Return Value:
 * Width, screen units <NUMBER>
 *
 * Example:
 * private _w = ["FLASH"] call jmfsb_tacpad_fnc_chipWidth
 *
 * Public: Yes
 */

params [["_label", "", [""]], ["_size", TEXT_LABEL, [0]], ["_tracked", true, [false]]];

private _fontH = ([_size * CHIP_SIZE_K] call FUNC(textH)) / 1.25;
private _n = count _label;
private _glyphs = _n;
if (_tracked) then {
    if (_n <= TRACK_MAX_CHARS) then {_glyphs = 2 * _n - 1};
};

_glyphs * CHIP_GLYPH * _fontH * pixelW / pixelH + 2 * CHIP_PAD_PX * pixelW
