# Equipment

`jmfsb_equipment`

Field equipment: the Vector designator map marker, fortify tooling
and the odds and ends that did not deserve an addon each.

The Vector marker's in-world name goes by the server (review R1): the
client sends the point by `remoteExecCall` to `srvMarker3D`, which names the
sender himself, checks he holds a Vector and the point is in its reach, and
sends it to every client's `show3DMarker`, which takes it only from the
server. It was the `jmfsb_equipment_marker3D` CBA event, which any client
could raise to put any text anywhere on every screen.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `A3_Ui_F` _(external)_
- `cba_main` _(external)_
- `cba_xeh` _(external)_
- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_medbags`
- `jmfsb_notify`
- `ace_vector` _(external)_
- `ace_fortify` _(external)_
- `A3_Weapons_F` _(external)_
- `cba_jr` _(external)_
- `ace_xm157` _(external)_

## Ships

4 unit classes, 4 weapon/item classes, 5 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_equipment_markerEnabled` | CHECKBOX | Enable Vector Target Marker |
| `jmfsb_equipment_markerType` | LIST | Vector Marker Type |
| `jmfsb_equipment_markerColor` | LIST | Vector Marker Color |
| `jmfsb_equipment_marker3DDuration` | SLIDER | Vector 3D Marker Duration (s) |
| `jmfsb_equipment_markerDuration` | SLIDER | Vector Marker Lifetime (s) |
| `jmfsb_equipment_waypointEnabled` | CHECKBOX | Enable Vector Personal Waypoint |
| `jmfsb_equipment_waypointType` | EDITBOX | Vector Waypoint Type |
| `jmfsb_equipment_waypointColor` | EDITBOX | Vector Waypoint Colour |

## Functions

<details><summary>5</summary>

- `jmfsb_equipment_fnc_placeTargetMarker`
- `jmfsb_equipment_fnc_placeWaypoint`
- `jmfsb_equipment_fnc_show3DMarker`
- `jmfsb_equipment_fnc_srvMarker3D`
- `jmfsb_equipment_fnc_vectorTarget`

</details>
