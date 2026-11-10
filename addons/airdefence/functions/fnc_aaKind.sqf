#include "script_component.hpp"
/*
 * Author: YonV
 * What kind of air defence this static is - none, gun or missile.
 *
 * Asked of the config rather than a class list, because a class list is a
 * maintenance job that goes stale the first time somebody loads a mod this was
 * not written against. A weapon that shoots at aircraft carries an air-target
 * magazine; whether its round is a missile is what separates a SAM launcher
 * from an AA gun turret, and a BATTERY is launchers - the sweep that treated
 * the two alike is how a "battery" came out as a ring of gun turrets.
 *
 * Arguments:
 * 0: Vehicle class <STRING>
 *
 * Return Value:
 * 0 does not engage aircraft / 1 gun / 2 missile <NUMBER>
 *
 * Example:
 * ["O_SAM_System_04_F"] call jmfsb_airdefence_fnc_aaKind
 */

params [["_cls", "", [""]]];

if (_cls isEqualTo "") exitWith {0};

private _cfg = configFile >> "CfgVehicles" >> _cls;
private _kind = 0;

private _fnc_scanMags = {
    params ["_mags"];
    {
        private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
        if (_ammo isEqualTo "") then {continue};

        // airLock 2 is "locks on to aircraft only"; 1 is "can". Either engages
        // aircraft; a missile round outranks a gun round the moment it shows.
        if (getNumber (configFile >> "CfgAmmo" >> _ammo >> "airLock") > 0) then {
            if (_ammo isKindOf ["MissileBase", configFile >> "CfgAmmo"]) exitWith {
                _kind = 2;
            };
            _kind = _kind max 1;
        };
    } forEach _mags;
};

{
    [getArray (_x >> "magazines")] call _fnc_scanMags;
    if (_kind == 2) exitWith {};
} forEach ([_cfg >> "Turrets", 1] call BIS_fnc_returnChildren);

// Some statics carry their weapon at the hull rather than in a turret.
if (_kind < 2) then {
    [getArray (_cfg >> "magazines")] call _fnc_scanMags;
};

_kind
