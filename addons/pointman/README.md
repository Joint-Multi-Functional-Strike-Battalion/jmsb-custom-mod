# Point Man

`jmfsb_pointman`

Navigation to waypoints (user, 2026-10-30: "a navigation app to way points
... call it point man, where you open an app drop down of waypoints or type
in grids, have an add to keep adding waypoints then draw on the map and
update the phone with distance when using").

- **The page** (the POINT MAN tile, or a device F-key set to it): a GRID box
  and ADD (6, 8 or 10 figures, `jmfsb_maptools_fnc_gridToPos`), PICK ON MAP
  (press the map for each waypoint in order; right click ends), the waypoints
  with their distance and bearing from where the GPS says you are, USE /
  STOP and CLEAR ALL. Press a waypoint to make it the next one; DEL takes it
  out. Up to 20.
- **On the map**, every map - the tablet's and the paper one - the moment a
  waypoint exists: numbered dots and measured legs in ink, the way the map
  tools draw a route; while navigating, the next waypoint and the leg to it
  from you in the accent.
- **USE walks the route**: inside the arrival radius (CBA setting, 25 m by
  default) it moves on to the next waypoint and says so; at the last it ends.
  By the GPS, so a jammed set (jmfsb_ew) gives NO FIX, not a true distance,
  and does not walk the route by itself.
- **While navigating** the phone's status row leads with a PM cell - waypoint,
  distance, bearing - and the tablet bar carries the same; the tile shows the
  distance over the bearing and the grid.
- **FOLLOW** (2026-10-30): a list of the BFT friendlies
  (`jmfsb_bft_fnc_friendlies`), nearest first, with the vehicle each is in;
  press one and a waypoint walks with him - the distance on the phone tracks
  him, the dot on the map moves with him, and where he was last seen is kept
  if he drops out.
- **ELEVATION PROFILE** (2026-10-30): the ground along the route as a strip of
  bars (60 samples, terrain only), the waypoints' bars in the accent, with the
  climb, descent, lowest and highest under it. One waypoint: from where you
  are to it.

The waypoints are this player's own, client side and in order; nothing is
shared (the shared picture is TAC//MSG's and BFT's).

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_tacpad`
- `jmfsb_tacpad_apps`
- `jmfsb_maptools`
- `jmfsb_devices`
- `jmfsb_messaging`
- `cba_xeh` _(external)_

## Ships

20 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_pointman_arriveRadius` | SLIDER | Point Man arrival radius |

## Functions

<details><summary>20</summary>

- `jmfsb_pointman_fnc_add`
- `jmfsb_pointman_fnc_addGrid`
- `jmfsb_pointman_fnc_app`
- `jmfsb_pointman_fnc_attach`
- `jmfsb_pointman_fnc_cell`
- `jmfsb_pointman_fnc_clear`
- `jmfsb_pointman_fnc_contacts`
- `jmfsb_pointman_fnc_draw`
- `jmfsb_pointman_fnc_follow`
- `jmfsb_pointman_fnc_gpsPos`
- `jmfsb_pointman_fnc_navText`
- `jmfsb_pointman_fnc_pick`
- `jmfsb_pointman_fnc_profile`
- `jmfsb_pointman_fnc_remove`
- `jmfsb_pointman_fnc_say`
- `jmfsb_pointman_fnc_state`
- `jmfsb_pointman_fnc_tick`
- `jmfsb_pointman_fnc_tile`
- `jmfsb_pointman_fnc_use`
- `jmfsb_pointman_fnc_wpPos`

</details>
