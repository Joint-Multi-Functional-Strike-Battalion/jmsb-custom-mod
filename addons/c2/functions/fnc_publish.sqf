#include "script_component.hpp"
/*
 * Author: YonV
 * Sends the measures to every client as GVAR(measureList), oldest first.
 * Server only.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_c2_fnc_publish
 *
 * Public: No
 */

if (!isServer) exitWith {};
private _list = values GVAR(measures);
private _keys = _list apply {[_x # 8, _x # 0]};
{_x pushBack _forEachIndex} forEach _keys;
_keys sort true;
GVAR(measureList) = _keys apply {_list select (_x # 2)};
publicVariable QGVAR(measureList);
