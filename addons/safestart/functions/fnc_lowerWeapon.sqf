#include "script_component.hpp"
/*
 * Author: veteran29
 * Lowers unit weapon (weapon on back) where the unit is local. A unit local
 * elsewhere is sent there by remoteExec, and only the server may do that -
 * the receiving machine takes a remote call only from the server (review R1:
 * it was the lowerWeapon CBA event, so any client could make anyone sling
 * his weapon).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call jmfsb_safestart_fnc_lowerWeapon
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]]
];

if (isNull _unit) exitWith {nil};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("lowerWeapon: refused - not from the server (machine %1)",remoteExecutedOwner);
    nil
};

if (!local _unit) exitWith {
    if (isServer) then {
        [_unit] remoteExecCall [QFUNC(lowerWeapon), _unit];
    };
    nil
};

_unit action ["WeaponOnBack", _unit];

nil
