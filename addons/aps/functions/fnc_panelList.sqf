#include "script_component.hpp"
/*
 * Author: YonV
 * The vehicles the map panel shows, in the order it shows them: the one the
 * player is in first, then the rest by distance. WHICH VEHICLES is the APS
 * Panel Scope setting - own vehicle only, every vehicle the player's group is
 * crewing, or every crewed vehicle on the side. A vehicle that carries nothing
 * is never listed; there is nothing on it to switch.
 *
 * Arguments: None
 *
 * Return Value:
 * Vehicles, at most APS_PANEL_MAX <ARRAY>
 *
 * Example:
 * call jmfsb_aps_fnc_panelList
 *
 * Public: No
 */

if (!hasInterface) exitWith { [] };
if !(missionNamespace getVariable [QGVAR(enabled), true]) exitWith { [] };

private _mine = vehicle player;
private _grp = group player;
private _side = side _grp;
private _scope = missionNamespace getVariable [QGVAR(panelScope), 1];

private _own = [];
private _rest = [];
{
    private _veh = _x;
    if (!alive _veh) then { continue };
    if ((_veh getVariable [QGVAR(fit), FIT_NONE]) isEqualTo FIT_NONE && {!(_veh getVariable [QGVAR(rf), false])}) then { continue };

    if (_veh == _mine) then { _own pushBack _veh; continue };
    private _ok = false;
    if (_scope >= 1) then { _ok = (crew _veh) findIf { group _x == _grp } > -1 };
    if (!_ok && _scope >= 2) then { _ok = (crew _veh) isNotEqualTo [] && {side _veh == _side} };
    if (_ok) then { _rest pushBack _veh };
} forEach vehicles;

// by distance - sorted as [distance, index] pairs, because an array holding
// objects cannot be sorted directly
private _order = [];
{ _order pushBack [player distance _x, _forEachIndex] } forEach _rest;
_order sort true;
_rest = _order apply { _rest select (_x select 1) };

(_own + _rest) select [0, APS_PANEL_MAX]
