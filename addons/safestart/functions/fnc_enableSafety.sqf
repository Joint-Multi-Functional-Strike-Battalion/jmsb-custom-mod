#include "script_component.hpp"
/*
 * Author: veteran29
 * Safe start on this machine's player: weapon on his back and, when the
 * Lock weapon setting is on and ACE safe mode is loaded, the safety on.
 * Called from XEH_postInitClient. Local calls only (review R1: it was the
 * enableSafety CBA event, which any client could raise on every machine).
 *
 * Arguments:
 * 0: Player <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call jmfsb_safestart_fnc_enableSafety
 *
 * Public: No
 */

params [["_player", objNull, [objNull]]];

if (isRemoteExecuted || {isNull _player} || {!local _player}) exitWith {};

[_player] call FUNC(lowerWeapon);

// Nested, not one bare && - GVAR(startLocked) is only REGISTERED when
// ace_safemode is loaded, and a non-lazy && evaluates both sides:
// without the mod the old line threw on every enableSafety.
if (EGVAR(common,aceSafemode)) then {
    if (GVAR(startLocked)) then {
        [_player, currentWeapon _player, true] call ACEFUNC(safemode,setWeaponSafety);
    };
};
