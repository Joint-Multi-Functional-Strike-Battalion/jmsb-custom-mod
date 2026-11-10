#include "script_component.hpp"
/*
 * Author: 3Mydlo3
 * Function checks if player has disconnected before and allows him to teleport back
 *
 * A client asks by remoteExec and the server takes the unit only if it is the
 * sender's own, and the Steam id only from that unit (review S7: it was a CBA
 * event, so any client could spend another player's save or take it).
 *
 * Arguments:
 * 0: Player unit <OBJECT>
 * 1: Player UID <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, getPlayerUID player] call jmfsb_back_to_game_fnc_handleConnected
 *
 * Public: No
 */

params ["_unit", "_uid"];

if (!isServer && {hasInterface}) exitWith {
    [_unit] remoteExecCall [QFUNC(handleConnected), SERVER_OWNER];

    nil
};

if (!isServer) exitWith {nil};
if (isNull _unit || {!([_unit] call EFUNC(common,senderIs))}) exitWith {
    WARNING_1("handleConnected: refused - machine %1 named a unit not its own",remoteExecutedOwner);
    nil
};
// The Steam id is the unit's own, never the request's (review S7).
if (isRemoteExecuted) then {_uid = getPlayerUID _unit};

if ([_uid] call FUNC(hasDisconnected)) exitWith {
    INFO_1("%1 has disconnected previously, loading saved data.",name _unit);
    private _save = [_uid] call FUNC(getPlayerData);
    [_unit, _save] remoteExecCall [QFUNC(handleTeleport), _unit];

    // Spent. The save has been handed to the client that asked for it, and
    // leaving it in the store means a player who reconnects a second time is
    // offered the position they held on the FIRST disconnect - and that the
    // store grows for the life of the mission with entries nothing ever reads
    // again. FUNC(deletePlayerData) existed for this and was never called.
    [_uid] call FUNC(deletePlayerData);

    nil
};

nil
