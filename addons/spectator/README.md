# Spectator

`jmfsb_spectator`

Spectator camera for the dead and for admins.

**Who may switch it (review R1).** `start`, `stop` and `reloadLocal` run on a
player's own machine: called there (death, respawn, unconscious), or sent by
the server by `remoteExec` (`enable`, `disable`, `restart`, all server only),
and a remote call is taken only from the server. They were CBA events any
client could raise to force every player in or out of spectator.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_common`
- `A3_Functions_F_Exp_A` _(external)_

## Ships

11 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_spectator_enabled` | CHECKBOX | Enable spectator |
| `jmfsb_spectator_allowUnconscious` | CHECKBOX | Allow spectator for unconscious |
| `jmfsb_spectator_enabledUnconscious` | CHECKBOX | Enable spectator (CLIENT) |
| `jmfsb_spectator_unconsciousDelay` | SLIDER | Unconscious spectator delay |
| `jmfsb_spectator_sides` | LIST | Sides available for spectating |
| `jmfsb_spectator_sidesUnconscious` | LIST | Sides available for spectating |
| `jmfsb_spectator_civilianSide` | CHECKBOX | Allow civilian spectating |
| `jmfsb_spectator_civilianSideUnconscious` | CHECKBOX | Allow civilian spectating |
| `jmfsb_spectator_allowAI` | CHECKBOX | Allow AI spectating |
| `jmfsb_spectator_allowAIUnconscious` | CHECKBOX | Allow AI spectating |
| `jmfsb_spectator_freeCamera` | CHECKBOX | Allow free camera |
| `jmfsb_spectator_freeCameraUnconscious` | CHECKBOX | Allow free camera |
| `jmfsb_spectator_TPPCamera` | CHECKBOX | Allow TPP Camera |
| `jmfsb_spectator_TPPCameraUnconscious` | CHECKBOX | Allow TPP Camera |

## Functions

<details><summary>11</summary>

- `jmfsb_spectator_fnc_EGSpectator`
- `jmfsb_spectator_fnc_addPlayerStatePanel`
- `jmfsb_spectator_fnc_canSpectate`
- `jmfsb_spectator_fnc_disable`
- `jmfsb_spectator_fnc_enable`
- `jmfsb_spectator_fnc_onDisplayLoad`
- `jmfsb_spectator_fnc_reloadLocal`
- `jmfsb_spectator_fnc_restart`
- `jmfsb_spectator_fnc_start`
- `jmfsb_spectator_fnc_stop`
- `jmfsb_spectator_fnc_toggle`

</details>
