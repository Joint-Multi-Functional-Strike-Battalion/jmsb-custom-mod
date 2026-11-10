#include "script_component.hpp"
/*
 * Author: YonV
 * Makes one catalog item for a delivery, empty of people:
 *
 *   PAC crate    the module's crate class, packed from its arsenal lists
 *                (FUNC(fillCrate))
 *   reference    its class, cleared and refilled with exactly the editor
 *                inventory read off the reference (FUNC(catalogEntry)), and
 *                a vehicle repainted and re-fitted as it was placed
 *
 * A delivered vehicle is the players' now: ALiVE is told to leave it alone
 * (through the adapter), so it is not virtualised out from under them.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The catalog item <ARRAY>
 * 2: Where, ATL <ARRAY>
 * 3: Direction <NUMBER> (optional, default 0)
 *
 * Return Value:
 * The object, objNull when it could not be made <OBJECT>
 *
 * Example:
 * [_logic, _entry, _pos, 90] call jmfsb_support_logistics_fnc_spawnItem
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_entry", [], [[]]], ["_pos", [], [[]]], ["_dir", 0, [0]]];

_entry params [["_name", "", [""]], ["_kind", "", [""]], ["_cls", "", [""]], ["_cargo", [], [[]]], ["_custom", [], [[]]], "", "", ["_load", "", [""]]];

if (isNull _logic || {!isClass (configFile >> "CfgVehicles" >> _cls)}) exitWith {
    WARNING_2("delivery: '%1' (%2) is not a class in this mission",_name,_cls);
    objNull
};

private _obj = createVehicle [_cls, _pos, [], 0, "CAN_COLLIDE"];
if (isNull _obj) exitWith {
    WARNING_1("delivery: '%1' could not be made",_cls);
    objNull
};
_obj setDir _dir;
_obj setPosATL _pos;

if (_kind isEqualTo ITEM_CRATE) then {
    [_obj, _logic, _load] call FUNC(fillCrate);
} else {
    clearWeaponCargoGlobal _obj;
    clearMagazineCargoGlobal _obj;
    clearItemCargoGlobal _obj;
    clearBackpackCargoGlobal _obj;
    // Each list is [[classes], [counts]], as the cargo getters give it.
    _cargo params [["_weapons", [[], []]], ["_mags", [[], []]], ["_items", [[], []]], ["_packs", [[], []]]];
    _weapons params [["_wClasses", []], ["_wCounts", []]];
    _mags params [["_mClasses", []], ["_mCounts", []]];
    _items params [["_iClasses", []], ["_iCounts", []]];
    _packs params [["_bClasses", []], ["_bCounts", []]];
    {_obj addWeaponCargoGlobal [_x, _wCounts param [_forEachIndex, 1]]} forEach _wClasses;
    {_obj addMagazineCargoGlobal [_x, _mCounts param [_forEachIndex, 1]]} forEach _mClasses;
    {_obj addItemCargoGlobal [_x, _iCounts param [_forEachIndex, 1]]} forEach _iClasses;
    {_obj addBackpackCargoGlobal [_x, _bCounts param [_forEachIndex, 1]]} forEach _bClasses;
    if (_custom isNotEqualTo []) then {
        [_obj, _custom param [0, false], _custom param [1, false]] call BIS_fnc_initVehicle;
    };
};

if (_obj isKindOf "AllVehicles" && !isNil QEFUNC(adapter_alive,profileIgnore)) then {
    [_obj] call EFUNC(adapter_alive,profileIgnore);
};

_obj
