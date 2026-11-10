#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a client asks for dead players to be respawned now - the
 * off-server half of FUNC(forceRespawn) and the Zeus "Respawn" modules
 * (FUNC(addZeusModules)), by remoteExec (review S7). Taken only from an admin
 * by the server's records or from a player who holds a curator module. Of
 * the units named, only dead players are respawned; no code from the client
 * runs here.
 *
 * Arguments:
 * 0: The players to respawn <ARRAY of OBJECTs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_units] remoteExecCall ["jmfsb_respawn_fnc_forceRespawnRequest", 2]
 *
 * Public: No
 */

params [["_units", [], [[]]]];

if (!isServer) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_sender"];
if (!([] call EFUNC(common,senderIsAdmin)) && {isNull getAssignedCuratorLogic _sender}) exitWith {
    WARNING_1("forceRespawnRequest: refused - machine %1 is no admin and no Zeus",_owner);
};

private _dead = _units select {_x isEqualType objNull && {_x in allPlayers} && {!alive _x}};
if (_dead isEqualTo []) exitWith {};

INFO_3("Respawning %1 dead player(s) for %2: %3",count _dead,name _sender,_dead apply {name _x});

[] remoteExecCall [QFUNC(forceLocal), _dead];
