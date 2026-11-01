# Admin Panel

`jmfsb_adminpanel`

**This addon is licensed GPL-3. The rest of 1st Joint Multi-Functional Strike Battalion is APL-SA. Read the
licence section at the bottom before moving any file in this folder anywhere
else.**

An in-game admin console: who is on the server, where they are, what state they
are in, and the handful of things an admin has to be able to do about it without
leaving the mission - teleport, heal, spectate, Zeus, kick, ban, run code.

Ported from the admin panel that shipped inside the Task Force Roomba mission
framework, re-laid-out to the TAC//ADMIN design and wired to jmfsb's own theme
and settings.

## Getting in

Two keys, both under **1st Joint Multi-Functional Strike Battalion** in CBA's keybinds:

| Key | Opens |
| --- | --- |
| `Pause/Break` | The console, if you are an admin. Says so if you are not. |
| `Shift + Pause/Break` | The message box, which anybody may use to reach an admin. |

Also `#jmfsb admin.list`, `#jmfsb admin.me` and `#jmfsb admin.reload` - the usual
jmfsb admin chat surface, for finding out why the console will not open.

## The admin list lives in the MISSION

This is the one thing that had to change in the port. The panel used to
`#include` the mission's admin list at compile time, which an addon cannot do -
an addon is compiled once and then runs on every mission. It is read at runtime
instead, from either of two places.

**The recommended one: `CfgJmfsbAdmins` in `description.ext`.** Put it beside the
mission's other admin arrays so one edit covers all three:

```cpp
#define ADMINS     "76561198000002705", /* YonV  */     "76561198083000561"  /* Wobba */

enableDebugConsole[]      = {ADMINS};
cba_settings_whitelist[]  = {ADMINS};

class CfgJmfsbAdmins {
    admins[] = {ADMINS};
};
```

That is one list for the debug console, the CBA settings whitelist and this
panel, which is the point - two lists saying the same thing means one of them is
always out of date.

**The panel's original file still works too.** A mission that still has
`config\config_adminlist.hpp` needs no edit:

```sqf
_admins = [
    "76561198000002705", /* YonV */
    "76561198083000561"  /* Wobba */
];
```

`jmfsb_adminpanel_fnc_adminList` **runs** that file at mission start and reads
`_admins` back out - `call` writes into the caller's scope, which is exactly what
the old `#include` did. Same path, same variable, same comments.

Third, jmfsb's own admin flag (`jmfsb_common_isAdmin`, what `#login` sets) opens
the console as well, and so do the uids in `jmfsb_admin`'s own
`enableDebugConsole` list. The flag is a CBA setting - **JMSB admins may open
it** - and turning it off makes the mission's list the only way in.

A mission with no list at all is therefore not locked out: the host can still
open the console and grant access with **TOGGLE ADMIN**.

## On a tablet

In tablet mode, with a device open, the console (ADMIN on the tablet, or the
key), the message box and TIME / WEATHER open as their own dialogs but sized
and placed to the tablet's screen - the map area the tacpad draws in
(`jmfsb_tacpad_host`) - instead of the whole monitor (`fitHost`): every
control's safe-zone rectangle mapped onto that rectangle, type scaled with it.
The console is not drawn into the device: it is two hundred declared controls
driven by idc from the ported panel, a live map and a PiP camera. ESC closes
it back to the tablet. Its TAC//PAC button closes the console and opens
TAC//PAC inside the tablet (`openPac`).

## What is on the screen

**Left rail** - the player list with a filter over it, the four utility toggles
(godmode, infinite ammo, jmfsb, arsenal), the admin actions (spectate, Zeus,
kick, ban, lock server, role access, heal all), the mission ending picker, and
the message box.

**Centre** - the map, with a tab strip choosing what it puts trackers on:
players, vehicles, AI, or nothing but the mission's own markers. Teleport combos
are on the MAP label's tooltip. Underneath, the code box: a target strip
(SERVER / LOCAL / REMOTE - name), RUN, and a **RETURN** log.

**Header** - **TIME / WEATHER** opens a small dialog over the console: the
current date, time, speed of time and weather at the top; hour, minute and time
speed combos with DAWN / NOON / DUSK / MIDNIGHT shortcuts and **SET TIME**;
overcast, rain, fog and wind combos with CLEAR / CLOUDY / STORM / FOG presets and
**SET WEATHER**. Both go out as CBA events - time to the server, weather to every
machine with the server forcing the change through, ZEN's split - so no
`CfgRemoteExec` entry is needed. A weather module running in the mission (ALiVE's,
for one) moves the weather on again at its own next cycle.

**Right rail** - the live camera feed on the selected man with his grid, height
and heading under it; his info and skills; his vehicle and his medical state,
with three buttons under it: **STABILIZE** (2026-10-31) brings him to what
ACM's casualty conversion asks of the patient - bleeding stopped, 1 g of
Ertapenem IV when ACM requires antibiotics - and nothing more: he is not woken
or healed, and the medic's side of ACM's rule (skill, place, tickets) is
untouched; the answer names what was done, in red while he still bleeds.
**WAKE UP** and **HEAL FULL** are the panel's own.

## What changed from the mission version

Ported code is edited as little as possible so an upstream fix stays a re-copy
rather than a merge. These were not optional:

- **The admin list**, above.
- **`fn_isAdmin` took a unit and then tested `player`** - the local one. Every
  name in the list got the admin's own status, so one admin opening the console
  starred every row. It delegates to jmfsb's gate now, so there is one answer.
- **`MISSION_ENDBUTTON` and `ADMIN_SERVERHEALALL` shared idc 4941**, which is why
  the whole MISSION block was commented out upstream. END MISSION has a number of
  its own and works, behind a two-stage confirm.
- **Remote exec threw its return value away.** `compileAndExec` spawned the code,
  so nothing could come back; it calls it and sends the result to the console that
  asked. Code that needs to suspend spawns itself.
- **The three exec buttons each fired immediately**, so the only way to change
  your mind about the target was to have already sent it somewhere. They select
  now; RUN sends.
- **Four calls into the Roomba framework** (`YMF_fnc_player_getRank`,
  `player_setRankOverride`, `logToServer`, `toggleRoleGrant`) are guarded. With
  that framework loaded they behave exactly as before; without it the engine's own
  rank, the RPT, and a plain "this mission has no role gating" stand in.
- **The toggle plates were a hardcoded orange**, repainted ten times a second
  straight over whatever scheme the player chose. They read the theme.
- **Layout and skin.** The panel was a floating 0.57-wide box; this is the
  console in the mockup, painted from the tacpad's scheme, opacity and UI size.

Everything else - every action, every remote call, the camera, the markers, the
medical readout - is the original, under its original `admp_fnc_` tag.

## Server whitelisting

**Every server door checks the sender itself (2026-10-31, code review S1-S4).**
The code box, Zeus, GRANT ADMIN, rank, role access, TIME / WEATHER and STABILIZE
go to the server by `remoteExec`, and the server refuses a machine that is not
an admin by its own records (`jmfsb_common_fnc_senderIsAdmin`). Code for another
player's machine goes through the server, which checks and forwards it; a client
runs console code only from the server or itself. GRANT ADMIN is the server's
too (`fnc_adminGrant`): it needs the logged-in admin or the host, as before, and
only a grant made there can be taken back there.

**SECRETS (2026-10-31, code review R4).** `#jmfsb secrets` opens a small
dialog over the console for the voice server's API key and secret and the
database's connection string and service key. Each row's SET sends the typed
value to the server alone (`jmfsb_common_fnc_secretSet`; the logged-in admin or
the host only), which keeps it in its own profile, never publishes it, and
answers each row with SET and the last four characters or NOT SET. The field is
emptied after SET. An empty field and SET clears that secret. Used when the CBA
setting is empty (every setting reaches every player); the database string at
the next mission start. Not yet seen in game.

If your server runs a `CfgRemoteExec` whitelist rather than allowing everything,
these functions need to be on it:

- `admp_fnc_compileAndExec` - the code box, targeting client or server
- `jmfsb_adminpanel_fnc_execLog` - the return value coming back
- `admp_fnc_createZeusModule`, `jmfsb_adminpanel_fnc_adminGrant`,
  `jmfsb_adminpanel_fnc_envTime`, `jmfsb_adminpanel_fnc_envWeather`,
  `jmfsb_adminpanel_fnc_stabilizeLocal`, `jmfsb_adminpanel_fnc_stabilizeDone`
- `jmfsb_players_fnc_setRankOverride`, `jmfsb_groups_fnc_toggleRoleGrant`
- `jmfsb_common_fnc_adminClaim`, `jmfsb_common_fnc_debugRunServer`
- `jmfsb_notify_fnc_srvBroadcast`, `jmfsb_notify_fnc_notify` - the "X did this
  to you" lines

**The lines told to the man acted on (review R1)** go through notify's
`broadcast`, which a client's console sends to the server and the server posts
only for an admin. They were the notify post CBA event, which any client could
aim at anyone. STABILIZE's answer comes back from the patient's machine to the
server (`fnc_stabilizeDone`), which tells only the admin it kept for that
patient.

docs/SETUP.md has the whole mod's list.

JMSB does not ship a `CfgRemoteExec` of its own; that is the mission's or the
server's call, and it should be.

## Credits and licence

The panel is **JohnnyShootos'** work, edited by **TheTimidShade**, taken from the
mission framework it shipped in - which is licensed under the **GNU General
Public License v3**.

That licence travels with the code. It cannot be relicensed as APL-SA, so this
addon is **its own PBO with its own LICENSE beside it**, distributed alongside
1st Joint Multi-Functional Strike Battalion rather than dissolved into it. No file from this folder may be
copied into another jmfsb addon, and no APL-SA jmfsb code may be copied in here.

JMSB's additions in this folder - the console layout, the theme and scale, the
filter, the map tabs, the return log, the runtime admin list - are contributed
under the same GPL-3, because that is the only way they can sit in the same PBO.

See [LICENSE](LICENSE) for the full text.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `jmfsb_tacpad`
- `cba_xeh` _(external)_

## Ships

37 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_adminpanel_enabled` | CHECKBOX | Enable admin console |

## Functions

<details><summary>37</summary>

- `jmfsb_adminpanel_fnc_adminGrant`
- `jmfsb_adminpanel_fnc_adminList`
- `jmfsb_adminpanel_fnc_confirmEnd`
- `jmfsb_adminpanel_fnc_envApply`
- `jmfsb_adminpanel_fnc_envLoad`
- `jmfsb_adminpanel_fnc_envPreset`
- `jmfsb_adminpanel_fnc_envReadout`
- `jmfsb_adminpanel_fnc_envSelect`
- `jmfsb_adminpanel_fnc_envTime`
- `jmfsb_adminpanel_fnc_envTimeOf`
- `jmfsb_adminpanel_fnc_envWeather`
- `jmfsb_adminpanel_fnc_execClear`
- `jmfsb_adminpanel_fnc_execCopy`
- `jmfsb_adminpanel_fnc_execLog`
- `jmfsb_adminpanel_fnc_execRun`
- `jmfsb_adminpanel_fnc_execTabs`
- `jmfsb_adminpanel_fnc_execTarget`
- `jmfsb_adminpanel_fnc_filterList`
- `jmfsb_adminpanel_fnc_fitHost`
- `jmfsb_adminpanel_fnc_infoRow`
- `jmfsb_adminpanel_fnc_isAdmin`
- `jmfsb_adminpanel_fnc_mapCursor`
- `jmfsb_adminpanel_fnc_mapFilter`
- `jmfsb_adminpanel_fnc_mapTabs`
- `jmfsb_adminpanel_fnc_mapTargets`
- `jmfsb_adminpanel_fnc_open`
- `jmfsb_adminpanel_fnc_openDisplay`
- `jmfsb_adminpanel_fnc_openPac`
- `jmfsb_adminpanel_fnc_panelAdmin`
- `jmfsb_adminpanel_fnc_secretsLoad`
- `jmfsb_adminpanel_fnc_secretsSet`
- `jmfsb_adminpanel_fnc_secretsShow`
- `jmfsb_adminpanel_fnc_stabilize`
- `jmfsb_adminpanel_fnc_stabilizeDone`
- `jmfsb_adminpanel_fnc_stabilizeLocal`
- `jmfsb_adminpanel_fnc_style`
- `jmfsb_adminpanel_fnc_styleMessage`

</details>
