# HIMF

`jmfsb_faction_himf`

The Horizon Islands Defence Force, rebuilt on the base game by
`tools/gen_himf.py` after Atlas left the load order: NATO Pacific bodies with
Tanoan identities, vehicles matched by job, the old HIMF's twenty groups role
for role.

hats, seven Modular Carrier rigs. Nothing is vendored and no class of ours sits
in the chain, which is the difference between this and everything that came
before it: the kit is a mod's, not a texture set built into ours.

| | |
|---|---|
| line | Combat Uniform, HBK helmet, Modular Carrier Lite / Combat |
| leaders | HBK with headset, Command rig (squad leader) or GL rig (team leader) |
| recon | the Shirt and Tee uniforms, CQB rig, HBK by role |
| marksman, medic, EOD | Booniehat, Tactical rig |
| radio | Booniehat with headset |
| aircrew | Heli Pilot Helmet, Pilot Helmet for fixed wing, Compact vest |
| crew | ear-protector HBK - the list has no vehicle-crew helmet, and that is the nearest thing in it to hearing protection in a hull |

Every one of the nineteen is issued to at least one man.

each man's `uniformClass` and `linkedItems[]`, never inherited from, so the
and leaning on `skipWhenMissingDependencies` would remove the entire faction
instead, which is worse than a faction in the wrong trousers. The JTFs, which

**What is still ours.** The rucksacks, facewear and the whole French CE
wardrobe are still built and still in the arsenal - `UNIFORMS`, `HEADGEAR`,
`VESTS`, `BACKPACKS` and `FACEWEAR` in the generator, on `data/`'s vendored
those are unchanged and the men still carry them.

The previous state - HIMF dressed head to toe in French CE - is preserved at
`backup/himf_frce_2026-08-29/`, with instructions for putting it back.

**Also HIMF's own**, none of it borrowed: the faction and group lists, the
Tanoan identities and flag, the vehicle roster and its crewing, the drone bags,
and the XMS rifle presets and the marksman's Mk-I EMR in `CfgWeapons.hpp`.

**Re-armed and re-kitted 2026-10-06** (the FAMAS was removed from jmfsb): base-game Mk20s
in camo - Mk20 on the line, Mk20C on recon, Mk20 GL for the grenadiers and team leaders - on
base-game STANAG tracer ammo; the Zafir 7.62 as the machine gun. Every ground man wears the
user's kit: JAM's tigerstripe special fatigues, JCA's olive KBT combat rig, jmfsb's green canvas
helmet and ADF Re-Cut's Kondor goggles (put on by an init handler - a unit config cannot pin
facewear). Pilots, helicrew and tank crew keep their own kit. What follows is the earlier history.

**On Atlas's own HIMF since 2026-08-29** (user: "himf move back to the uniforms
in the aegis himf - uniforms and weapons"). Every man inherits from the matching
`Atlas_B_H_*` class - uniform, vest, helmet, rifle (M16A4 on the line, XMS on
the commandos) and pack are Atlas's by link, nothing copied. Ours on top: the
Tanoan identity, the FA tier-2 round wherever the index knows the magazine, the
squad drones, and the vehicles already settled: the EMB 312 mod's AT-27M35
Tucano in grey and Atlas's HIMF Caesar BTT as the only planes (user, 2026-08-29),
the Hummingbird, Pawnee, RF Hellcat and Atlas's own HIMF EC-04 / EC-03
helicopters (the EUDF Wildcats went with EUDF35), RF Ram 1500s, EF Gyras, and
no APC beyond EF's two Gyras (Atlas's Otokar ARMAs
came out on 2026-08-30 at the user's request).
Atlas's characters addon is a real dependency; without it the PBO is skipped.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_uniform`
- `jmfsb_vehicle`
- `jmfsb_weapons`

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

63 unit classes.
