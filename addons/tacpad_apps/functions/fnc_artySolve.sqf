#include "script_component.hpp"
/*
 * Author: YonV
 * The ARTY calculator's firing solutions, one row per charge the gun carries
 * (user, 2026-10-25: "a good arty calculator that works with ACE built in").
 *
 * ACE'S OWN SOLVER: ace_artillerytables_fnc_calculateSolution - the one behind
 * ACE's range table and its air-friction model - so the answer is ACE's. The
 * charges and the air friction are worked out the way ACE's range table works
 * them out (ace_artillerytables_fnc_rangeTableOpen):
 *   muzzle velocity  the magazine's initSpeed x the fire mode's artilleryCharge
 *                    (one row a magazine when every mode is charge 1)
 *   air friction     the magazine's ace_artillerytables_airFriction; none set
 *                    (or 0 or less) is ACE's default -0.00006 while ACE's
 *                    Advanced Corrections is on, else 0; a positive value means
 *                    the ammo's own engine airFriction
 * Without ACE: the vacuum arc (the engine flies shells without drag), with
 * the height difference.
 *
 * Arguments:
 * 0: The gun <OBJECT>
 * 1: Target position, ASL <ARRAY>
 *
 * Return Value:
 * [azimuth mils, range m, height difference m, rows] - each row
 * [label, muzzle velocity, [low elev mils, low TOF s, low deflection mils], [high ...]];
 * an angle it cannot reach is -1. [] without a gun or a weapon <ARRAY>
 *
 * Example:
 * [vehicle player, _targetASL] call jmfsb_tacpad_apps_fnc_artySolve
 *
 * Public: No
 */

params [["_gun", objNull, [objNull]], ["_target", [], [[]]]];

if (isNull _gun || {count _target < 3}) exitWith {[]};

private _turret = [0];
private _weapon = (_gun weaponsTurret _turret) param [0, ""];
if (_weapon isEqualTo "") exitWith {[]};

private _from = getPosASL _gun;
private _range = _from distance2D _target;
private _height = (_target # 2) - (_from # 2);
private _azimuth = (_from getDir _target) * ARTY_MILS_PER_DEG;

private _ace = !isNil "ace_artillerytables_fnc_calculateSolution";
private _adv = missionNamespace getVariable ["ace_artillerytables_advancedCorrections", false];
private _temp = ARTY_STD_TEMP;
if (!isNil "ace_weather_fnc_calculateTemperatureAtHeight") then {
    _temp = [_from # 2] call ace_weather_fnc_calculateTemperatureAtHeight;
};

// The fire modes a player can pick, each with its charge.
private _weaponCfg = configFile >> "CfgWeapons" >> _weapon;
private _modes = (getArray (_weaponCfg >> "modes")) select {
    private _m = _weaponCfg >> _x;
    isClass _m && {getNumber (_m >> "showToPlayer") == 1}
};
private _charges = _modes apply {[getNumber (_weaponCfg >> _x >> "artilleryCharge"), _x]};
private _oneCharge = (count _charges) <= 1 && {((_charges param [0, [1]]) # 0) isEqualTo 1};

// One solution, ACE's or the vacuum arc.
private _fnc_solve = {
    params ["_mv", "_af", "_high"];
    if (_ace) exitWith {
        private _s = [_from, _target, _mv, _high, _af, _temp, ARTY_STD_DENSITY, 0, 0] call ace_artillerytables_fnc_calculateSolution;
        _s params [["_el", -1], ["_defl", 0], ["_tof", -1]];
        if (!(_el isEqualType 0) || {!finite _el || _el <= 0} || {!finite _tof || _tof <= 0}) exitWith {[-1, -1, 0]};
        [_el, _tof, _defl]
    };
    private _v2 = _mv * _mv;
    private _disc = _v2 * _v2 - ARTY_G * (ARTY_G * _range * _range + 2 * _height * _v2);
    if (_disc < 0 || _range <= 0) exitWith {[-1, -1, 0]};
    private _tan = (_v2 + ([-1, 1] select _high) * sqrt _disc) / (ARTY_G * _range);
    private _a = atan _tan;
    [_a * ARTY_MILS_PER_DEG, _range / (_mv * cos _a), 0]
};

private _rows = [];
{
    private _mag = _x;
    private _magCfg = configFile >> "CfgMagazines" >> _mag;
    private _speed = getNumber (_magCfg >> "initSpeed");
    if (_speed <= 0) then {continue};
    private _af = getNumber (_magCfg >> "ace_artillerytables_airFriction");
    if (_af <= 0) then {
        _af = if (_adv) then {
            [ARTY_ACE_DEFAULT_AF, _af] select (isNumber (_magCfg >> "ace_artillerytables_airFriction"))
        } else {0};
    } else {
        _af = getNumber (configFile >> "CfgAmmo" >> getText (_magCfg >> "ammo") >> "airFriction");
    };
    private _name = getText (_magCfg >> "displayNameShort");
    if (_name isEqualTo "") then {_name = getText (_magCfg >> "displayName")};
    private _list = [[[1, ""]], _charges] select (!_oneCharge && {_charges isNotEqualTo []});
    {
        _x params ["_charge", "_mode"];
        private _mv = _speed * _charge;
        _rows pushBack [
            toUpper format ["%1%2", _name, ["", format [" CH%1", _forEachIndex]] select (_mode isNotEqualTo "")],
            round _mv,
            [_mv, _af, false] call _fnc_solve,
            [_mv, _af, true] call _fnc_solve
        ];
    } forEach _list;
} forEach ((_gun magazinesTurret _turret) arrayIntersect (_gun magazinesTurret _turret));

[_azimuth, _range, _height, _rows]
