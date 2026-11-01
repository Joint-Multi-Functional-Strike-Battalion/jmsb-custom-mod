#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: who sent the remote-executed call now running (review S1-S7,
 * recommendation R1). The machine is the engine's remoteExecutedOwner, never
 * anything the call's arguments say; the unit is the player that machine
 * owns; the uid is that unit's Steam id. A call this machine made itself
 * (not remote executed) is the server's own: owner 2 and the host's player
 * (objNull on a dedicated server).
 *
 * CBA events carry no sender (they travel as public variables), so a
 * request that needs trust comes by remoteExec, never by a CBA event.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [owner <NUMBER>, unit <OBJECT>, uid <STRING>] <ARRAY>
 *
 * Example:
 * ([] call jmfsb_common_fnc_sender) params ["_owner", "_unit", "_uid"]
 *
 * Public: Yes
 */

if (!isRemoteExecuted) exitWith {[SERVER_OWNER, player, getPlayerUID player]};

private _owner = remoteExecutedOwner;
private _unit = objNull;
{
    if ((owner _x) isEqualTo _owner) exitWith {_unit = _x};
} forEach allPlayers;

[_owner, _unit, getPlayerUID _unit]
