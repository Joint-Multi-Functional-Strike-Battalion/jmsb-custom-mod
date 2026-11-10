#include "script_component.hpp"
/*
 * Author: YonV
 * The store a strike card asks for, off one airframe (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING section 4) - the CAS drones' and support_air's CAS
 * read it alike.
 *
 *   nothing aboard           CANTCO "NO STORES"
 *   PREFERRED MUNITIONS      the first store whose name or magazine holds the
 *                            words; not carried, or empty: the provider picks
 *                            ("" - AUTO, the heaviest thing aboard)
 *   Line 7 marked LASER      a laser-guided store - the preferred one when it
 *                            is, else the heaviest one aboard; none: CANTCO
 *                            "CANNOT LASE <code>". Only when the mark asks for
 *                            it: SMOKE, IR or no mark takes any store.
 *
 * Laser guided is the ammunition's own word for it: the engine's laser lock,
 * the laser bit of its lock systems, or ACE's semi-active laser seeker.
 *
 * Arguments:
 * 0: Airframe class, or the aircraft itself <STRING or OBJECT>
 * 1: The order, from EFUNC(support,readOrder) <HASHMAP>
 *
 * Return Value:
 * 0: Can fly it <BOOL>
 * 1: Why not, "" when it can <STRING>
 * 2: Magazine class to use, "" for the heaviest aboard <STRING>
 *
 * Example:
 * ([_cls, _order] call jmfsb_cas_fnc_orderStore) params ["_ok", "_why", "_mag"]
 *
 * Public: No
 */

params [["_src", "", ["", objNull]], ["_order", createHashMap, [createHashMap]]];

private _stores = [_src] call FUNC(stores);
if (_stores isEqualTo []) exitWith {[false, WHY_NO_STORES, ""]};

private _fnc_laser = {
    params ["_mag"];
    private _ammo = configFile >> "CfgAmmo" >> getText (configFile >> "CfgMagazines" >> _mag >> "ammo");
    if (getNumber (_ammo >> "laserLock") > 0) exitWith {true};
    if (((floor (getNumber (_ammo >> "weaponLockSystem") / LOCK_LASER_BIT)) mod 2) isEqualTo 1) exitWith {true};
    (getText (_ammo >> "ace_missileguidance" >> "defaultSeekerType")) isEqualTo SEEKER_LASER
};

private _mag = "";
private _want = toUpper (_order getOrDefault ["munition", ""]);
if (_want isNotEqualTo "") then {
    private _i = _stores findIf {
        ((toUpper (_x select 0)) find _want) >= 0 || ((toUpper (_x select 1)) find _want) >= 0
    };
    if (_i >= 0) then {_mag = (_stores select _i) select 0};
};

if ((_order getOrDefault ["mark", ""]) isNotEqualTo MARK_LASER) exitWith {[true, "", _mag]};

private _lasers = (_stores select {[_x select 0] call _fnc_laser}) apply {_x select 0};
if (_lasers isEqualTo []) exitWith {
    [false, trim format [WHY_CANNOT_LASE, _order getOrDefault ["code", ""]], ""]
};
if !(_mag in _lasers) then {_mag = _lasers select 0};

[true, "", _mag]
