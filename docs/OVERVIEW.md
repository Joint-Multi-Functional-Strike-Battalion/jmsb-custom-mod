# What is in this mod

Hand-written overview, 2026-08-15. **Not generated** - `tools/gen_docs.py` does
not touch this file. For the exact per-addon detail see the generated
[ADDONS.md](ADDONS.md), [MODULES.md](MODULES.md) and [SETTINGS.md](SETTINGS.md);
this page is the plain-language answer to "what does jmfsb actually add".

## Command and control (the tablet suite)

- **TACPAD** - the map-screen app shell: live tiles, panels, colour schemes, settings
- **TAC//SUPPORT** - ALiVE combat-support tasking (transport / CAS / artillery)
  with an embedded map, parameter steppers, GUNS control, SITREP and RTB
- **Messaging** - the cTab replacement: threads, nets, 13 report templates,
  composer and reader
- **BFT** - blue-force tracking with trails, icon and colour rules, per-side fuzzing
- **TAC//ADMIN** - ported admin panel (the one GPL-3 addon in the mod)
- Supporting UI: HUD, map tools, notifications, chat, spectator, killtracker,
  main menu, loading screen

## Battlefield systems (one Eden module each)

- **ALiVE adapter** - the only addon allowed to know ALiVE's internals;
  everything else asks it
- **Enemy drones (uas)** - profiled and live patrols over objectives, supply
  caches that thin the fleet when raided, sighting hooks into the reaction ladder
- **QRF** - objective capture detection, answered with artillery, drones and
  infantry waves from the hostile commander
- **Reaction ladder** - hacks, drone sightings and radio transmissions roll one
  detection: a silent flag first, the full reply on the retry
- **Leader chain** - asymmetric network of leaders in safe houses, rotating by
  car, finite once players spend them; trapped houses, internet pops, prison delivery
- **Hacking / intel economy** - towers, phones, wrecks, remote net breaks, and
  the intel products they buy (locate AA, artillery, caches, radars, TRACE NETWORK)
- **Jamming / EW** - zones that degrade game voice (through RF) and ACRE, held up by destructible emitters
- **Air defence** - sited AA batteries and MANPAD teams inside TAORs
- **Anti-ship** - coastal Burevestnik batteries with radars, decoys and rearm
- **Ambience** - ambient artillery shelling and one-way kamikaze drones near players
- Plus insurgents, remote sensors, task helpers, Zeus/curator tools and a shared
  module toolbox

Every module spawn passes the shared side/TAOR gate
(`jmfsb_common_fnc_taorGate`), so nothing stands up on the wrong side's ground.

## Gameplay

- **Medic evac** replacing respawn: the medic heals the real player onto
  themselves and leaves an injured AI clone behind
- Medical additions, medbags, respawn handling, back-to-game
- Towing, vehicle repair and rearm pads, boarding, patrol-base building,
  satcom masts, naval bits
- Fatigue, AI disembark, friendly-fire logging, hit effects, safe start, safe
  grenades, prone launcher, pointing, tagging, backpack-on-chest, VS-17 panels,
  difficulty presets, UI tweaks, debug console, and grass / NVG / flares / smoke
  / ballistics tweaks

## Gear and content

- Weapons (ported MX family, JCA sets) and optics, including the EF/XM157
  fire-control graft
- Uniforms (EU, SOF), vests (Aegis, EFA, JCA, SOF, WS, Odin), helmets, faces,
  flags, backpacks
- Signs, icons, media and the 2035 motor pool content

## State of it

- The UI suite and the gear are the most exercised parts
- **Most battlefield systems are code-complete but barely tested in-game** -
  treat first runs as tests, and read the RPT
- The 2026-08-15 full-mod audit fixed roughly 25 verified bugs, including two
  systems that were entirely dead (jamming's model knobs, equipment's init gate)
  and several multiplayer-only failures that solo hosting cannot reveal
- Faction addons are archived and frozen; they are not part of the active set
