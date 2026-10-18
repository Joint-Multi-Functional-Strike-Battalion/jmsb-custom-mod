#include "..\script_component.hpp"
/*
 * Author: JMSB
 * One round of an engagement, then the next ADS_BURST_GAP later until the
 * count runs out - a CBA timer chain that ends by itself, never a PFH.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 * 1: Gunner <OBJECT>
 * 2: Weapon <STRING>
 * 3: Fire mode <STRING>
 * 4: Rounds left <NUMBER>
 *
 * Return Value: None
 *
 * Example:
 * [_veh, _gunner, "weapon_Cannon_Phalanx", "manual", 12] call jmfsb_adsite_fnc_burst
 *
 * Public: No
 */

params ["_veh", "_gunner", "_weapon", "_fireMode", "_left"];

if (!alive _veh || {!alive _gunner} || {!local _gunner}) exitWith {};

_gunner forceWeaponFire [_weapon, _fireMode];

if (_left > 1) then {
    [LINKFUNC(burst), [_veh, _gunner, _weapon, _fireMode, _left - 1], ADS_BURST_GAP] call CBA_fnc_waitAndExecute;
};
