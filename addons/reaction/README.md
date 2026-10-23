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

SATCOM is exempt from radio detection, tested through ACRE's own antenna
connection rather than a flag jmfsb keeps. Under game voice (`jmfsb_voice`) a
key-up on the TEAM net, the vehicle intercom or direct speech never reaches the
filter at all; C2, A2G and calls do.

    #jmfsbreact    flag and cooldown counts, and whether you are flagged

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

1 unit class, 6 functions.

## Eden modules

### JMSB - Enemy Reaction

`jmfsb_moduleReaction`, category jmfsb_modules

Placing this module turns on enemy reaction. Without it, the system is off.<br>Hack Fail Chance (%) - Chance an intrusion fails outright Detection Chance (%) - Chance a failure, a drone sighting or a transmission is noticed Barrage Rounds Min - Fewest shells a major response puts down Barrage Rounds Max - Most shells Radio Watts Watched - Transmit power at or above which a radio can be direction-found

<details><summary>5 attributes</summary>

- `detectChance`
- `failChance`
- `roundsMax`
- `roundsMin`
- `watts`

</details>

## Functions

<details><summary>6</summary>

- `jmfsb_reaction_fnc_flagged`
- `jmfsb_reaction_fnc_major`
- `jmfsb_reaction_fnc_moduleController`
- `jmfsb_reaction_fnc_onTransmit`
- `jmfsb_reaction_fnc_radioInit`
- `jmfsb_reaction_fnc_roll`

</details>
