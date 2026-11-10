#include "script_component.hpp"
/*
 * Author: YonV
 * One object of a reference area as a catalog item (shape in
 * script_component.hpp), or [] when it is not an item.
 *
 * THE EDITOR INVENTORY IS KEPT AS IT WAS PLACED: the weapons, magazines,
 * items and backpacks in its cargo when the mission starts - which is what
 * Eden's Equipment Storage put there, or the class's own load when nobody
 * touched it. A delivery is cleared and refilled with exactly that
 * (FUNC(spawnItem)), so an emptied box arrives empty and a stocked one
 * arrives stocked. Weapons are kept by class (their attachments are not);
 * what is inside a backpack in the cargo is not.
 *
 * A VEHICLE KEEPS ITS PAINT AND PARTS (BIS_fnc_getVehicleCustomization),
 * put back with BIS_fnc_initVehicle on delivery.
 *
 * Arguments:
 * 0: The object <OBJECT>
 *
 * Return Value:
 * The item, [] when it is none <ARRAY>
 *
 * Example:
 * [_obj] call jmfsb_support_logistics_fnc_catalogEntry
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]]];

if (isNull _obj || {!alive _obj}) exitWith {[]};
if ((CATALOG_NEVER findIf {_obj isKindOf _x}) > -1) exitWith {[]};
if ((CATALOG_KINDS findIf {_obj isKindOf _x}) < 0) exitWith {[]};
if ((crew _obj) isNotEqualTo []) exitWith {
    WARNING_1("catalog: '%1' has people in it - not an item (place it empty)",typeOf _obj);
    []
};

private _cls = typeOf _obj;
private _vehicle = _obj isKindOf "AllVehicles";
private _custom = if (_vehicle) then {_obj call BIS_fnc_getVehicleCustomization} else {[]};

[
    toUpper getText (configOf _obj >> "displayName"),
    [ITEM_OBJECT, ITEM_VEHICLE] select _vehicle,
    _cls,
    [getWeaponCargo _obj, getMagazineCargo _obj, getItemCargo _obj, getBackpackCargo _obj],
    _custom,
    getMass _obj,
    (getArray (configOf _obj >> "slingLoadCargoMemoryPoints")) isNotEqualTo [],
    ""
]
