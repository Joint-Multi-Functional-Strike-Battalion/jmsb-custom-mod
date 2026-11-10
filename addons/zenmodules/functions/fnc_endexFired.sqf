#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A, CPL.Dunn.W
 * Warns a player who fires during endex. Added by FUNC(endexLocal) to ACE's
 * ace_firedPlayer and ace_firedPlayerVehicle events, which only fire for the
 * local player, so the player is always the shooter.
 *
 * Arguments:
 * 0: Unit or vehicle that fired <OBJECT>
 * 1: Weapon <STRING>
 * 2: Muzzle <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ace_firedPlayer", jmfsb_zenmodules_fnc_endexFired] call CBA_fnc_addEventHandler
 *
 * Public: No
 */

params ["", ["_weapon", "", [""]], ["_muzzle", "", [""]]];

if !(missionNamespace getVariable [QEGVAR(Mission,Endex), false]) exitWith {};

private _rank = [player, "USA"] call EFUNC(players,getRank);
private _name = [player] call EFUNC(players,unit_getName);

private _hftitle = format [
    "<t color='#ffc61a' size='1.2' shadow='1' shadowColor='#000000' align='center'>%1 %2<br />hold your Fire!</t><br /><br />",
    _rank,
    _name
];
private _hfimage = format ["<img size='5' image='%1' align='center'/><br /><br />", QPATHTOEF(media,images\logo_512.paa)];
private _hftext = "You are not allowed to discharge your weapon during Endex.<br />";
hint parseText (_hftitle + _hfimage + _hftext);

// The server logs it and tells everyone, once per muzzle (FUNC(srvEndexFired),
// review R1: a client's broadcast is refused, and the server names the shooter).
[_weapon, _muzzle] remoteExecCall [QFUNC(srvEndexFired), SERVER_OWNER];
