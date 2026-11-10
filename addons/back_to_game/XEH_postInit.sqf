#include "script_component.hpp"

// No CBA events here any more (review S7): any client could raise them - one
// teleported every player at once. A joining client asks the server by
// remoteExec (FUNC(handleConnected), which checks the unit is the sender's),
// the server offers the teleport by remoteExec (FUNC(handleTeleport), taken
// only from the server), and the confirm button calls FUNC(teleportPlayer)
// on the player's own machine.

if (isServer) then {
    addMissionEventHandler ["HandleDisconnect", {
        params ["_unit", "_id", "_uid", "_name"];
        if !GVAR(enableAddon) exitWith {};
        [_unit, _uid] call FUNC(handleDisconnected);
        // To prevent AI transfer to server
        false
    }];
};

if (hasInterface) then {
    [{
        if !GVAR(enableAddon) exitWith {};
        [player, getPlayerUID player] call FUNC(handleConnected);
    }] call EFUNC(common,runAfterSettingsInit);
};
