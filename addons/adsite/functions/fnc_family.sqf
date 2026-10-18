#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Which threat family an ammo class is, and how fast it flies - read once per
 * class from config and cached, so every later shot of it is one lookup.
 *
 *   FAM_BOMB       BombCore
 *   FAM_MISSILE    MissileCore, unless it is an AA missile (airLock ADS_AA_LOCK)
 *   FAM_ROCKET     RocketCore
 *   FAM_ARTILLERY  ShellCore / SubmunitionCore with artilleryLock, or at least
 *                  ADS_ARTY_MIN_HIT heavy (FUNC(threat) also asks for a steep
 *                  launch, so a tank's flat HE shot is not one)
 *   FAM_NONE       everything else - bullets, grenades, flares, smoke
 *
 * Arguments:
 * 0: Ammo class <STRING>
 *
 * Return Value:
 * [family, speed m/s] <ARRAY>
 *
 * Example:
 * ["Sh_82mm_AMOS"] call jmfsb_adsite_fnc_family
 *
 * Public: No
 */

params [["_ammo", "", [""]]];

private _base = configFile >> "CfgAmmo";
private _cfg = _base >> _ammo;
private _shellLike = {
    getNumber (_cfg >> "artilleryLock") > 0 || {getNumber (_cfg >> "hit") >= ADS_ARTY_MIN_HIT}
};

private _family = switch (true) do {
    case (!isClass _cfg): { FAM_NONE };
    case (_ammo isKindOf ["BombCore", _base]): { FAM_BOMB };
    case (_ammo isKindOf ["MissileCore", _base]): {
        [FAM_MISSILE, FAM_NONE] select (getNumber (_cfg >> "airLock") >= ADS_AA_LOCK)
    };
    case (_ammo isKindOf ["RocketCore", _base]): { FAM_ROCKET };
    case (_ammo isKindOf ["SubmunitionCore", _base]);
    case (_ammo isKindOf ["ShellCore", _base]): { [FAM_NONE, FAM_ARTILLERY] select (call _shellLike) };
    default { FAM_NONE };
};

private _speed = getNumber (_cfg >> "maxSpeed") max getNumber (_cfg >> "typicalSpeed");
if (_speed <= 0) then { _speed = ADS_DEFAULT_SPEED };

private _info = [_family, _speed];
GVAR(families) set [_ammo, _info];
_info
