# Leaders

`jmfsb_leaders`

The asymmetric chain: **three leaders, and only a player's hand takes one off
the board.** A leader lost to crossfire, a mine or ALiVE's own war is quietly
replaced - a successor stands up in a new safe house, and the corpse stops
carrying the phone. A kill nobody earned must not end a hunt nobody got to
run.

They live in safe houses - enterable buildings in settlement clusters inside
the asymmetric commander's TAOR - and rotate between them. Intel points at the
**safe house, never the man**, and once he is moving it points at the house he
is going to, so the chain is followed rather than solved. A house may be
watched: walk in and 3-4 mortar rounds arrive. (IEDs stay ALiVE's.)

**Take one alive** and deliver him to a `jmfsb_prison*` marker and he gives up
another leader's position exactly - the only moment the chain hands over a
point instead of a circle, and it costs a live prisoner rather than a hack.

Killing or capturing one cuts the asymmetric pool by the slider, and the state
survives a restart.

**Without ALiVE (2026-11-02)** the placed module stands for the asymmetric
commander: the chain belongs to the mission's enemy - or to the side of a man
synchronised to the module, whose faction the leaders then wear (else the one
that side's men on the map wear). Safe houses and pops are in the map's own
towns, inside the module's TAOR field or the `jmfsb_taor_<side>` markers when
set. Nothing to persist into, so a restart brings all three back. Built, not
seen in game.

    #jmfsbleaders    who is left, where, and in what state

Admins only, on a dedicated server too; the answer goes to the admin who typed
it, nobody else. Same as `#jmfsb leaders`.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

1 unit class, 16 functions.

## Eden modules

### JMSB - Leader Chain

`jmfsb_moduleLeaders`, category jmfsb_modules

Placing this module turns on leader chain. Without it, the system is off.<br>Without ALiVE: the mission's enemy is the insurgent side (or the side of a man synchronised to this module, whose faction the leaders wear), safe houses are in the map's towns, inside TAOR Markers or jmfsb_taor_west / _east / _guer markers when set.<br>Pool Cut Per Leader (%) - How much of the asymmetric commander's force pool dies with each leader Rotate Every (sec) - How often a leader moves to another safe house Trap Chance (%) - Chance a watched safe house is trapped with mortars Internet Pops - How many rugged-server props are placed for players to find and pull leads from

<details><summary>5 attributes</summary>

- `poolCut`
- `pops`
- `rotateEvery`
- `taor`
- `trapChance`

</details>

## Functions

<details><summary>16</summary>

- `jmfsb_leaders_fnc_armTrap`
- `jmfsb_leaders_fnc_arrive`
- `jmfsb_leaders_fnc_down`
- `jmfsb_leaders_fnc_leaderCar`
- `jmfsb_leaders_fnc_moduleController`
- `jmfsb_leaders_fnc_parkSpot`
- `jmfsb_leaders_fnc_placePops`
- `jmfsb_leaders_fnc_prisonWatch`
- `jmfsb_leaders_fnc_productLeader`
- `jmfsb_leaders_fnc_replace`
- `jmfsb_leaders_fnc_reveal`
- `jmfsb_leaders_fnc_rotate`
- `jmfsb_leaders_fnc_safeHouses`
- `jmfsb_leaders_fnc_save`
- `jmfsb_leaders_fnc_spawnLeader`
- `jmfsb_leaders_fnc_start`

</details>
