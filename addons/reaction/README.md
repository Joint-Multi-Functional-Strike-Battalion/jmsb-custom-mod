# Reaction

`jmfsb_reaction`

The one consequence path. A failed hack, a drone that actually saw you, and a
transmission over the wattage threshold all roll the same degrees:

* **nothing** - and it is never announced. A system that reports its own
  passes teaches players to read the chat instead of the ground.
* **SMALL** - a *silent* flag. You are not told. Walk away and it decays;
  try again and your fail *and* detect chances are trebled.
* **MAJOR** - shells asked of the hostile commander's own guns, a drone sent
  to look (out of that side's cache-limited ceiling), and every AI within a
  few hundred metres told where you are.

Under game voice (`jmfsb_voice`) a key-up on the TEAM net, the vehicle
intercom or direct speech never reaches the filter at all; C2, A2G and calls
do, counted as 5 W. The ACRE watch (its set's power, the SATCOM antenna
exemption) was removed on 2026-10-31 (DEC1).

    #jmfsbreact    flag and cooldown counts, and whether you are flagged

Admins only, on a dedicated server too; the answer goes to the admin who typed
it, nobody else. Same as `#jmfsb react`.

## Counter-battery (2026-10-25)

**Player-crewed guns only** (user: "we need an exception not to counter-battery
AI arty", then "player side virtual are the exception"). A player-crewed gun
firing counts (ACE's `ace_firedPlayerVehicle`, raised only on the player
gunner's machine, on a vehicle with an artillery computer). The players'
virtual artillery - the support batteries - and AI artillery never do.
After *Rounds To Fix* inside the *Fix Window* the enemy rolls *Chance*; a hit
answers *Delay Min-Max* seconds later on where the guns were at the fix - the
hostile commander's guns if one can be asked, else a virtual 155 mm barrage,
no TAOR gate (counter-battery's job is to reach into the base). The crew are
warned INCOMING when it is fired (*Warning*).

**The other way round, the radar - all enemy shells.** When enemy artillery
fires - an AI gun, or any virtual barrage (`jmfsb_common_fnc_fireBarrage`
runs its `onBarrage` hooks; every caller is enemy fire) - every player side
hostile to it that has an artillery team - a squad whose ORBAT kind (its map
icon on the squad's row) is `art` or `mortar` - gets a TAC//MSG thread from CB
RADAR to that squad, pinned on the map: the gun's grid within *Radar Error*
metres. A virtual barrage has a virtual battery 3-7 km from where it lands,
kept for that area so the next barrage comes from the same place. One report
per gun or battery per *Radar Cooldown*. No popup of its
own - the message is the notice (user: "no new notification system, just a
message"). The fix also feeds the team's ARTY tile and calculator
(jmfsb_tacpad_apps). All of it is on the Enemy Reaction module.

**Who may raise it (review R1).** No CBA events: any client could raise one
naming anyone. A client reports its own player (a key-up, a failed hack) by
`remoteExec` to `report`, which takes only the sender's own unit and the
sources radio, burnthrough and hack. A player's gun firing goes to `cbShot`,
which takes only the sender's own unit crewing that artillery piece, one shot
per call. An AI gun firing goes to `cbRadar` from the machine that holds the
gun. The server's own sources (drones, DF fixes, a remote hack's failure)
call `roll` directly.

**Without ALiVE (2026-11-02)** the mission's enemy answers a MAJOR and a
counter-battery (virtual barrage, drone if the UAS addon is loaded), the town's
hostility leaves the roll as set, and "has your position" comes from the
hostile side's own `knowsAbout` the man (3 or better) instead of ALiVE's COP.
Built, not seen in game.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

1 unit class, 12 functions.

## Eden modules

### JMSB - Enemy Reaction

`jmfsb_moduleReaction`, category jmfsb_modules

Placing this module turns on enemy reaction. Without it, the system is off.<br>Hack Fail Chance (%) - Chance an intrusion fails outright Detection Chance (%) - Chance a failure, a drone sighting or a transmission is noticed Barrage Rounds Min - Fewest shells a major response puts down Barrage Rounds Max - Most shells Radio Watts Watched - Transmit power at or above which a radio can be direction-found<br>Counter-battery - player-crewed guns only; the players' virtual artillery (support batteries called by message) and AI artillery never: Chance (%) - 0 turns it off. Rounds To Fix and Fix Window - how much fire the enemy radar needs Delay Min / Max (s) - when the answer lands, on where the guns were. Rounds, Spread - the answer Cooldown (s) - per gun. Warning (1/0) - INCOMING to the gun crew

<details><summary>17 attributes</summary>

- `cbChance`
- `cbCooldown`
- `cbDelayMax`
- `cbDelayMin`
- `cbRadar`
- `cbRadarCooldown`
- `cbRadarError`
- `cbRounds`
- `cbShots`
- `cbSpread`
- `cbWarn`
- `cbWindow`
- `detectChance`
- `failChance`
- `roundsMax`
- `roundsMin`
- `watts`

</details>

## Functions

<details><summary>12</summary>

- `jmfsb_reaction_fnc_cbFire`
- `jmfsb_reaction_fnc_cbRadar`
- `jmfsb_reaction_fnc_cbReport`
- `jmfsb_reaction_fnc_cbShot`
- `jmfsb_reaction_fnc_cbVirtual`
- `jmfsb_reaction_fnc_flagged`
- `jmfsb_reaction_fnc_major`
- `jmfsb_reaction_fnc_moduleController`
- `jmfsb_reaction_fnc_onTransmit`
- `jmfsb_reaction_fnc_radioInit`
- `jmfsb_reaction_fnc_report`
- `jmfsb_reaction_fnc_roll`

</details>
