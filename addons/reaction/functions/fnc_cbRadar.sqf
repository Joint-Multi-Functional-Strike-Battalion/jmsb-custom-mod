#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: an ENEMY gun fired (the class hook in XEH_postInit - AI artillery,
 * never a player's). One report per gun per cbRadarCooldown seconds goes to
 * the players' artillery teams (FUNC(cbReport)). Virtual barrages, which have
 * no gun, come in through FUNC(cbVirtual) instead.
 *
 * Arguments:
 * 0: The enemy gun <OBJECT>
 *
 * Return Value:
 * Teams told <NUMBER>
 *
 * Example:
 * [_gun] call jmfsb_reaction_fnc_cbRadar
 *
 * Public: No
 */

params [["_gun", objNull, [objNull]]];

if (!isServer || {isNull _gun} || {!GVAR(moduleUp)} || GVAR(cbRadar) <= 0) exitWith {0};
// By remoteExec from the machine the gun is local to (review R1: it was a CBA
// event, so any client could file a fake report on any object). The gun must
// be that machine's, artillery, and not crewed by a player.
if (!([_gun] call EFUNC(common,senderIs)) || {isPlayer (gunner _gun)} || {getNumber (configOf _gun >> "artilleryScanner") <= 0}) exitWith {
    WARNING_1("cbRadar: refused - machine %1 does not hold that gun",remoteExecutedOwner);
    0
};

private _key = hashValue _gun;
if (CBA_missionTime < (GVAR(cbRadarLast) getOrDefault [_key, -1e9]) + GVAR(cbRadarCooldown)) exitWith {0};
GVAR(cbRadarLast) set [_key, CBA_missionTime];

private _gside = side group (gunner _gun);
if (_gside isEqualTo sideUnknown) then {_gside = side _gun};

[getPosATL _gun, _gside, getText (configOf _gun >> "displayName")] call FUNC(cbReport)
