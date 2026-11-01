#include "script_component.hpp"
/*
 * Author: JMSB
 * One live tile's changing parts, as values in the order FUNC(panelTiles)
 * draws them (code review R8): the state's tint over the ground (live states
 * only), the outline, the kicker, the qualifier's badge and its word (when
 * there is a qualifier), the value and the detail line. The band is built
 * from these and its refresh writes the next ones into the same controls
 * (EFUNC(tacpad,liveApply)).
 *
 * THE STATE'S COLOUR ALL ROUND THE TILE (user, 2026-10-30, the TAC//APP
 * mockup: "I like the colours around the tiles based on status"): the
 * outline, a tint over the ground, the value and the qualifier's badge in it
 * - red alert, amber warn, green ok; rest is ink on the ground, stale the
 * line with dim text. Never text colour alone.
 *
 * Arguments:
 * 0: Tile, as FUNC(tileData) gives it <ARRAY>
 *
 * Return Value:
 * Values [[text, RGBA], ...] - a fill's text is "" <ARRAY>
 *
 * Example:
 * private _values = [_tile] call jmfsb_tacpad_apps_fnc_tileLive
 *
 * Public: No
 */

params [["_tile", [], [[]]]];

_tile params ["", "_kicker", "_qualifier", "_value", "_detail", ["_state", "rest"]];

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "", "_line"];

// The ink's quieter steps: dim for stale text, mute for the detail line.
private _dim = [_ink # 0, _ink # 1, _ink # 2, TILE_DIM_ALPHA];
private _mute = [_ink # 0, _ink # 1, _ink # 2, LIVE_MUTE_ALPHA];

private _stale = _state isEqualTo "stale";
private _tone = switch (_state) do {
    case "alert": {TILE_RED};
    case "warn": {TILE_AMBER};
    case "ok": {TILE_GREEN};
    case "stale": {_line};
    default {_ink};
};
private _live = _state in ["alert", "warn", "ok"];

private _values = [];
if (_live) then {
    _values pushBack ["", [_tone # 0, _tone # 1, _tone # 2, TILE_TINT_ALPHA]];
};
_values pushBack ["", _tone];
_values pushBack [_kicker, [_ink, _dim] select _stale];

// The qualifier a badge, filled with the state's colour and the ground on it,
// the line and ink at rest.
if (_qualifier isNotEqualTo "") then {
    _values pushBack ["", [_line, [_tone # 0, _tone # 1, _tone # 2, TILE_BADGE_ALPHA]] select _live];
    _values pushBack [_qualifier, [[_ink, _dim] select _stale, _ground] select _live];
};

_values pushBack [_value, switch (true) do {
    case (_live): {_tone};
    case (_stale): {_dim};
    default {_ink};
}];
_values pushBack [_detail, [_mute, _dim] select _stale];

_values
