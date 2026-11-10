# Respawn

`jmfsb_respawn`

Respawn handling, including the force-respawn call a trigger can make:

    [west] call jmfsb_respawn_fnc_forceRespawn;

Only the dead are affected, which is why it is safe to fire from a trigger that
may run more than once.

**Off the server it is a request (review S7).** The filter runs on the
calling machine and only the players it picked go to the server by
`remoteExec` (`jmfsb_respawn_fnc_forceRespawnRequest`); the server takes it
only from an admin by its own records or a player holding a curator module,
respawns only those of them who are dead players, and never runs code a
client sent. The Zeus "Respawn sides" / "Respawn player" modules go the same
way. The server tells each dead man by `remoteExec`
(`jmfsb_respawn_fnc_forceLocal`), which a client takes only from the server.
A trigger that is not server-only still works: the server's own copy fires.

Turning respawn on or off and changing the delay (the two CBA settings) go
from the server to every player by `remoteExec` (`enable`, `disable`,
`adjustTimeLocal`), which a client takes only from the server.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_common`
- `jmfsb_notify`

## Ships

12 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_respawn_enabled` | CHECKBOX | Enable respawn |
| `jmfsb_respawn_time` | SLIDER | Respawn delay |

## Functions

<details><summary>12</summary>

- `jmfsb_respawn_fnc_addZeusModules`
- `jmfsb_respawn_fnc_adjustTime`
- `jmfsb_respawn_fnc_adjustTimeLocal`
- `jmfsb_respawn_fnc_disable`
- `jmfsb_respawn_fnc_enable`
- `jmfsb_respawn_fnc_forceLocal`
- `jmfsb_respawn_fnc_forceRespawn`
- `jmfsb_respawn_fnc_forceRespawnRequest`
- `jmfsb_respawn_fnc_gearManaged`
- `jmfsb_respawn_fnc_onPlayerKilled`
- `jmfsb_respawn_fnc_onPlayerRespawn`
- `jmfsb_respawn_fnc_toggle`

</details>
