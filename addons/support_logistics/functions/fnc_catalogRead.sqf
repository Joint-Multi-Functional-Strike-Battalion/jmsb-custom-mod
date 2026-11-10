#include "script_component.hpp"
/*
 * Author: YonV
 * The items of one JMSB - Logistics Catalog module: every object inside its
 * area or synced to it, read once on the server and kept on the module.
 *
 * WHAT IS AN ITEM (FUNC(catalogEntry)): a vehicle, a crate or another
 * object, empty of people - with its editor inventory and its paint. Units,
 * animals, logics and crewed vehicles are not; a dead or destroyed object is
 * not. Identical objects (same class, inventory and paint) are one item:
 * three of the same crate on the shelf mean "this crate", not three entries.
 *
 * READ ONCE, BY WHOEVER ASKS FIRST - the catalog module's own function at
 * the start, or a logistics module synced to it - and the answer is kept on
 * the module, so several logistics modules share one shelf and the objects
 * can be removed after the first read (the module's Remove The Objects,
 * ticked by default). The catalog is a list; the objects were only how the
 * mission maker wrote it.
 *
 * Arguments:
 * 0: The catalog module <OBJECT>
 *
 * Return Value:
 * Catalog items, see script_component.hpp <ARRAY>
 *
 * Example:
 * [_catalogModule] call jmfsb_support_logistics_fnc_catalogRead
 *
 * Public: No
 */

params [["_cat", objNull, [objNull]]];

if (isNull _cat || {!isServer}) exitWith {[]};

private _done = _cat getVariable QGVAR(items);
if (!isNil "_done") exitWith {_done};

// The area as Eden set it: half-width, half-length, direction, rectangle.
(_cat getVariable ["objectArea", [0, 0, 0, false, -1]]) params [["_a", 0, [0]], ["_b", 0, [0]], ["_dir", 0, [0]], ["_rect", false, [false]]];
private _centre = getPosATL _cat;
private _area = [_centre, _a, _b, _dir, _rect];

private _found = [];
if (_a > 0 && _b > 0) then {
    // The search circle covers the corners of a rectangle; inArea trims it.
    _found = (nearestObjects [_centre, CATALOG_KINDS, sqrt (_a ^ 2 + _b ^ 2), true]) select {_x inArea _area};
};
{_found pushBackUnique _x} forEach (synchronizedObjects _cat);

private _items = [];
private _keys = [];
private _read = [];
{
    private _entry = [_x] call FUNC(catalogEntry);
    if (_entry isEqualTo []) then {continue};
    _read pushBack _x;
    // Identical: the same class, inventory and paint.
    private _key = [_entry select ITEM_CLASS, _entry select ITEM_CARGO, _entry select ITEM_CUSTOM];
    if (_key in _keys) then {continue};
    _keys pushBack _key;
    _items pushBack _entry;
} forEach _found;

_cat setVariable [QGVAR(items), _items];

INFO_3("catalog at %1: %2 items from %3 objects",mapGridPosition _cat,count _items,count _read);
if (_items isEqualTo []) then {
    WARNING_1("catalog at %1 holds nothing - place vehicles, crates or objects inside its area, or sync them to it",mapGridPosition _cat);
};

if ([_cat getVariable ["removeObjects", true]] call EFUNC(support_air,bool)) then {
    {deleteVehicle _x} forEach _read;
};

_items
