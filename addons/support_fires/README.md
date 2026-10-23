# Support Fires

`jmfsb_support_fires`

Fires for TAC//SUPPORT: artillery, cruise missiles and loitering munitions.
A provider of the support core (`jmfsb_support`, kind `fires`, asset ids
`fires:<n>`) - see `addons/support/README.md` for the contract and
`docs/DESIGN_SUPPORT.md` for the brief (phase 2).

**The modules act like Simplex, except that artillery is virtual** (user,
2026-10-20). Simplex Support Services is a behaviour reference only: no code
of it is used and nothing depends on it.

**No module, no asset.** Each placed module is one row on the support page and
nothing else is: a mission without a **JMSB - Cruise Missiles** module has no
cruise missiles. Many modules of each kind may be placed. No module carries a
side (D59): every asset belongs to the players' side, and a loitering
munition's prey is the enemy side worked out from the mission's side relations.

| Module | Asset type | What fires |
|---|---|---|
| JMSB - Virtual Artillery | `arty` (ARTILLERY) | nothing on the map: each round is the shell class, spawned on its descent over the target after the time of flight from the module |
| JMSB - Artillery Battery *(retired, hidden)* | `arty` (ARTILLERY) | the same virtual rounds; synced guns are read, never fired - see below |
| JMSB - Cruise Missiles | `cruise` (CRUISE MISSILES) | a real missile projectile launched at the module and flown the whole route |
| JMSB - Loitering Munitions | `loiter` (LOITERING MUNITIONS) | a real air vehicle (Switchblade 600 with the mod, else a Darter) that hunts the area |

**Artillery is virtual.** No gun anywhere aims or fires for this addon. Both
artillery modules list under the shared ARTILLERY tab, beside any other
provider's batteries.

## On the support page

Every task needs a TARGET point. The steppers write parameter slots 12-19 and
32-35 (36-39 are kept for this addon; 20-31 and 40-48 are support_air's):

| Slot | Stepper | Used by |
|---|---|---|
| 12 | ORDNANCE - the battery's own round types, with rounds left | artillery |
| 13 | ROUNDS PER GUN - up to the module's Max Rounds Per Gun | artillery |
| 19 | SHEAF TYPE - CONVERGED, PARALLEL, BOX, CREEPING (those the module offers) | artillery |
| 14 | SHEAF (m) - the half-width of the square the page draws round the target | artillery |
| 15 | GUNS - ALL, or 1..n | artillery |
| 33 | INTERVAL - seconds added between one gun's rounds (hidden when Max Interval is 0) | artillery |
| 32 | DELAY - seconds before the first round or missile (hidden when Max Delay is 0) | artillery, cruise missiles |
| 34 | REPEAT - extra volleys (hidden when Max Repeats is 0) | artillery |
| 35 | COORDINATE - ALONE, or WITH NEARBY batteries (only offered when one is in reach) | artillery |
| 16 | MISSILES - up to the salvo size | cruise missiles |
| 17 | MUNITIONS - up to the launch size | loitering munitions |
| 18 | SEARCH RADIUS (m) | loitering munitions |

**Before CONFIRM** (the core's `preview` hook) the board's VERDICT line reads
the order exactly as CONFIRM would send it: `ETA 70 S - 4 GUNS x 3 HE` (a range
when the module has a response time; volleys, `+ NEARBY` and `ONLY n LEFT`
when they apply), `TIME TO TARGET 95 S - 2 MISSILES`, `ON STATION IN 120 S -
2 MUNITIONS, SEARCH 300 M`. It holds CONFIRM only for what the order would be
refused for: busy or cooling down, nothing left, `OUT OF RANGE - 14.2 KM, MAX
12 KM`, `TOO CLOSE - 300 M, MIN 420 M`. **On the map** (the `overlay` hook) the
picked asset shows its position and its range rings, `MIN` and `MAX`: a
battery both, a cruise missile launcher its 1 km minimum and its reach, a
loitering munition site its reach.

A request is refused on the requester's own machine, with the reason, when it
cannot be fired: no target, inside the minimum or beyond the maximum range,
nothing of that type left, busy or cooling down. RTB is CHECK FIRE for a
battery (virtual rounds not yet fired are not fired; those in the air land;
every battery that joined checks fire too), and self-destruct for loitering
munitions. A cruise missile in flight cannot be recalled.

The server acknowledges every order with what will happen and when
(`jmfsb_support_ack`), and the asset talks on the notify rail of its side:
fire mission received (with the wait), SHOT with the impact grid and time of
flight, SPLASH, rounds complete, check fire, missile away, on station, target
acquired, impact, and **rearmed, ready for tasking** when its cooldown runs
out. While a mission runs its target is **marked on the map** for the side
(an icon, and the sheaf or search area as an outline), and the marker goes
when the mission ends.

**Cooldown** is Simplex's: the module's cooldown after the mission ends, plus
its cooldown per round (artillery) or per missile (cruise) for every one the
mission fired.

## How each one fires

- **Virtual Artillery.** The module is the battery, on or off the map. The
  time of flight and descent angle come from a vacuum arc (Arma flies shells
  without drag, so this is the arc a gun's round flies) from the battery to
  the target. High angle fires the lowest of six charges (shares of the
  *Muzzle Velocity*) that reaches with the tube at or under 80 degrees, as a
  real battery would; low angle fires the top charge flat. The range is the
  tighter of the module's *Minimum / Maximum Range* and what the charges
  reach.
  - **The fire mission.** After a random *Response Time* plus the DELAY asked
    for, every gun fires its rounds one *Reload* plus the INTERVAL apart, the
    guns of a salvo a moment apart. REPEAT fires more volleys, each once the
    one before has landed and the *Cooldown* has passed. Fewer rounds left
    than asked fires what is left.
  - **The sheaf.** CONVERGED puts each round at random inside the SHEAF radius;
    PARALLEL lines the guns up across the line of fire over the sheaf's width;
    BOX spreads the rounds over the whole square; CREEPING gives each gun a
    lane and walks its rounds from the near edge to the far edge along the
    line of fire. Each round then lands within the module's *Dispersion* of
    its aim point.
  - **Coordinated.** With COORDINATE on, every other battery of the side whose
    position is within the tasked battery's *Coordination Distance*, that has
    a Coordination Distance of its own, is free, carries the same shell class
    and reaches the target, fires the same mission with all its guns. Each
    calls its own SHOT and SPLASH and cools down on its own.
  - **The round.** Each round comes off the stock as it is fired and is
    spawned 8 seconds before impact on its descent, at a real shell's terminal
    speed. A low-angle descent masked by terrain comes in high. Submunition
    rounds (smoke, cluster, guided, mines, the 230 mm rockets) are opened by
    script at their class's `triggerDistance`; illumination is the flare class
    released over the target.
- **Artillery Battery (retired).** Hidden from Eden and Zeus; a placed one
  still loads and runs as a Virtual Artillery battery with that module's
  defaults - see below.
- **Cruise Missiles.** After a random *Response Time* plus the DELAY asked
  for, the missile ammo (default `ammo_Missile_Cruise_01`, the Mk41 VLS round)
  is created at the module, boosts straight up, then is steered every 0.05 s
  along route points every 1.5 km to the target, terrain-following at the
  *Cruise Altitude*, pops up inside 1.8 km and dives inside 700 m. It is a
  MissileCore in the world, so active protection sees it, and it is reported
  to the air defence intercept (`adsite`) once its time to impact is under
  200 s so AD units engage it. Its own `timeToLive` is its range; a target
  closer than 1 km is refused.
- **Loitering Munitions.** Each munition is created in the air at the module,
  crewed on the players' side, and flown to the point. On station it orbits,
  looks every 3 s for the best visible target its *Strike Rules* allow (enemy
  side only; dearest vehicle, or the man in the biggest group), then dives
  under script control and sets off its warhead. Out of loiter time it
  self-destructs. A target further than the airframe flies in 900 s at its
  transit speed is refused. The Switchblade's warhead is the mod's own; the
  Darter fallback carries `M_Titan_AP`.

## Picking shell classes

The **Virtual Artillery** module takes a **CfgAmmo** class for each round type
(HE, Smoke, Illumination, Cluster, Guided). The shell class decides what lands;
the module's *Muzzle Velocity* decides how long it flies. Every class below
was checked against the vanilla config.

| Round | 155 mm (M4 Scorcher / 2S9 Sochor) | 82 mm (Mk6 mortar) | 230 mm (M5 Sandstorm) |
|---|---|---|---|
| HE | `Sh_155mm_AMOS` | `Sh_82mm_AMOS` | `R_230mm_HE` |
| Smoke | `Smoke_120mm_AMOS_White` | `Smoke_82mm_AMOS_White` | - |
| Illumination | `Flare_82mm_AMOS_White` | `Flare_82mm_AMOS_White` | - |
| Cluster | `Cluster_155mm_AMOS` | - | `R_230mm_Cluster` |
| Guided (seeks armour) | `Sh_155mm_AMOS_guided` | `Sh_82mm_AMOS_guided` | - |
| Guided (laser) | `Sh_155mm_AMOS_LG` | `Sh_82mm_AMOS_LG` | - |
| Mines (in the Cluster or Guided slot) | `Mine_155mm_AMOS_range`, `AT_Mine_155mm_AMOS_range` | - | - |

- **Illumination** is any flare class; the module default
  `F_40mm_White_Illumination` is a long-burning white flare.
  `Flare_82mm_AMOS_White` is the mortar's own, `Flare_82mm_AMOS_White_Illumination`
  a brighter, longer one.
- **Muzzle Velocity** to match the gun: 810 for 155 mm (the magazines'
  `initSpeed`), 200 for the 82 mm mortar, 850 for the 230 mm rockets.
- **Modded shells** (CUP, RHS, ...) are their own CfgAmmo classes - the `ammo`
  of the gun's magazine in the config viewer.

### Retired Artillery Battery: Ammunition Per Gun

Missions that placed **JMSB - Artillery Battery** keep it: it runs as a
virtual battery and **no gun is loaded, ordered or fired**. Its battery stands
at the centre of the synced artillery (the module when none is synced), has as
many guns as are synced (4 when none), and its *Ammunition Per Gun* field takes
`class:rounds` pairs separated by commas - **magazine classes** (as before) or
CfgAmmo shell classes. Each pair is that many rounds **per gun**, multiplied
by the gun count; a magazine gives its `ammo` as the shell and its `initSpeed`
(times the synced guns' top charge) as the muzzle velocity. Blank reads the
rounds already in the synced guns' artillery magazines; blank with no guns
carries the Virtual Artillery defaults (HE 96, smoke 24, illumination 12).
Its range is whatever that muzzle velocity's charges reach (no module
minimum or maximum); every other value is the Virtual Artillery default.

| Gun | Ammunition Per Gun |
|---|---|
| M4 Scorcher | `32Rnd_155mm_Mo_shells:24, 6Rnd_155mm_Mo_smoke:6, 2Rnd_155mm_Mo_Cluster:2, 4Rnd_155mm_Mo_guided:4, 4Rnd_155mm_Mo_LG:4` |
| 2S9 Sochor | `32Rnd_155mm_Mo_shells_O:24, 6Rnd_155mm_Mo_smoke_O:6, 2Rnd_155mm_Mo_Cluster_O:2, 4Rnd_155mm_Mo_guided_O:4, 4Rnd_155mm_Mo_LG_O:4` |
| Mk6 mortar | `8Rnd_82mm_Mo_shells:24, 8Rnd_82mm_Mo_Smoke_white:8, 8Rnd_82mm_Mo_Flare_white:8` |
| M5 Sandstorm | `12Rnd_230mm_rockets:12, 12Rnd_230mm_rockets_cluster:6` |

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_support`

## Ships

4 unit classes, 47 functions.

## Eden modules

### JMSB - Artillery Battery (retired)

`jmfsb_moduleFiresArtillery`, category jmfsb_modules

RETIRED - place JMSB - Virtual Artillery instead. Kept so missions that placed it still load.<br>Runs as a virtual battery: no gun aims or fires. Synced artillery, if any, gives only the battery's position, its gun count and (with Ammunition Per Gun blank) the rounds its magazines carry.<br>Callsign - What the support page calls it Ammunition Per Gun - class:rounds per gun; blank reads the synced guns Cooldown (sec) - Time after a mission before it can be tasked again

<details><summary>3 attributes</summary>

- `ammunition`
- `callsign`
- `cooldown`

</details>

### JMSB - Virtual Artillery

`jmfsb_moduleFiresVirtual`, category jmfsb_modules

THE artillery module. A battery on the support page, on or off the map: no guns exist, the module IS the battery's position. Each round is the shell class itself, spawned high over the target on its descending arc after the time of flight from here, so it is heard coming in. Counter-battery has nothing to find.<br>A Simplex fire mission: ordnance, rounds per gun, sheaf type and size, guns, interval, delay, repeat volleys, and coordination with nearby batteries. The target is marked on the map until the mission ends. Rounds are counted per type and run out.<br>Callsign - What the support page calls it Guns - Tubes in the battery HE, Smoke, Illumination, Cluster, Guided - Shell class and rounds of each; 0 none, -1 unlimited Minimum / Maximum Range (m) - From this module Dispersion (m) - Each round's own error Muzzle Velocity (m/s) - Top charge; time-of-flight model Trajectory - High or low angle Reload (sec) - Between one gun's rounds Cooldown (sec) - After the mission, and between repeats Cooldown Per Round (sec) - Added per round fired Response Time Min / Max (sec) - Random wait before the first round Sheaf Types - Which the support page offers Max Rounds Per Gun, Max Interval, Max Delay, Max Repeats - Stepper limits; 0 hides a stepper Coordination Distance (m) - Batteries this close may fire together; 0 never

<details><summary>28 attributes</summary>

- `callsign`
- `clusterClass`
- `clusterRounds`
- `cooldown`
- `coordination`
- `dispersion`
- `guidedClass`
- `guidedRounds`
- `guns`
- `heClass`
- `heRounds`
- `illumClass`
- `illumRounds`
- `maxDelay`
- `maxInterval`
- `maxRange`
- `maxRepeat`
- `maxRounds`
- `minRange`
- `muzzleVelocity`
- `reload`
- `responseMax`
- `responseMin`
- `roundCooldown`
- `sheafTypes`
- `smokeClass`
- `smokeRounds`
- `trajectory`

</details>

### JMSB - Cruise Missiles

`jmfsb_moduleFiresCruise`, category jmfsb_modules

A cruise missile launcher on the support page, at this module's position - a ship or ground site, off the map edge is fine.<br>Each missile is a real projectile that flies the whole route: up off the rail, terrain-following at cruise altitude to the target, then a terminal dive. Air defence and active protection can shoot it down. The target is marked on the map until the salvo is gone.<br>Callsign - What the support page calls it Missiles - How many for the whole mission Missile Class - The CfgAmmo flown; blank for ammo_Missile_Cruise_01 Warhead - CfgAmmo set off at the target; blank for the missile's own Salvo Size - Most per request Cruise Speed (m/s) / Cruise Altitude (m) - The route Cooldown (sec) - After a salvo Cooldown Per Missile (sec) - Added per missile launched Response Time Min / Max (sec) - Random wait before the first launch Max Delay (sec) - Top of the DELAY stepper; 0 hides it

<details><summary>12 attributes</summary>

- `altitude`
- `callsign`
- `cooldown`
- `maxDelay`
- `missileClass`
- `missileCooldown`
- `missiles`
- `responseMax`
- `responseMin`
- `salvo`
- `speed`
- `warhead`

</details>

### JMSB - Loitering Munitions

`jmfsb_moduleFiresLoiter`, category jmfsb_modules

A loitering munition launch site on the support page, at this module's position.<br>Each munition is a real air vehicle: it flies to the target area, orbits it for the loiter time hunting, dives on the best target its strike rules allow, and self-destructs when time runs out. It can be shot down. The hunt area is marked on the map until the last munition is gone; a target further than the munition can fly in its transit time is refused.<br>Callsign - What the support page calls it Munition Class - Blank for the Switchblade 600 (Switchblade mod) or the side's Darter Munitions - How many for the whole mission Launch Size - Most per request Loiter Time (sec) - Time on station Strike Rules - Vehicles, infantry or both, enemy side only Loiter Altitude (m) - Height above the ground Warhead - CfgAmmo set off on the target; blank for the munition's own Cooldown (sec) - After the last munition is gone

<details><summary>9 attributes</summary>

- `altitude`
- `callsign`
- `cooldown`
- `launchSize`
- `loiterTime`
- `munitionClass`
- `munitions`
- `strikeRules`
- `warhead`

</details>

## Functions

<details><summary>47</summary>

- `jmfsb_support_fires_fnc_abort`
- `jmfsb_support_fires_fnc_aimPoint`
- `jmfsb_support_fires_fnc_assetAvailable`
- `jmfsb_support_fires_fnc_assets`
- `jmfsb_support_fires_fnc_available`
- `jmfsb_support_fires_fnc_ballistics`
- `jmfsb_support_fires_fnc_detonate`
- `jmfsb_support_fires_fnc_entityRow`
- `jmfsb_support_fires_fnc_finish`
- `jmfsb_support_fires_fnc_fireMission`
- `jmfsb_support_fires_fnc_fireVirtual`
- `jmfsb_support_fires_fnc_flyCruise`
- `jmfsb_support_fires_fnc_fmtDist`
- `jmfsb_support_fires_fnc_gunRanges`
- `jmfsb_support_fires_fnc_inRange`
- `jmfsb_support_fires_fnc_launchCruise`
- `jmfsb_support_fires_fnc_launchLoiter`
- `jmfsb_support_fires_fnc_logicOf`
- `jmfsb_support_fires_fnc_loiterOne`
- `jmfsb_support_fires_fnc_loiterTick`
- `jmfsb_support_fires_fnc_mark`
- `jmfsb_support_fires_fnc_moduleArtillery`
- `jmfsb_support_fires_fnc_moduleCruise`
- `jmfsb_support_fires_fnc_moduleLoiter`
- `jmfsb_support_fires_fnc_moduleVirtual`
- `jmfsb_support_fires_fnc_openMission`
- `jmfsb_support_fires_fnc_ordnance`
- `jmfsb_support_fires_fnc_overlay`
- `jmfsb_support_fires_fnc_partners`
- `jmfsb_support_fires_fnc_pickTarget`
- `jmfsb_support_fires_fnc_preview`
- `jmfsb_support_fires_fnc_readOpts`
- `jmfsb_support_fires_fnc_register`
- `jmfsb_support_fires_fnc_request`
- `jmfsb_support_fires_fnc_sayLater`
- `jmfsb_support_fires_fnc_setupBattery`
- `jmfsb_support_fires_fnc_sitrep`
- `jmfsb_support_fires_fnc_sortieDone`
- `jmfsb_support_fires_fnc_stockFromTable`
- `jmfsb_support_fires_fnc_task`
- `jmfsb_support_fires_fnc_taskDecls`
- `jmfsb_support_fires_fnc_tasks`
- `jmfsb_support_fires_fnc_threat`
- `jmfsb_support_fires_fnc_typeList`
- `jmfsb_support_fires_fnc_unmark`
- `jmfsb_support_fires_fnc_virtualRound`
- `jmfsb_support_fires_fnc_virtualShot`

</details>
