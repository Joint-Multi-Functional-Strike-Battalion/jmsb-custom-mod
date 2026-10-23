# BFT

`jmfsb_bft`

Blue Force Tracking. Every group that has its tracker on draws a marker on the
map for everyone entitled to see it, updated on a server-time tick so two people
looking at the same map see the same picture.

Entitlement is a NETWORK, not a side. A group transmits on a list of codes and
listens on another; a marker is drawn when one of the viewer's codes appears in
the target's transmit list. A group nobody has configured transmits on its own
side's name, so out of the box it behaves like a side tracker - and the moment a
mission calls `jmfsb_bft_fnc_networkAdd`, that group is off the side net and on
whatever nets it was given. Faded markers are the other half of that contract:
they mean you can see them and they cannot see you.

Position is deliberately not the truth. Tracking picks where the group is - the
leader, or an average pulled towards the rest of the group - and trailing decides
how far behind that the marker is allowed to lag, so a tracker reads like a radio
report rather than a live feed. All of it is drawn locally off group variables:
the update rate costs nothing on the network.

**The tracker switch is a property of the group, not of the man**, and that is
right — a group is what gets a marker — but it means the answer follows the group
you are in. Move into another group, get given your own team, slot somewhere
else, and you arrive in a group nobody has switched on: your marker vanishes and
the tracker looks broken while doing exactly what it was told. `autoEnable` runs
on CBA's `group` and `unit` player events as well as at start, so a group with no
answer gets the default one. A group whose visibility somebody *has* set — a
mission init field, its leader through the map menu, an admin — keeps it.

Group leaders own their own marker through ACE self interaction with the map
open - name, icon, colour, tracker on or off. A logged-in admin sees every group
regardless of nets, tracker state or side obfuscation, and drives the whole
system from chat with `#jmfsb bft.*`; `#jmfsb help` lists them.

Not jmfsb's design. This is **Jacco Douma's** BFT, ported over from Team
Collaboration Aides - see Credits.

## Admin commands

| Command | What it does |
|---|---|
| `#jmfsb bft.list [group\|side\|all]` | Tracker state, icon, colour and nets of every matching group |
| `#jmfsb bft.on <group>` / `bft.off <group>` | Force a group's tracker on or off |
| `#jmfsb bft.name <group> <new name>` | Rename a group |
| `#jmfsb bft.icon <group> <icon>` | Set its marker icon |
| `#jmfsb bft.color <group> <class>` | Set its marker colour, a `CfgMarkerColors` class |
| `#jmfsb bft.net add\|remove\|clear <group> [net]` | Nets the group transmits on |
| `#jmfsb bft.obs add\|remove\|clear <group> [net]` | Nets the group only listens to |
| `#jmfsb bft.view` | Toggle your own god view, to see what the players see |

The group token is a fragment of a call sign - `alpha` finds `B Alpha 1-1` - or
a side name (`west`, `east`, `guer`, `civ`), or `all`.

## Mission maker

Group variables, all public, all safe to set from an init field:

- `jmfsb_bft_visible` BOOL - tracker on
- `jmfsb_bft_type` STRING - `CfgMarkers` icon suffix, e.g. `"recon"`
- `jmfsb_bft_color` STRING - `CfgMarkerColors` class
- `jmfsb_bft_encryptCodes` ARRAY - nets it transmits on
- `jmfsb_bft_decryptCodes` ARRAY - nets it only listens to

The TCA names (`BFT_groupMarker_visible`, `_type`, `_color`) are NOT read here -
a mission written against TCA has to be renamed to these.

## Credits

**Jacco Douma** wrote this. The original is the `TCA_bft` addon of
[Team Collaboration Aides](https://github.com/Jaccodouma/TCA-A3) (TCA, by Jacco
& Hightower) - the tracker loop, the weighted-average and trailing position
model, the encrypt/decrypt network idea, the ACE map settings menu and every icon
in [ui/icons/](ui/icons/) are all theirs, carried over as they were.

TCA ships no licence file. It is here with attribution and nothing more: ask
before redistributing it further.

JMSB's part is the port and the plumbing around it:

- re-prefixed to `jmfsb_bft` on jmfsb's macros, settings categories and the
  `initSettings.inc.sqf` layout
- group variables renamed `BFT_groupMarker_*` -> `jmfsb_bft_*`
- `TCA_BFT_Interact_Icons` config class dropped; the icons are addressed
  directly with `QPATHTOF`
- the menu moved off the player object onto `CAManBase` with inheritance, so it
  survives respawn and unit switching
- markers named by index rather than by call sign - two groups can share a
  `groupId`, and `createMarkerLocal` returns `""` on a name already taken
- `mapSettings` was declared but never read upstream; it gates the menu here
- the unreachable `projected` trailing mode dropped
- the admin surface: god view, `#jmfsb bft.*`, gated on `jmfsb_common_isAdmin`
- **positions are GPS positions** (`jmfsb_ew_fnc_gpsOf`, when `jmfsb_ew` is
  loaded): a member dot is drawn where the man's GPS says he is - the false
  fix when spoofed, nothing when his GPS is denied, and your own dot reads
  "- GPS SUSPECT" while an anti-spoof set flags it; group markers are built
  from the members' GPS positions (a denied man counts at his true one)

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `ace_interact_menu` _(external)_
- `ace_common` _(external)_
- `cba_xeh` _(external)_

## Ships

22 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_bft_enabled` | CHECKBOX | Enable group markers |
| `jmfsb_bft_autoEnable` | LIST | Auto enable for |
| `jmfsb_bft_memberMarkers` | LIST | Member markers |
| `jmfsb_bft_memberVoiceRings` | CHECKBOX | Member voice rings |
| `jmfsb_bft_hideOwnGroup` | CHECKBOX | Hide own group marker |
| `jmfsb_bft_showVirtual` | CHECKBOX | Show virtual friendlies |
| `jmfsb_bft_updateDelay` | SLIDER | Update delay |
| `jmfsb_bft_markerShape` | LIST | Marker shape |
| `jmfsb_bft_trackingMode` | LIST | Position: tracking mode |
| `jmfsb_bft_trailingMode` | LIST | Position: trailing mode |
| `jmfsb_bft_trailingCount` | SLIDER | Position: trailing count |
| `jmfsb_bft_trailingWeight` | SLIDER | Position: trailing weight |
| `jmfsb_bft_mapSettings` | CHECKBOX | Map settings menu |
| `jmfsb_bft_nameOptions` | EDITBOX | Group name options |
| `jmfsb_bft_preferredIcons` | EDITBOX | Preferred icons |
| `jmfsb_bft_iconsBlacklist` | EDITBOX | Icons blacklist |
| `jmfsb_bft_preferredColors` | EDITBOX | Preferred colors |
| `jmfsb_bft_colorsBlacklist` | EDITBOX | Colors blacklist |
| `jmfsb_bft_fuzzOtherSides` | CHECKBOX | Obfuscate other sides |
| `jmfsb_bft_adminGodView` | CHECKBOX | Admin sees everything |

## Functions

<details><summary>22</summary>

- `jmfsb_bft_fnc_autoEnable`
- `jmfsb_bft_fnc_describeGroup`
- `jmfsb_bft_fnc_draw`
- `jmfsb_bft_fnc_drawMembers`
- `jmfsb_bft_fnc_findGroups`
- `jmfsb_bft_fnc_getGroupMarkerShape`
- `jmfsb_bft_fnc_getGroupPosition`
- `jmfsb_bft_fnc_init`
- `jmfsb_bft_fnc_isAdmin`
- `jmfsb_bft_fnc_loop`
- `jmfsb_bft_fnc_memberNumber`
- `jmfsb_bft_fnc_networkAdd`
- `jmfsb_bft_fnc_networkAddObserver`
- `jmfsb_bft_fnc_networkClear`
- `jmfsb_bft_fnc_networkClearObserved`
- `jmfsb_bft_fnc_networkRemove`
- `jmfsb_bft_fnc_networkRemoveObserver`
- `jmfsb_bft_fnc_remove`
- `jmfsb_bft_fnc_settingsAdd`
- `jmfsb_bft_fnc_settingsColors`
- `jmfsb_bft_fnc_settingsIcons`
- `jmfsb_bft_fnc_settingsNames`

</details>
