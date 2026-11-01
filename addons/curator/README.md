# Curator

`jmfsb_curator`

Zeus tooling and the jmfsb additions to the curator interface.

**Who gets Zeus is the server's call (review S7).** `jmfsb_curator_fnc_assignZeus`
sends the request to the server by `remoteExec` (`zeusAssign` / `zeusUnassign`),
never a CBA event. A client may ask only for himself, and gets a curator
module only when he is an admin by the server's records or on the server's
own Zeus list: units with the Eden "Zeus" attribute (the attribute runs on
the server too) and units whose `jmfsb_Player_Unit` names a curator role
(`s3`, `zeus`, `curator`, `debug`) at mission start, read from the server's
copy. The list is kept in `localNamespace` and follows a man across respawn.
A client may unassign only himself (an admin anyone). The server tells the
new curator by `remoteExec` (`zeusAssigned`, taken only from the server), and
activates addons only on the module the asking player is assigned to.

**What Zeus can edit** goes the same way: a placed object or group, and each
player at start, reach the server by `remoteExec` (`editableAdd`), which adds
them for every curator. A man with a curator module may add anything; anyone
else only what his own machine owns.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`

## Ships

8 functions.

## Functions

<details><summary>8</summary>

- `jmfsb_curator_fnc_assignZeus`
- `jmfsb_curator_fnc_createCuratorModule`
- `jmfsb_curator_fnc_editableAdd`
- `jmfsb_curator_fnc_getFreeCuratorModule`
- `jmfsb_curator_fnc_zeusActivateAddons`
- `jmfsb_curator_fnc_zeusAssign`
- `jmfsb_curator_fnc_zeusAssigned`
- `jmfsb_curator_fnc_zeusUnassign`

</details>
