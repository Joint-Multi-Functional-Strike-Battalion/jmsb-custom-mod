#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A
 * This function is both a wrapper and function that retreave the baseclass of a radio.
 *
 * Arguments:
 * 0: Radio <STRING>
 *
 * Return Value:
 * Radio Baseclass <STRING>
 *
 * Example:
 * ["ACRE_PRC343"] call ymf_fnc_getRadioBase
 *
 */

params[["_radio", "", [""]]];

if (!EGVAR(Patches,usesACRE) && !EGVAR(Patches,usesTFAR)) exitWith {_radio};
if (!EGVAR(Settings,enableRadios)) exitWith {_radio};

if (EGVAR(patches,usesACRE)) exitWith {[_radio] call acre_api_fnc_getBaseRadio};

// TFAR: an instance resolves to its arsenal class (tf_parent)
private _radioBase = getText (configFile >> "CfgWeapons" >> _radio >> "tf_parent");
[_radioBase, _radio] select (_radioBase isEqualTo "")
