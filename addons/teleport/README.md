# Teleport

`jmfsb_teleport`

The menu. IDCs are jmfsb's own block rather than the 7000s the mission version used - 7000 is inside the range other people's dialogs sit in.

**Who may add a point (review S7).** `jmfsb_teleport_fnc_addPoint` runs on the
server. The server's own calls (Eden init fields, the patrol base) pass; a
request a client sends by `remoteExec` - the Zeus "Add teleport point" module -
is taken only from an admin by the server's records or a player who holds a
curator module.

**The point list is the server's.** It lives in the server's `localNamespace`
and only that copy is read and changed by server code (`addPoint`,
`deletePoint`, `listCheck`). `jmfsb_teleport_list` in `missionNamespace` is a
copy for the menus; a client that publishes over it gets the server's list
published back at once.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `cba_settings` _(external)_
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

13 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_teleport_actionRadius` | SLIDER | Action visibility radius |
| `jmfsb_teleport_actionTime` | SLIDER | Teleportation time |

## Functions

<details><summary>13</summary>

- `jmfsb_teleport_fnc_addAction`
- `jmfsb_teleport_fnc_addPoint`
- `jmfsb_teleport_fnc_applyTheme`
- `jmfsb_teleport_fnc_deletePoint`
- `jmfsb_teleport_fnc_listCheck`
- `jmfsb_teleport_fnc_listPublish`
- `jmfsb_teleport_fnc_onButtonClick`
- `jmfsb_teleport_fnc_onLBSelChanged`
- `jmfsb_teleport_fnc_onLoad`
- `jmfsb_teleport_fnc_open`
- `jmfsb_teleport_fnc_teleport`
- `jmfsb_teleport_fnc_zenDialog`
- `jmfsb_teleport_fnc_zenModules`

</details>
