#include "..\script_component.hpp"
/*
 * Author: JMSB
 * The tube mask for a goggle, or none. Only a JMSB full-screen goggle
 * (jmfsb_nvg_fullScreen = 1) gets one: ACE's border of the goggle it was made
 * from - the first class up its parents with an ACE_nightvision_border - and
 * that class's eye cups. A JMSB goggle clears both on itself, so the walk starts
 * at its parent; a parent with no border anywhere above it gets ACE's binocular
 * mask. Read from config once per class.
 *
 * Arguments:
 * 0: HMD class <STRING>
 *
 * Return Value:
 * [Texture <STRING>, Eye cups <BOOL>], or [] when the goggle is not a JMSB
 * full-screen one <ARRAY>
 *
 * Example:
 * ["jmfsb_nvg_NVGoggles"] call jmfsb_nvg_fnc_maskTexture
 *
 * Public: No
 */

params [["_hmd", "", [""]]];

if (_hmd isEqualTo "") exitWith {[]};

private _cached = GVAR(maskCache) get _hmd;
if (!isNil "_cached") exitWith {_cached};

private _config = configFile >> "CfgWeapons" >> _hmd;
private _mask = [];

if (getNumber (_config >> QGVAR(fullScreen)) > 0) then {
    private _texture = MASK_DEFAULT;
    private _eyeCups = false;
    private _parent = inheritsFrom _config;

    while {isClass _parent} do {
        private _border = getText (_parent >> "ACE_nightvision_border");
        if (_border isNotEqualTo "") exitWith {
            _texture = _border;
            _eyeCups = getNumber (_parent >> "ACE_nightvision_eyeCups") > 0;
        };
        _parent = inheritsFrom _parent;
    };

    _mask = [_texture, _eyeCups];
};

GVAR(maskCache) set [_hmd, _mask];

_mask
