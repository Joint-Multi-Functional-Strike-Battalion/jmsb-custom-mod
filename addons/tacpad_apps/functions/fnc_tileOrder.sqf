#include "script_component.hpp"
/*
 * Author: YonV
 * The band's order of tile ids, off the player's layout (FUNC(tileLayout)):
 * a placed tile stands at its position, the AUTO tiles fill the positions
 * nobody placed in the default order given, a placed tile past the last AUTO
 * one follows them, and a tile switched off is not in it. One algorithm for
 * the band (FUNC(tileData)) and for SETTINGS > LIVE TILES, which shows what
 * is at each position (user, 2026-10-30: "auto is annoying, fill in what's
 * there now").
 *
 * Arguments:
 * 0: Tile ids in the default order <ARRAY>
 *
 * Return Value:
 * Tile ids in band order, the off ones dropped <ARRAY>
 *
 * Example:
 * private _order = [["drones", "jam", "pac"]] call jmfsb_tacpad_apps_fnc_tileOrder
 *
 * Public: No
 */

params [["_ids", [], [[]]]];

private _layout = [] call FUNC(tileLayout);
private _placed = createHashMap;
private _auto = [];
{
    private _slot = _layout getOrDefault [_x, TILE_SLOT_AUTO];
    if (_slot isEqualTo TILE_SLOT_OFF) then {continue};
    if (_slot > TILE_SLOT_OFF) then {
        _placed set [_slot, _x];
    } else {
        _auto pushBack _x;
    };
} forEach _ids;

private _out = [];
private _slots = keys _placed;
_slots sort true;
private _last = _slots param [count _slots - 1, 0];
for "_pos" from 1 to _last do {
    private _id = _placed getOrDefault [_pos, ""];
    if (_id isEqualTo "" && {_auto isNotEqualTo []}) then {_id = _auto deleteAt 0};
    if (_id isNotEqualTo "") then {_out pushBack _id};
};

_out + _auto
