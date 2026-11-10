# Back To Game

`jmfsb_back_to_game`

Reconnect handling: a player who drops and returns is offered
their position, loadout, vehicle and group back rather than starting over.

The joining client asks the server by `remoteExec` (`handleConnected`), which
takes the unit only if it is the sender's own and the Steam id from that unit;
the server offers the teleport by `remoteExec` (`handleTeleport`), taken only
from the server; the confirm button calls `teleportPlayer` on the player's own
machine (review S7). They were CBA events: any client could teleport every
player at once, or spend or take another player's save.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`

## Ships

11 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_back_to_game_enableAddon` | CHECKBOX | Enable Back To Game |
| `jmfsb_back_to_game_teleportToLeader` | CHECKBOX | Teleport to leader |
| `jmfsb_back_to_game_teleportToVehicle` | CHECKBOX | Teleport to vehicle |
| `jmfsb_back_to_game_removeBody` | CHECKBOX | Remove body |

## Functions

<details><summary>11</summary>

- `jmfsb_back_to_game_fnc_addHandler`
- `jmfsb_back_to_game_fnc_deletePlayerData`
- `jmfsb_back_to_game_fnc_dialogConfirm`
- `jmfsb_back_to_game_fnc_dialogReject`
- `jmfsb_back_to_game_fnc_getPlayerData`
- `jmfsb_back_to_game_fnc_handleConnected`
- `jmfsb_back_to_game_fnc_handleDisconnected`
- `jmfsb_back_to_game_fnc_handleTeleport`
- `jmfsb_back_to_game_fnc_hasDisconnected`
- `jmfsb_back_to_game_fnc_savePlayerData`
- `jmfsb_back_to_game_fnc_teleportPlayer`

</details>
