#include "script_component.hpp"
/*
 * Author: JMSB
 * Every tile SETTINGS > LIVE TILES can place or switch off: the declared
 * TILE_CHOICES in their order, then the tiles the providers answer for this
 * player (jmfsb_devices' VEHICLE, the medic's, Point Man's, the jumpmaster's)
 * that the list does not already name. A provider's tile that cannot be
 * placed or switched off was a gap (notes, 2026-10-30).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[tile id, name], ...] <ARRAY>
 *
 * Example:
 * private _choices = [] call jmfsb_tacpad_apps_fnc_tileChoices
 *
 * Public: No
 */

private _out = +TILE_CHOICES;
{
    private _tiles = [] call _y;
    if (isNil "_tiles" || {!(_tiles isEqualType [])}) then {continue};
    {
        if !(_x isEqualType [] && {count _x > 1}) then {continue};
        private _id = _x select 0;
        private _name = _x select 1;
        if !(_id isEqualType "" && _name isEqualType "") then {continue};
        if ((_out findIf {(_x select 0) isEqualTo _id}) < 0) then {_out pushBack [_id, toUpper _name]};
    } forEach _tiles;
} forEach (missionNamespace getVariable [QGVAR(tileProviders), createHashMap]);

_out
