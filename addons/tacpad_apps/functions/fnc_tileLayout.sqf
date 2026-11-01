#include "script_component.hpp"
/*
 * Author: JMSB
 * The player's live-tile layout, off his own setting (QGVAR(tileLayout)):
 * "drones:1,jam:off,pac:2" - a tile id to its slot number, or off. A tile
 * with no entry is AUTO: shown, in the default order after the placed ones
 * (FUNC(tileData)). Written by FUNC(tileLayoutSet) from SETTINGS > LIVE TILES.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Tile id -> slot (1..), TILE_SLOT_OFF for off; absent = AUTO <HASHMAP>
 *
 * Example:
 * private _layout = [] call jmfsb_tacpad_apps_fnc_tileLayout
 *
 * Public: No
 */

private _layout = createHashMap;
private _text = missionNamespace getVariable [QGVAR(tileLayout), ""];
if !(_text isEqualType "") exitWith {_layout};

{
    private _pair = (_x splitString ":") apply {toLower trim _x};
    if (count _pair < 2) then {continue};
    _pair params ["_id", "_slot"];
    if (_id isEqualTo "") then {continue};
    if (_slot isEqualTo "off") then {
        _layout set [_id, TILE_SLOT_OFF];
    } else {
        private _n = parseNumber _slot;
        if (_n >= 1) then {_layout set [_id, round _n]};
    };
} forEach (_text splitString ",");

_layout
