#include "script_component.hpp"
/*
 * Author: ACRE2Team, CPL.Brostrom.A
 * Filters unitLoadout for ACRE or TFAR ID classes and replacing them for base classes.
 *
 * Arguments:
 * 0: Loadout <ARRAY or OBJECT or STRING or CONFIG> (default: getUnitLoadout player)
 *
 * Return Value:
 * Loadout <ARRAY>
 *
 * Example:
 * _loadout = [_loadout] call cScripts_fnc_filterUnitLoadout;
 * _loadout = [getUnitLoadout _unit] call cScripts_fnc_filterUnitLoadout;
 * _loadout = [player] call cScripts_fnc_filterUnitLoadout;
 *
 * Public: Yes
 */

params [["_loadout", getUnitLoadout player, [[], objNull, "", configNull]]];

if !(_loadout isEqualType []) then {
    _loadout = [_loadout] call CBA_fnc_getLoadout;
};

if (_loadout isEqualTo []) exitWith {
    _loadout;
};

// CBA_fnc_getLoadout hands back [loadout, extendedInfo] whatever mods are on;
// a plain getUnitLoadout is the ten-element loadout itself. Tell them apart by
// SHAPE. This used the ACEAX flag, and on a modset without it the wrapper went
// through unopened - "2 elements provided, 10 expected" at every role setup.
private _wrapped = count _loadout == 2 && {(_loadout#0) isEqualType []} && {count (_loadout#0) == 10};
private _baseLoadout = [_loadout, _loadout#0] select _wrapped;
// Remove "ItemRadioAcreFlagged"
if (_baseLoadout#9#2 == "ItemRadioAcreFlagged") then {
    _baseLoadout#9 set [2, ""];
};

// Set ACRE base classes
private _replaceRadio = {
    params ["_item"];
        if (EGVAR(Patches,usesACRE)) then {
        // Replace only if string (array can be eg. weapon inside container) and an ACRE radio
        if (!(_item isEqualType []) && {[_item] call acre_api_fnc_isRadio}) then {
            _this set [0, [_item] call acre_api_fnc_getBaseRadio];
        };
    };
    if (EGVAR(Patches,usesTFAR)) then {
        // Replace only if string (array can be eg. weapon inside container) and an TFAR radio
        if (!(_item isEqualType []) && {_item call TFAR_fnc_isRadio}) then {
            private _baseClassRadio = getText (configFile >> "CfgWeapons" >> _item >> "ace_arsenal_uniqueBase");
            if (_baseClassRadio isNotEqualTo "") then {_this set [0, _baseClassRadio]};
        };
    };
};

if ((_baseLoadout#3) isNotEqualTo []) then {
    {_x call _replaceRadio} forEach (_baseLoadout#3#1); // Uniform items
};

if ((_baseLoadout#4) isNotEqualTo []) then {
    {_x call _replaceRadio} forEach (_baseLoadout#4#1); // Vest items
};

if ((_baseLoadout#5) isNotEqualTo []) then {
    {_x call _replaceRadio} forEach (_baseLoadout#5#1); // Backpack items
};

if (_wrapped) then {
    _loadout set [0,_baseLoadout];
};

_loadout
