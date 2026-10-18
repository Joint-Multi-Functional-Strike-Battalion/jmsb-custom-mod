#include "..\script_component.hpp"
/*
 * Author: JMSB
 * The ACE interaction node for an AD vehicle class, once per class on this
 * machine: Air Defence > one entry per targeting mode, and mute / un-mute.
 * Nothing without ACE.
 *
 * Arguments:
 * 0: Vehicle class <STRING>
 *
 * Return Value: None
 *
 * Example:
 * ["B_AAA_System_01_F"] call jmfsb_adsite_fnc_aceActions
 *
 * Public: No
 */

params [["_cls", "", [""]]];

if (_cls in GVAR(aceClasses)) exitWith {};
GVAR(aceClasses) set [_cls, true];
if (!isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) exitWith {};

private _onSide = {
    params ["_target", "_player"];
    GVAR(enabled) && {alive _target} && {((side group _player) getFriend (side _target)) >= ADS_FRIEND}
};
private _root = [QGVAR(ace), "Air Defence", ADS_ICON, {}, _onSide] call ace_interact_menu_fnc_createAction;
[_cls, 0, ["ACE_MainActions"], _root] call ace_interact_menu_fnc_addActionToClass;

private _path = ["ACE_MainActions", QGVAR(ace)];
{
    private _act = [format ["%1_%2", QGVAR(ace), _x], format ["Targeting: %1", ADS_MODE_NAMES select _forEachIndex], "", {
        params ["_target", "", "_mode"];
        [_target, _mode] call FUNC(setMode);
    }, {
        params ["_target", "", "_mode"];
        (_target getVariable [QGVAR(mode), ADS_MODE_DEFAULT]) isNotEqualTo _mode
    }, {}, _x] call ace_interact_menu_fnc_createAction;
    [_cls, 0, _path, _act] call ace_interact_menu_fnc_addActionToClass;
} forEach ADS_MODES;

private _mute = [QGVAR(aceMute), "Mute alarm", "", {
    params ["_target"];
    [_target, true] call FUNC(setMute);
}, {
    params ["_target"];
    !(_target getVariable [QGVAR(muted), false])
}] call ace_interact_menu_fnc_createAction;
[_cls, 0, _path, _mute] call ace_interact_menu_fnc_addActionToClass;

private _unmute = [QGVAR(aceUnmute), "Un-mute alarm", "", {
    params ["_target"];
    [_target, false] call FUNC(setMute);
}, {
    params ["_target"];
    _target getVariable [QGVAR(muted), false]
}] call ace_interact_menu_fnc_createAction;
[_cls, 0, _path, _unmute] call ace_interact_menu_fnc_addActionToClass;
