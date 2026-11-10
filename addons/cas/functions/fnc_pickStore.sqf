#include "script_component.hpp"
/*
 * Author: YonV
 * The store a pass fires, off the live airframe: the weapon, the magazine
 * and the turret it sits on. Was the picker inside FUNC(fireAt) (2026-11-05,
 * the pass).
 *
 * BY WEIGHT, unless asked by name. The heaviest air-to-ground thing aboard
 * with rounds left in it (CAS_RANK, the same order FUNC(stores) lists them
 * in); a store asked for by name - the one the page offered or the card
 * named, on the airframe as QGVAR(ordnance) - when it is aboard with rounds
 * left, else the heaviest with a warning in the RPT, so a module pointed at
 * an airframe that never carries what the page keeps offering is visible
 * rather than mysterious. Only a magazine the weapon can chamber: a pylon's
 * bombs paired with the gun names a weapon that will never fire.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: Magazine class wanted, "" for the heaviest aboard <STRING> (optional, default "")
 *
 * Return Value:
 * [weapon, magazine, turret path], [] when nothing aboard can hit the ground <ARRAY>
 *
 * Example:
 * ([_veh, ""] call jmfsb_cas_fnc_pickStore) params ["_weapon", "_mag", "_turret"]
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]], ["_want", "", [""]]];

if (!alive _veh) exitWith {[]};

// Rounds left per magazine, pylons included; the same store on two pylons is
// one count.
private _left = createHashMap;
{
    _x params ["_mag", "", ["_rounds", 0]];
    if (_rounds > 0) then {_left set [_mag, (_left getOrDefault [_mag, 0]) + _rounds]};
} forEach (magazinesAllTurrets _veh);

private _rank = CAS_RANK;
private _fnc_bestOf = {
    params ["_want"];
    private _best = [];
    private _bestRank = -1;
    {
        private _turret = _x;
        private _loaded = (_veh magazinesTurret _turret) select {(_left getOrDefault [_x, 0]) > 0};
        {
            private _weapon = _x;
            private _fits = getArray (configFile >> "CfgWeapons" >> _weapon >> "magazines");
            {
                if !(_x in _fits) then {continue};
                if (_want isNotEqualTo "" && _x isNotEqualTo _want) then {continue};
                private _ammo = getText (configFile >> "CfgMagazines" >> _x >> "ammo");
                if (_ammo isEqualTo "") then {continue};
                private _r = _rank find (toLower getText (configFile >> "CfgAmmo" >> _ammo >> "simulation"));
                if (_r < 0) then {continue};
                // The rank list is heaviest-first: a lower index is the
                // better weapon, and the first found at that index wins.
                if (_bestRank < 0 || _r < _bestRank) then {
                    _bestRank = _r;
                    _best = [_weapon, _x, _turret];
                };
            } forEach _loaded;
        } forEach (_veh weaponsTurret _turret);
    } forEach ([TURRET_PILOT] + (allTurrets _veh));
    _best
};

private _best = [_want] call _fnc_bestOf;
if (_best isEqualTo [] && _want isNotEqualTo "") then {
    WARNING_2("'%1' has no '%2' left aboard - falling back to the heaviest thing it still has",typeOf _veh,_want);
    _best = [""] call _fnc_bestOf;
};
if (_best isEqualTo []) then {
    WARNING_1("'%1' is carrying nothing it can shoot at the ground",typeOf _veh);
};

_best
