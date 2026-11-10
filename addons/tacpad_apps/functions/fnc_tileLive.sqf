#include "script_component.hpp"
/*
 * Author: YonV
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
 * - amber warn, green ok; alert the inverted accent block (review
 * 2026-11-01); rest is ink on the ground, stale the line with dim text. Never
 * text colour alone.
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

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];
private _solid = [_ground # 0, _ground # 1, _ground # 2, 1];

// The ink's quieter steps: dim for stale text, mute for the detail line.
private _dim = [_ink # 0, _ink # 1, _ink # 2, TILE_DIM_ALPHA];
private _mute = [_ink # 0, _ink # 1, _ink # 2, LIVE_MUTE_ALPHA];

// ALERT IS THE INVERTED ACCENT BLOCK (review 2026-11-01, item 2.7; the
// user's R4: "accent block, as the other tiles"), the tile state rule in
// FUNC(tileData)'s header: the accent fills the tile and every word on it is
// the ground, the badge turned over again - ground with the accent word. It was
// a fixed red tint, outline, value and badge; red is a fixed status colour only
// where the theme allows one (squad health, net reach), and the accent is red
// only on some schemes. Amber warn and green ok keep their fixed swatches.
private _stale = _state isEqualTo "stale";
private _alert = _state isEqualTo "alert";
private _tone = switch (_state) do {
    case "alert": {_accent};
    case "warn": {TILE_AMBER};
    case "ok": {TILE_GREEN};
    case "stale": {_line};
    default {_ink};
};
private _live = _state in ["alert", "warn", "ok"];

private _values = [];
if (_live) then {
    _values pushBack ["", [_tone # 0, _tone # 1, _tone # 2, [TILE_TINT_ALPHA, 1] select _alert]];
};
_values pushBack ["", _tone];
_values pushBack [_kicker, switch (true) do {
    case (_alert): {_solid};
    case (_stale): {_dim};
    default {_ink};
}];

// The qualifier a badge, filled with the state's colour and the ground on it,
// the line and ink at rest - and on the alert block, ground with the accent.
if (_qualifier isNotEqualTo "") then {
    _values pushBack ["", switch (true) do {
        case (_alert): {_solid};
        case (_live): {[_tone # 0, _tone # 1, _tone # 2, TILE_BADGE_ALPHA]};
        default {_line};
    }];
    _values pushBack [_qualifier, switch (true) do {
        case (_alert): {_accent};
        case (_live): {_ground};
        case (_stale): {_dim};
        default {_ink};
    }];
};

_values pushBack [_value, switch (true) do {
    case (_alert): {_solid};
    case (_live): {_tone};
    case (_stale): {_dim};
    default {_ink};
}];
_values pushBack [_detail, switch (true) do {
    case (_alert): {_solid};
    case (_stale): {_dim};
    default {_mute};
}];

_values
