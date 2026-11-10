#include "script_component.hpp"
/*
 * Author: YonV
 * Counts patrol-base kits near a position: loose kit items sitting in ground
 * weapon holders PLUS deployed kit objects (both count toward building).
 *
 * Arguments:
 * 0: Centre position ATL <ARRAY> (default: player position)
 *
 * Return Value:
 * Kit count within range <NUMBER>
 *
 * Example:
 * [getPosATL player] call jmfsb_patrol_base_fnc_countKits
 *
 * Public: No
 */

params [["_pos", getPosATL player, [[]]]];

private _range = missionNamespace getVariable [QGVAR(kitRange), 5];
private _kitItems = KIT_ITEMS;
private _count = 0;

// Loose kit items dropped on the ground (they live in weapon holders)...
{
    private _cargo = itemCargo _x;
    _count = _count + ({_x in _kitItems} count _cargo);
} forEach (nearestObjects [_pos, ["WeaponHolderSimulated", "GroundWeaponHolder", "WeaponHolder"], _range]);

// ...plus deployed kit objects (Zeus drops / recovered kits), one each.
_count = _count + count (nearestObjects [_pos, KIT_OBJECTS, _range]);

_count
