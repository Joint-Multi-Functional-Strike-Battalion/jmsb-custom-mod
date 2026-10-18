# Air Defence Intercept

`jmfsb_adsite`

Air defence vehicles shoot down incoming artillery, rockets, missiles and bombs, on every side, with no setup.
Rewritten on 2026-10-14 to a hard performance budget: the first `adsite` rescanned the sky every 0.25 s for every
Site and the game ran at about 4 FPS. This version does not scan for anything. It keeps the module class name
(`jmfsb_moduleADSite`) so missions still recognise it. Aircraft and drones are left to the crews' own AI.

- **AD units** are registered once, when the vehicle is created (class InitPost on `LandVehicle` / `Ship`; static
  weapons are LandVehicles). Whether a class counts is worked out once and cached: a CIWS (rate of fire faster than
  0.03 s) with a heavy round (hit 40+), an AA gun with that round on a vehicle with an air search radar, or a missile
  with the dedicated AA lock (airLock 2). Every rifle and MG bullet has airLock 1, so airLock alone counts for
  nothing. `jmfsb_airdefence` batteries and AA bases (its `batteryUp` event) and vehicles synced to a
  **JMSB - Air Defence Site** module are claimed into their own alarm area. A unit drops out on Deleted / Killed.
- **Detection by event.** Every machine's `fired` class event looks up the ammo's family (artillery, rocket,
  missile, bomb, or none), cached per class. Bullets and grenades stop there. For a relevant round, only the
  machine where the shooter is **local** goes on: it keeps the round and sends one message to the server, or a local
  event when the shooter is the server's own AI. Nothing at all is sent while no AD unit exists. The server predicts
  the impact once (ballistic from the launch velocity, or straight to a guided missile's target). It then finds the
  AD units whose protect radius holds the impact and whose side is hostile to the shooter (getFriend under 0.6, or
  any side with **Ignore sides**), and queues the threat with its time to impact. Rounds landing under 3 s or over
  240 s out are ignored. A shell fired flatter than 15 degrees is a tank's direct fire and is ignored too.
- **Engagement.** One global PFH runs every 0.15 s, and only while a threat is in the air. It removes itself when
  the queue empties. Free units pick open threats by their **targeting mode**. Missiles are the outer layer and take
  a threat any time they can reach it. Guns and CIWS are the inner layer and take it in its last 8 s. The gunner
  watches the lead point, and after 1.5 s the vehicle's own weapon fires (`forceWeaponFire`): one missile, steered
  at the point with `setMissileTargetPos`, or a 12-round burst. The kill follows the Air Defenses PLUS pattern:
  when the interceptor's flight time runs out, the **intercept chance** is rolled. On a hit, the machine that fired
  the threat deletes it and leaves a harmless blast in its place. On a miss, another unit may still try.
- **Targeting mode per vehicle**: Off / Random / Closest threat (default) / Highest threat (soonest impact). Players
  on a friendly side set it with the scroll action *Air defence: next targeting mode* or with ACE *Air Defence >
  Targeting*, and mute the vehicle's alarm the same way.
- **Alarms** per side (Off or a base-game alarm sound) play once per salvo per area, then stay quiet for the
  **Alarm repeat**. They play on the area's un-muted units and on its loudspeakers (`Land_Loudspeakers_F`,
  `Land_PortableSpeakers_01_F`). Loudspeakers are found once, when the area is made. A module Site or a battery is
  one area. Automatic units share one area per side per 1 km grid cell.
- **Admin**: `#jmfsb adsite` shows the units, the threats in the air, whether the PFH is running, the last and worst
  pass in ms, and the running totals.

**Performance budget** (enforced in code; the limits are `#define`s in `script_component.hpp`):

| When | Cost |
|---|---|
| Idle, no threat in the air | **zero PFHs**. No scan, no timer of this addon's. |
| A vehicle is created | one hashmap lookup if its class is already known. Otherwise the class is read once. |
| A shot of an ignored type (every bullet and grenade) | **one hashmap lookup** and a compare. |
| A relevant round | one prediction and one pass over the AD units, on the server. One network message only when a client or HC fired it. |
| Threats in the air | one PFH every 0.15 s with at most **16** threats, **64** unit-against-threat tests and **8** new engagements per pass. A pass over **2 ms** logs a throttled WARNING (at most once every 30 s). The target is under 1 ms with 16 threats and 50 units. |
| Firing | CBA timers (12 per gun burst) on the gunner's machine. No PFH. |
| Alarm | a few `playSound3D` per salvo per area. Loudspeakers are cached. |

On 2026-10-14 this addon was removed together with `airdefence` and `iads` because of the frame rate. `airdefence`
is restored unchanged. `iads` (radar EMCON blinking) stays removed.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `cba_xeh` _(external)_
- `cba_settings` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

1 unit class, 26 functions.

## Eden modules

### JMSB - Air Defence Site

`jmfsb_moduleADSite`, category jmfsb_modules

An air defence Site: sync the AA guns, CIWS and SAM launchers that make it. They intercept artillery, rockets, missiles and bombs predicted to land inside the protected radius, and share one alarm. Any air defence vehicle defends itself without this module; the module only sets the radius and the intercept chance for its own.

<details><summary>2 attributes</summary>

- `interceptChance`
- `radius`

</details>

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_adsite_1st Joint Multi-Functional Strike Battalion` | Air Defence"]

[
    QGVAR(enabled) | CHECKBOX |
| `jmfsb_adsite_interceptChance` | SLIDER | Intercept chance |
| `jmfsb_adsite_threatArtillery` | CHECKBOX | Intercept artillery and mortar |
| `jmfsb_adsite_threatRockets` | CHECKBOX | Intercept rockets |
| `jmfsb_adsite_threatMissiles` | CHECKBOX | Intercept missiles |
| `jmfsb_adsite_threatBombs` | CHECKBOX | Intercept bombs |
| `jmfsb_adsite_radiusCap` | SLIDER | Protect radius cap (m) |
| `jmfsb_adsite_ignoreSides` | CHECKBOX | Ignore sides |
| `jmfsb_adsite_alarmWest` | LIST | Alarm - BLUFOR |
| `jmfsb_adsite_alarmEast` | LIST | Alarm - OPFOR |
| `jmfsb_adsite_alarmIndependent` | LIST | Alarm - Independent |
| `jmfsb_adsite_alarmCooldown` | SLIDER | Alarm repeat (s) |

## Functions

<details><summary>26</summary>

- `jmfsb_adsite_fnc_aceActions`
- `jmfsb_adsite_fnc_actions`
- `jmfsb_adsite_fnc_alarm`
- `jmfsb_adsite_fnc_area`
- `jmfsb_adsite_fnc_assign`
- `jmfsb_adsite_fnc_burst`
- `jmfsb_adsite_fnc_family`
- `jmfsb_adsite_fnc_fire`
- `jmfsb_adsite_fnc_fired`
- `jmfsb_adsite_fnc_kill`
- `jmfsb_adsite_fnc_moduleSite`
- `jmfsb_adsite_fnc_plan`
- `jmfsb_adsite_fnc_posAt`
- `jmfsb_adsite_fnc_predict`
- `jmfsb_adsite_fnc_profile`
- `jmfsb_adsite_fnc_register`
- `jmfsb_adsite_fnc_resolve`
- `jmfsb_adsite_fnc_setMode`
- `jmfsb_adsite_fnc_setMute`
- `jmfsb_adsite_fnc_shot`
- `jmfsb_adsite_fnc_start`
- `jmfsb_adsite_fnc_status`
- `jmfsb_adsite_fnc_threat`
- `jmfsb_adsite_fnc_tick`
- `jmfsb_adsite_fnc_unregister`
- `jmfsb_adsite_fnc_vehicleInit`

</details>
