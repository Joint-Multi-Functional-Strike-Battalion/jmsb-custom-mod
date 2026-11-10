# Notify

`jmfsb_notify`

The notification widget every jmfsb system talks through, so a warning
from the EW net looks like a warning from the medical page.

**Who may post (review R1).** `notify` shows a line on this machine. A
remote call is taken only from the server. `broadcast` posts to other
players - everyone, a side, one player, a machine id or a list of players -
and the server works out who is told and sends `notify` to them by
`remoteExec`. On a client, `broadcast` goes to `srvBroadcast` on the server,
which posts only for an admin by the server's records or a headless client.
The old
`jmfsb_notify_post` CBA event is gone: any client could raise it to put any
text on every screen. A client telling itself something calls `notify`.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`

## Ships

7 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_notify_enabled` | CHECKBOX | Enable stacked notifications |
| `jmfsb_notify_hidden` | CHECKBOX | Hide notifications |
| `jmfsb_notify_corner` | LIST | Corner |
| `jmfsb_notify_maxVisible` | SLIDER | Max on screen |
| `jmfsb_notify_duration` | SLIDER | Duration (sec) |
| `jmfsb_notify_width` | SLIDER | Width |
| `jmfsb_notify_fontSize` | SLIDER | Text size |
| `jmfsb_notify_font` | LIST | Font |

## Functions

<details><summary>7</summary>

- `jmfsb_notify_fnc_broadcast`
- `jmfsb_notify_fnc_layout`
- `jmfsb_notify_fnc_notify`
- `jmfsb_notify_fnc_place`
- `jmfsb_notify_fnc_show`
- `jmfsb_notify_fnc_srvBroadcast`
- `jmfsb_notify_fnc_tick`

</details>
