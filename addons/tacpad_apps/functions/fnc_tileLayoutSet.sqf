#include "script_component.hpp"
/*
 * Author: YonV
 * Sets one tile's place in the player's live-tile layout (FUNC(tileLayout)) and
 * writes it back to his setting, through the suite's setter so it persists and
 * the screen rebuilds.
 *
 * Either steps the tile through AUTO > 1 > ... > the last slot > OFF > AUTO
 * (or back), or - from the SETTINGS > LIVE TILES dropdown - puts it straight
 * at a slot. There are as many slots as tiles (user, 2026-10-30: "increase the
 * slot count with every new app"; FUNC(tileChoices)). A position another tile
 * already holds is handed over: that tile goes back to AUTO, so no two tiles
 * claim one position (user, 2026-10-24: "a drop down to set tile pos 1-10").
 *
 * Arguments:
 * 0: Tile id <STRING>
 * 1: Direction, +1 or -1, when stepping <NUMBER>
 * 2: Slot to set - 1..the number of tiles, TILE_SLOT_OFF or TILE_SLOT_AUTO; nil to step <NUMBER> (optional)
 *
 * Return Value:
 * None
 *
 * Example:
 * ["pac", 0, 2] call jmfsb_tacpad_apps_fnc_tileLayoutSet
 *
 * Public: No
 */

params [["_id", "", [""]], ["_dir", 1, [0]], ["_set", nil, [0]]];

if (_id isEqualTo "") exitWith {};

private _layout = [] call FUNC(tileLayout);

private _next = if (isNil "_set") then {
    // The cycle: AUTO, 1 .. the last slot (one per tile), OFF.
    private _cycle = [TILE_SLOT_AUTO];
    for "_i" from 1 to count ([] call FUNC(tileChoices)) do {_cycle pushBack _i};
    _cycle pushBack TILE_SLOT_OFF;
    private _at = _cycle find (_layout getOrDefault [_id, TILE_SLOT_AUTO]);
    if (_at < 0) then {_at = 0};
    _cycle select ((_at + ([-1, 1] select (_dir >= 0)) + count _cycle) mod count _cycle)
} else {
    _set
};

// One tile per position: whoever held it goes back to AUTO.
if (_next > TILE_SLOT_OFF) then {
    {
        if (_x isNotEqualTo _id && _y isEqualTo _next) then {_layout deleteAt _x};
    } forEach +_layout;
};

if (_next isEqualTo TILE_SLOT_AUTO) then {
    _layout deleteAt _id;
} else {
    _layout set [_id, _next];
};

private _pairs = (keys _layout) apply {
    format ["%1:%2", _x, ["off", str (_layout get _x)] select ((_layout get _x) > TILE_SLOT_OFF)]
};
_pairs sort true;
[QGVAR(tileLayout), _pairs joinString ","] call FUNC(setSetting);
