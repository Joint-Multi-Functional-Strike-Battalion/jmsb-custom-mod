# APS

`jmfsb_aps`

Active protection, 2040: Drongo's APS rebuilt inside this mod - no DAPS
dependency, no DAPS conflict - with a second effector on top, the **RF burst**
of `docs/rf_aps_2040_spec.json`.

**Hard kill.** Launcher-and-charge systems (Trophy / Afganit / GL-5 / Iron
Fist by side) that fly out and destroy incoming rockets, missiles and
submunitions thirty metres short of the hull; the enhanced fit kills tank rounds
on sight. Charges per side, a front-half-only BASIC fit at the bottom, rearmed
when the vehicle reloads its guns or parks by a supply. Top-attack dives above
the max angle and rounds above the size limit get through - that is the
counter. The launchers watch only while the vehicle is crewed with the engine
on; quiet, they look four times a second a little past their range, and once
anything is in the air near them, twenty times a second for three seconds
(code review P3, 2026-10-31).

**RF burst.** An omnidirectional high-power microwave pulse, automatic, with a
cooldown as its only resource. Guided munitions in the sphere lose their
guidance and fly on past; drones drop - own drones too, there is no IFF; every
radio in the smaller near field is jammed for a moment (the emitter's own crew
for less), sensors and datalink on every vehicle in that field go dark for the
same moment. Unguided rounds are immune by omission - the counter is to shoot
dumb, and to stagger attacks inside the cooldown.

**Who gets what is the faction's tier** (the same numbers the factions'
ammunition is built to):

| tier | tank | cannon IFV | other APC | MRAP | helicopter |
|---|---|---|---|---|---|
| 0-1 irregular | - | - | - | - | - |
| 2 near-peer | BASIC | BASIC | - | - | - |
| 3 peer | HEAVY + RF | MEDIUM | LIGHT | LIGHT | - |
| 4 peer+ | ENHANCED + RF | HEAVY + RF | MEDIUM + RF | LIGHT + RF | RF (as the DIRCM) |

Artillery, MLRS and mortar carriers carry nothing. The module can bend the
tier table (`faction:tier`) or name a class's fit outright (`class:FIT+RF`).

**APS arms itself from its settings; the module is an override.** A JMSB - APS
module bends the switches and the tier / fit tables, and it is applied whether
it runs before or after the settings armed the system - one that arrives second
refits every vehicle to its tables. The jam is a reference-counted registry
per client with a cue at each edge. The ACRE signal lever it drove (shared
with `jmfsb_jamming`) was removed on 2026-10-31 (DEC1); under game voice the
burst is the cue only.

**The map panel** (user, 2026-08-29: "a live panel to control APS on the map").
Registered with the tacpad shell when it is loaded, refreshed every two
seconds: one block per fitted vehicle the player is entitled to see - the one
they are in first, then the group's or the side's by distance, as **APS panel
scope** allows - with the fit, the charges by side, the emitter's state, and
three switches. **HK HOLD** stops the launchers firing; **RF HOLD** stops the
emitter firing on its own; **BURST** fires it now if it is live and off
cooldown. Holds are server state on the vehicle, so every crew, every panel and
the watch agree, and the HUD's APS tile shows them. They exist because the
burst jams every radio near the emitter and drops own drones - a section
flying a UAV or talking on the net wants the emitter silent until the missile
is real. Drone disabling is the spec's preferred
method and **untested per airframe** (blocker B1); the player-UAV disconnect
(B3) is deferred.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `cba_xeh` _(external)_
- `cba_settings` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

1 unit class, 25 functions.

## Eden modules

### JMSB - APS

`jmfsb_moduleAPS`, category jmfsb_modules

Placing this module turns on the APS, the active protection. Without it, the system is off.<br>Hard Kill - Launcher-and-charge systems that destroy incoming rockets and missiles short of the hull RF Burst - The microwave emitter: guided munitions lose guidance, drones drop, every radio nearby is jammed for a moment RF Burst On Helicopters - Peer+ helicopters carry the emitter as their DIRCM Tier Overrides - faction:tier pairs that bend the fit table for a mission Fit Overrides - class:fit pairs that name a vehicle's fit outright Debug - Log fits and intercepts, draw burst radii

<details><summary>6 attributes</summary>

- `debug`
- `fitOverrides`
- `hardKill`
- `rfAir`
- `rfBurst`
- `tierOverrides`

</details>

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_aps_enabled` | CHECKBOX | Active protection |
| `jmfsb_aps_maxAngle` | SLIDER | Max engagement angle |
| `jmfsb_aps_hitLimit` | SLIDER | Max round size (hit) |
| `jmfsb_aps_rearmRange` | SLIDER | Rearm range (m) |
| `jmfsb_aps_rearmDelay` | SLIDER | Rearm check (s) |
| `jmfsb_aps_defaultTier` | LIST | Default tier |
| `jmfsb_aps_panelScope` | LIST | APS panel scope |
| `jmfsb_aps_jmfsb_tacpad_apps_show_aps` | CHECKBOX | Show APS panel |
| `jmfsb_aps_tierOverrides` | EDITBOX | Tier overrides |
| `jmfsb_aps_rfRadius` | SLIDER | RF engagement radius (m) |
| `jmfsb_aps_rfFloor` | SLIDER | RF close floor (m) |
| `jmfsb_aps_rfClosing` | SLIDER | RF closing speed (m/s) |
| `jmfsb_aps_rfCooldown` | SLIDER | RF cooldown (s) |
| `jmfsb_aps_rfJamRadius` | SLIDER | RF jam radius (m) |
| `jmfsb_aps_rfJamDismount` | SLIDER | RF jam - dismounts (s) |
| `jmfsb_aps_rfJamCrew` | SLIDER | RF jam - own crew (s) |
| `jmfsb_aps_rfDamage` | SLIDER | RF emitter damage limit |
| `jmfsb_aps_rfProbDrone` | SLIDER | RF: quadcopter / FPV |
| `jmfsb_aps_rfProbLoiter` | SLIDER | RF: loitering munition |
| `jmfsb_aps_rfProbATGM` | SLIDER | RF: guided missile |
| `jmfsb_aps_rfProbIR` | SLIDER | RF: IR / laser guided |

## Functions

<details><summary>25</summary>

- `jmfsb_aps_fnc_arm`
- `jmfsb_aps_fnc_blackout`
- `jmfsb_aps_fnc_burst`
- `jmfsb_aps_fnc_burstNow`
- `jmfsb_aps_fnc_charges`
- `jmfsb_aps_fnc_deguide`
- `jmfsb_aps_fnc_disableDrone`
- `jmfsb_aps_fnc_fitFor`
- `jmfsb_aps_fnc_intercept`
- `jmfsb_aps_fnc_isGuided`
- `jmfsb_aps_fnc_jamRegister`
- `jmfsb_aps_fnc_jamTick`
- `jmfsb_aps_fnc_kill`
- `jmfsb_aps_fnc_moduleAPS`
- `jmfsb_aps_fnc_panelAps`
- `jmfsb_aps_fnc_panelList`
- `jmfsb_aps_fnc_popSmoke`
- `jmfsb_aps_fnc_rearm`
- `jmfsb_aps_fnc_refit`
- `jmfsb_aps_fnc_register`
- `jmfsb_aps_fnc_report`
- `jmfsb_aps_fnc_setHold`
- `jmfsb_aps_fnc_sweep`
- `jmfsb_aps_fnc_tierOf`
- `jmfsb_aps_fnc_watch`

</details>
