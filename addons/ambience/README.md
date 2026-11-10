# Ambience

`jmfsb_ambience`

Ambient war: every few minutes a short artillery stonk lands on a building near a player inside the named markers. It never targets the players themselves - the distance band keeps it off their heads - and every impact area is announced on the alert bus first.

The kamikaze drone's dive ends in one burst and nothing else: the airframe is deleted, crew and all, where the warhead goes or where it is shot down, so no wreck flies on at dive speed into the people below.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

2 unit classes, 5 functions.

## Eden modules

### JMSB - Ambient Shelling

`jmfsb_moduleAmbientShelling`, category jmfsb_modules

Ambient war: every few minutes a short artillery stonk lands on a building near a player inside the named markers. It never targets the players themselves - the distance band keeps it off their heads - and every impact area is announced on the alert bus first.

<details><summary>8 attributes</summary>

- `bandMax`
- `bandMin`
- `intervalMax`
- `intervalMin`
- `markers`
- `roundsMax`
- `roundsMin`
- `shellClasses`

</details>

### JMSB - Ambient Kamikaze Drones

`jmfsb_moduleAmbientKamikaze`, category jmfsb_modules

Ambient war: every few minutes a one-way drone flies in and dives on a building near a player inside the named markers. It is a real aircraft on the map - audible, visible and killable, and shooting it down is the counterplay. It never dives at the players themselves.

<details><summary>7 attributes</summary>

- `bandMax`
- `bandMin`
- `diveSpeed`
- `droneClasses`
- `intervalMax`
- `intervalMin`
- `markers`

</details>

## Functions

<details><summary>5</summary>

- `jmfsb_ambience_fnc_areaMarker`
- `jmfsb_ambience_fnc_kamikazeModule`
- `jmfsb_ambience_fnc_kamikazeRun`
- `jmfsb_ambience_fnc_pickBuilding`
- `jmfsb_ambience_fnc_shellingModule`

</details>
