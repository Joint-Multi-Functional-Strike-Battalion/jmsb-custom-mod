#include "script_component.hpp"
/*
 * Author: 3Mydlo3
 * Function shows teleport confirmation dialog to player
 *
 * Sent by the server (FUNC(handleConnected)) by remoteExec to the player and
 * taken only from the server (review S7: it was a CBA event, so any client
 * could offer another player a teleport to a place of his choosing).
 *
 * Arguments:
 * 0: Player unit <OBJECT>
 * 1: "Savegame" <ARRAY>
 *  0: Player loadout <ARRAY>
 *  1: Player vehicle <OBJECT>
 *  2: Destination <POSITION>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, [getPlayerUID player, getUnitLoadout player, vehicle player, getPos player]] call jmfsb_back_to_game_fnc_handleTeleport
 *
 * Public: No
 */

params ["_unit", "_save"];

if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("handleTeleport: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if !(local _unit) exitWith {
    [_unit, _save] remoteExecCall [QFUNC(handleTeleport), _unit];
};

GVAR(savegameData) = _save;

[{!isNull(findDisplay 46)}, {
    createDialog QGVAR(teleportDialog);
}] call CBA_fnc_waitUntilAndExecute;

nil
