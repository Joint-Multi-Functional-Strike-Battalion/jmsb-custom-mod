# Jumpmaster

`jmfsb_jumpmaster`

HALO, HAHO and static-line jumps for a squad, run by its leader from the
tablet (user, 2026-10-30). Not run in game.

- **Who:** squad leaders and admins (the voice permission table's SL and
  ADMIN, `jmfsb_tacpad_apps_fnc_radioRole`). The JUMPMASTER tile is theirs
  alone; anyone else gets none.
- **The page:** the type (HALO, HAHO, STATIC); the passes (1-4) and the exit
  (automatic at the green light, or each man himself); PICK PATH ON MAP -
  the RED LIGHT point, then the GREEN LIGHT point, the aircraft flying the
  line through them; the stick with every man's mask (HALO and HAHO) and
  parachute, and which pass he is on; the verdict; LAUNCH, or ABORT while a
  run is up. The path is drawn on every map.
- **Readiness:** every living man of the leader's group needs a parachute of
  the setting's classes, and for HALO and HAHO a mask of the setting's.
  LAUNCH waits until all do.
- **The run** (server): the aircraft - the setting's class, or the side's own
  cargo aircraft - appears 3 km short of the red light at the type's
  altitude (HALO / HAHO 6000 m, static line 150 m, both settings), the
  squad is put aboard where each man is local (seats, or standing in the bay
  fixed to the hull), and it flies the line. Past the red light: RED LIGHT,
  JUMP in every man's action menu. Past the green light: GREEN LIGHT, and
  with automatic exit this pass's share of the stick goes out one every
  0.7 s, behind and below the tail with the aircraft's velocity. More
  passes: it circles back to the start of the run-in and flies the line
  again. Last pass flown with men still aboard: it holds over the drop zone
  until they jump. Empty: it leaves and is removed. ABORT holds it over the
  drop zone the same way.
- **Static line:** the round canopy (`NonSteerable_Parachute_F`) is pulled
  1 s after exit, `jmfsb_support_air`'s own chuteTick. HALO and HAHO fall
  free: each man opens his own.
- **Standing in the bay:** the engine does not carry a walking man in a
  moving aircraft, so "stand" fixes him to the hull in two files; an
  aircraft with a bay of its own gets "seats".
- **The wind** (2026-10-30): the engine carries a canopy with the wind and a
  free-falling man not at all, so the stick drifts the wind's vector for its
  seconds under canopy - from the HALO pull altitude (setting, 300 m), from
  the aircraft on a HAHO, from the static line's altitude - scaled by the
  wind-drift setting. The page reads the wind and the drift; LAND on every
  map is where a stick released at the green light comes down; SHIFT PATH
  FOR WIND moves both lights upwind by the drift, so the stick lands where
  the green light was.
- **The ALT readout** (2026-10-30): from the exit the phone's status row
  leads with ALT - height over the ground and the rate of fall, amber from
  the pull altitude down, red at half of it; under canopy the height alone -
  until the man is on the ground.
- **Who the server believes** (review S7): LAUNCH and ABORT go by
  `remoteExec` to `srvLaunch` / `srvAbort`, which take the leader only if he
  is the sender's own unit; the stick is cut to living men of his own group,
  and an unknown type or exit falls back to HALO / automatic. The squad leader
  test stays on the client (the role words are the client's). Each man's
  board, light, jump and word come from the server by `remoteExec` and are
  taken only from it. They were CBA events: any client could put anyone
  aboard, throw anyone out, or abort any squad's run.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_tacpad`
- `jmfsb_tacpad_apps`
- `jmfsb_maptools`
- `jmfsb_support_air`
- `jmfsb_messaging`
- `cba_xeh` _(external)_

## Ships

26 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_jumpmaster_haloAltitude` | SLIDER | HALO / HAHO altitude |
| `jmfsb_jumpmaster_staticAltitude` | SLIDER | Static line altitude |
| `jmfsb_jumpmaster_haloOpenAltitude` | SLIDER | HALO pull altitude |
| `jmfsb_jumpmaster_windFactor` | SLIDER | Wind drift factor |
| `jmfsb_jumpmaster_maskClasses` | EDITBOX | HALO masks |
| `jmfsb_jumpmaster_chuteClasses` | EDITBOX | Parachutes |
| `jmfsb_jumpmaster_passesDefault` | SLIDER | Passes by default |
| `jmfsb_jumpmaster_exitDefault` | LIST | Exit by default |
| `jmfsb_jumpmaster_aircraft` | EDITBOX | Jump aircraft |
| `jmfsb_jumpmaster_bay` | LIST | In the aircraft |

## Functions

<details><summary>26</summary>

- `jmfsb_jumpmaster_fnc_abort`
- `jmfsb_jumpmaster_fnc_altCell`
- `jmfsb_jumpmaster_fnc_altWatch`
- `jmfsb_jumpmaster_fnc_app`
- `jmfsb_jumpmaster_fnc_attach`
- `jmfsb_jumpmaster_fnc_board`
- `jmfsb_jumpmaster_fnc_classList`
- `jmfsb_jumpmaster_fnc_draw`
- `jmfsb_jumpmaster_fnc_drift`
- `jmfsb_jumpmaster_fnc_isJumpmaster`
- `jmfsb_jumpmaster_fnc_jump`
- `jmfsb_jumpmaster_fnc_launch`
- `jmfsb_jumpmaster_fnc_light`
- `jmfsb_jumpmaster_fnc_pick`
- `jmfsb_jumpmaster_fnc_ready`
- `jmfsb_jumpmaster_fnc_say`
- `jmfsb_jumpmaster_fnc_spawnAircraft`
- `jmfsb_jumpmaster_fnc_srvAbort`
- `jmfsb_jumpmaster_fnc_srvEnd`
- `jmfsb_jumpmaster_fnc_srvLaunch`
- `jmfsb_jumpmaster_fnc_srvLight`
- `jmfsb_jumpmaster_fnc_srvTick`
- `jmfsb_jumpmaster_fnc_stick`
- `jmfsb_jumpmaster_fnc_tile`
- `jmfsb_jumpmaster_fnc_typeAlt`
- `jmfsb_jumpmaster_fnc_windShift`

</details>
