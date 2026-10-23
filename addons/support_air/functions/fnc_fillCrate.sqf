#include "script_component.hpp"
/*
 * Author: JMSB
 * Fills a drop crate with the unit's own gear: every class on the PAC arsenal
 * lists the module names.
 *
 * WHERE THE LISTS LIVE. PAC keeps the unit's arsenal as named lists -
 * "weapons", "magazines", "backpacks", "items..." - in its structure's
 * "arsenal" document, common lists under "lists" and named arsenal versions
 * under "variants" (addons/pac FUNC(cfgLists), FUNC(pgArsenalLists)). A name
 * on the module is a common list; "version.list" is a list of a named
 * version. The mission's own Common_Arsenal class of the same list name is
 * added, exactly as the player arsenal does (addons/groups FUNC(buildArsenal))
 * - the database adds to the mission, it does not replace it.
 *
 * NOTHING FOUND IS NOT AN EMPTY CRATE. With no PAC, no list of that name or
 * an empty one, the crate keeps the contents its class came with - the
 * module's Crate Class is the fallback, and the RPT says the lists gave
 * nothing.
 *
 * Arguments:
 * 0: The crate <OBJECT>
 * 1: The module logic <OBJECT>
 * 2: The load - comma-separated list names - picked for this drop <STRING> (optional, default the module's first load)
 *
 * Return Value:
 * Filled from the lists <BOOL>
 *
 * Example:
 * [_crate, _logic, "magazines, itemsMedical"] call jmfsb_support_air_fnc_fillCrate
 *
 * Public: No
 */

// The crate takes whatever the lists add up to.
#define CRATE_LOAD 1e6

params [["_crate", objNull, [objNull]], ["_logic", objNull, [objNull]], ["_load", "", [""]]];

if (isNull _crate || {isNull _logic}) exitWith {false};

if (_load isEqualTo "") then {_load = (_logic getVariable [QGVAR(loads), [""]]) param [0, ""]};
private _names = (_load splitString ", ") select {_x isNotEqualTo ""};
if (_names isEqualTo []) exitWith {false};

private _arsenal = (missionNamespace getVariable [QEGVAR(pac,structure), createHashMap]) getOrDefault ["arsenal", createHashMap];
if !(_arsenal isEqualType createHashMap) then {_arsenal = createHashMap};
private _common = _arsenal getOrDefault ["lists", createHashMap];
if !(_common isEqualType createHashMap) then {_common = createHashMap};
private _variants = _arsenal getOrDefault ["variants", createHashMap];
if !(_variants isEqualType createHashMap) then {_variants = createHashMap};

private _classes = [];
{
    private _parts = _x splitString ".";
    private _list = [];
    if (count _parts > 1) then {
        private _doc = _variants getOrDefault [_parts select 0, createHashMap];
        if (_doc isEqualType createHashMap) then {_list = _doc getOrDefault [_parts select 1, []]};
    } else {
        _list = _common getOrDefault [_x, []];
        private _mission = missionConfigFile >> "Common_Arsenal" >> _x;
        if (isArray _mission) then {_list = +_list + getArray _mission};
    };
    if (_list isEqualType []) then {
        {
            if (_x isEqualType "" && _x isNotEqualTo "") then {_classes pushBackUnique _x};
        } forEach _list;
    };
} forEach _names;

if (_classes isEqualTo []) exitWith {
    WARNING_2("drop crate: the lists %1 gave nothing - '%2' keeps its own contents",_names,typeOf _crate);
    false
};

clearWeaponCargoGlobal _crate;
clearMagazineCargoGlobal _crate;
clearItemCargoGlobal _crate;
clearBackpackCargoGlobal _crate;
_crate setMaxLoad CRATE_LOAD;

private _mags = _logic getVariable [QGVAR(magCount), 10];
private _items = _logic getVariable [QGVAR(itemCount), 2];
private _unknown = [];
{
    switch (true) do {
        case (isClass (configFile >> "CfgMagazines" >> _x)): {
            if (_mags > 0) then {_crate addMagazineCargoGlobal [_x, _mags]};
        };
        case (isClass (configFile >> "CfgWeapons" >> _x)): {
            if (_items <= 0) exitWith {};
            if (_x isKindOf ["Rifle", configFile >> "CfgWeapons"] || {_x isKindOf ["Pistol", configFile >> "CfgWeapons"]} || {_x isKindOf ["Launcher", configFile >> "CfgWeapons"]}) then {
                _crate addWeaponCargoGlobal [_x, _items];
            } else {
                _crate addItemCargoGlobal [_x, _items];
            };
        };
        case (isClass (configFile >> "CfgVehicles" >> _x) && {_x isKindOf "Bag_Base"}): {
            if (_items > 0) then {_crate addBackpackCargoGlobal [_x, _items]};
        };
        case (isClass (configFile >> "CfgGlasses" >> _x)): {
            if (_items > 0) then {_crate addItemCargoGlobal [_x, _items]};
        };
        default {_unknown pushBack _x};
    };
} forEach _classes;

if (_unknown isNotEqualTo []) then {
    WARNING_1("drop crate: not classes in this mission - %1",_unknown);
};
INFO_2("drop crate filled from %1 - %2 classes",_names,count _classes - count _unknown);

true
