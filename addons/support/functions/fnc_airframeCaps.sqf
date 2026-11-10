#include "script_component.hpp"
/*
 * Author: YonV
 * What an aircraft can do for a man on the ground beyond its stores - the
 * AIRFRAME CHECK-IN's CAPABILITIES ticks (user, 2026-11-02, FUNC(checkIn)).
 *
 *   FMV    full-motion video: a targeting pod (pilotCamera), a drone, or a
 *          turret with its own optics
 *   LASER  a laser designator among its weapons, any seat - the weapon's
 *          magazine is ammunition the engine lases with
 *   IR     thermal (FLIR) in the pod's or a turret's optics
 *   NVG    night vision in the same optics
 *
 * Read off the config for the sensors and off the live airframe for the
 * weapons, so a designator added after it spawned counts.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 *
 * Return Value:
 * Tick prefix -> has it <HASHMAP>
 *
 * Example:
 * ([_veh] call jmfsb_support_fnc_airframeCaps) getOrDefault ["LASER", false]
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

private _caps = createHashMapFromArray [[CAP_FMV, false], [CAP_LASER, false], [CAP_IR, false], [CAP_NVG, false]];
if (isNull _veh) exitWith {_caps};

private _cfg = configOf _veh;
private _modes = [];
private _optics = false;

// The modes one sight sees in: each of its views (OpticsIn), and its own.
private _fnc_modes = {
    params ["_node"];
    {
        _modes append (getArray (_x >> "visionMode"));
    } forEach configProperties [_node >> "OpticsIn", "isClass _x", true];
    _modes append (getArray (_node >> "ViewOptics" >> "visionMode"));
};

private _pod = _cfg >> "pilotCamera";
if (isClass _pod) then {
    _optics = true;
    [_pod] call _fnc_modes;
};

// Turrets nest - a gunner's can carry a commander's - so the tree is walked.
private _fnc_turrets = {
    params ["_node"];
    {
        if (isClass (_x >> "OpticsIn")) then {_optics = true};
        [_x] call _fnc_modes;
        [_x] call _fnc_turrets;
    } forEach configProperties [_node >> "Turrets", "isClass _x", true];
};
[_cfg] call _fnc_turrets;

_modes = _modes apply {toLower _x};
_caps set [CAP_FMV, _optics || unitIsUAV _veh];
_caps set [CAP_IR, VISION_THERMAL in _modes];
_caps set [CAP_NVG, VISION_NVG in _modes];

// A designator: any weapon in any seat, the pilot's ([-1]) included, whose
// magazine's ammunition is the engine's laser.
private _fnc_lases = {
    params ["_weapon"];
    private _magazines = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
    (_magazines findIf {
        (toLower getText (configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> _x >> "ammo") >> "simulation")) isEqualTo SIM_LASER
    }) >= 0
};
private _seats = [[-1]] + allTurrets [_veh, false];
_caps set [CAP_LASER, (_seats findIf {((_veh weaponsTurret _x) findIf {[_x] call _fnc_lases}) >= 0}) >= 0];

_caps
