# Jamming

`jmfsb_jamming`

The jamming model: zones with a full-strength core and a falloff, one shared
calculator (`jamFactor`) that every consumer agrees with - radio degradation,
the device's jam readout, the scanner needle.

## Three domains, not one

A zone denies **radio**, **data**, **GPS**, or some combination, and every
consumer asks about the one it cares about rather than about "jamming":

| domain | what goes | who reads it |
|---|---|---|
| `radio` | the voice net - RF noise on VHF/UHF (game voice through `jmfsb_voice`) | `rfNoise`, `jammerLoop` |
| `data` | TAC//MSG traffic, and every group but your own off the map; RF noise on the DATA net's band | `messaging_fnc_linkState`, `bft_fnc_draw`, `rfNoise` |
| `gps` | the GPS item, and with it the map self-icon | `gpsApply` |

`any` is not a domain a zone can carry - it is the question the meter and the EW
scanner ask, meaning "is the spectrum dirty at all". A zone with no domains set
carries radio and data, which is what one emitter denied before the split, so an
untouched mission behaves exactly as it did.

`JAM_DENIED_BAND` is 0.75 and it is one number: it is where the handset says
DENIED, where the meter turns red, where the GPS comes off, and where keying up
counts as burning through rather than talking in a noisy place.

## The zones are RF noise

Jamming depends on `jmfsb_rf`. `fnc_rfNoise` is registered with
`jmfsb_rf_fnc_addNoiseSource` on the server, so every radio zone adds noise to
the VHF and UHF link budgets and every data zone to the band of RF's DATA net
(UHF - so on that band every net hears it). The strength is the module's
**Zone Noise at the Core (dBm)**, default -40, plus 10 log10 of the zone's
`jamFactor` at the receiver, before the receiver's spread gain: the zone's shape
in RF is exactly its shape on the meter. Game voice then degrades by link
quality in `jmfsb_voice`; this addon writes no voice variables. The direct
ACRE lever (`acreJam` and its custom signal function) was removed on
2026-10-31 (DEC1). GPS is not RF yet and stays here.

`jamFactor` itself is unchanged and still zone-based: the meter, TAC//MSG link
state, the scanner, burn-through and hacking read it as before. It answers for
the zones only - an RF noise source that is not a zone (the Drone40 Jammer) is
not in it.

## A site is three props

The **terminal** says what the site denies and IS the emitter - it holds the
zone, LOCATE JAMMER plots it, the hacking tower pool picks it up by classname,
and hacking or destroying it kills the denial permanently. An **omnidirectional
antenna** and a **satellite dish** stand beside it, rolled from three colours
each. They carry nothing; they are there so a site reads as a site from three
hundred metres out. Every site is registered with its commander through the
adapter, so ALiVE garrisons the thing it owns.

    RuggedTerminal_01_communications_hub_F   GPS     one on the map, ever
    RuggedTerminal_01_F                      data    the bigger objectives
    RuggedTerminal_01_communications_F       radio   the rest

## GPS is space-based

There is no mast over the ground it denies. One uplink on the whole map steers a
**1 km or 2 km sphere that wanders**, turning at the world edge, re-rolling its
heading every so often - weather rather than terrain. It is the one field a
player cannot walk out of and wait out, so the only answer is the uplink, which
is a findable, garrisoned, hackable objective like any other site. Kill it and
GPS comes back for good.

## Burning through

A set powerful enough to punch a hole in a radio field does so - and
`jmfsb_reaction` answers the transmission with the full reply and a QRF on the
transmitter, no detection roll. It is not something that might be noticed: it is
radiating hard, from inside ground somebody is spending an emitter to keep quiet.
Off by default until the module's **Radio Burn-Through** is ticked.

    #jmfsbjam    list live zones

Admins only, answered to the caller alone: it is `#jmfsb jam` on the admin
debug surface (review R1: it was a CBA event any player could raise to print
every zone's position in everyone's chat).

## On the terminal itself (ACE)

Two actions under a live terminal's own ACE menu (user, 2026-10-24: "the
jammers need to have a local ace interface to disable or hack"). **Disable
jammer**: an engineer, explosives specialist or ISR operator (a setting; or anyone) kneels
for the disable time (setting, 20 s) and the server removes the zone for good,
the same end as destroying or hacking it; the terminal is flagged so it is not
offered again. **Hack jammer**: an ISR operator who may hack puts the terminal
on the HACK board as the selected device and the board opens, on the tablet
where there is one; the hack runs there as any tower hack does. Nothing here
needs ACE to load the addon: without it there is no menu.

The disable reaches the server by `remoteExec` to `disableSite`, which takes it
only for the sender's own unit and runs the checks again: a live jammer, a man
allowed to disable it, within 7 m of it (review R1: it was a CBA event, so any
client could switch off any jammer from anywhere). The "site disabled" line
comes back through notify's broadcast, not a CBA event.

## For EW

`jmfsb_ew` reads the zones as emitters through `fnc_emitters` (id, object,
position, reach, domains, owner) and DFs every site; the GPS-only sphere has
no emitter on the ground and is left out. EW's GPS jammers lay their denial
here with `fnc_zoneOnObject` (a zone that rides an existing object, owner
tagged) and lift it with `fnc_removeZone`, so GPS denial stays this addon's
whoever fields the jammer.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `jmfsb_rf`
- `cba_xeh` _(external)_

Carries `skipWhenMissingDependencies` - the PBO is skipped rather than breaking the load order when something above is absent.

## Ships

2 unit classes, 28 functions.

## Eden modules

### JMSB - Jamming

`jmfsb_moduleJamming`, category jmfsb_modules

Placing this module turns on jamming. Without it, the system is off. It places no jammers - a JMSB - Jammer Site module does that, one per emitter.<br>Site Radius Min / Max (m) - every site rolls its own reach between the two GPS Denial - one uplink per commander steering a wandering 1-2 km GPS sphere Uplink Radius (m) - the uplink's own GPS field Radio Burn-Through - a strong set beats a jammer, and is answered with a QRF Burn-Through Reference (mW) - the set power the field is calibrated against Zone Noise at the Core (dBm) - what a radio or data zone adds to the RF link budget

<details><summary>7 attributes</summary>

- `burnRef`
- `gpsUplinkRadius`
- `largeRadius`
- `maxPerSide`
- `objectiveShare`
- `rfNoise`
- `smallRadius`

</details>

### JMSB - Jammer Site

`jmfsb_moduleJammerSite`, category jmfsb_modules

One jammer site, where you place it. Needs the JMSB - Jamming module on the map to arm.<br>Spectrum - radio, data or gps. One per site Radius (m) - 0 rolls one from the Jamming module's bounds Owner - whoever is hostile to the players, worked out from the mission's side relations<br>Artillery Reply - the site shells whoever loiters in its field Reply Delay (s) - how long a hostile must stay inside before it fires Reply Rounds / Scatter (m) - the size of the mission and how wide it falls Reply Cooldown (s) - minimum gap between two missions from this site

<details><summary>6 attributes</summary>

- `artyCooldown`
- `artyDelay`
- `artyRounds`
- `artyScatter`
- `domain`
- `radius`

</details>

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_jamming_disableTime` | SLIDER | Disable time (s) |
| `jmfsb_jamming_disableNeedsEngineer` | CHECKBOX | Disable needs a specialist |

## Functions

<details><summary>28</summary>

- `jmfsb_jamming_fnc_artyReply`
- `jmfsb_jamming_fnc_canDisable`
- `jmfsb_jamming_fnc_disableSite`
- `jmfsb_jamming_fnc_disableStart`
- `jmfsb_jamming_fnc_emitters`
- `jmfsb_jamming_fnc_getZones`
- `jmfsb_jamming_fnc_gpsApply`
- `jmfsb_jamming_fnc_gpsDrift`
- `jmfsb_jamming_fnc_hackStart`
- `jmfsb_jamming_fnc_isLiveJammer`
- `jmfsb_jamming_fnc_jamFactor`
- `jmfsb_jamming_fnc_jamHud`
- `jmfsb_jamming_fnc_jammerLoop`
- `jmfsb_jamming_fnc_moduleController`
- `jmfsb_jamming_fnc_moduleJammerSite`
- `jmfsb_jamming_fnc_productLocateJammer`
- `jmfsb_jamming_fnc_pruneJammers`
- `jmfsb_jamming_fnc_publishZones`
- `jmfsb_jamming_fnc_removeZone`
- `jmfsb_jamming_fnc_rfNoise`
- `jmfsb_jamming_fnc_spawnGpsUplink`
- `jmfsb_jamming_fnc_spawnJammerSite`
- `jmfsb_jamming_fnc_spawnObjectiveJammers`
- `jmfsb_jamming_fnc_spawnTempZone`
- `jmfsb_jamming_fnc_spawnZoneAt`
- `jmfsb_jamming_fnc_start`
- `jmfsb_jamming_fnc_zoneModel`
- `jmfsb_jamming_fnc_zoneOnObject`

</details>
