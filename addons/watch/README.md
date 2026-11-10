# Watch

`jmfsb_watch`

The watch HUD (`docs/DESIGN_WATCH_HUD.json`, decided 2026-11-07). Off by default.

A **profile** is a class or skill set: what it watches, its fields, its report. A **slot** is one watched target, 4 per profile. Other addons register profiles (`jmfsb_watch_fnc_register`); `jmfsb_medic` registers `medical`. This addon has `self_aid`.

## Keys

- **Action key, F9 (numpad 9 in the numpad layout):** look at a target (within 15 m) and press. It goes into the first profile you have that takes it. Press again on a watched target to take it off.
- **While a profile is on, the device keys are:** the arrows (F5 / F6) pick a slot, F1 reports it, F2 shares it (medical: onto every medic within 5 m), F3 all off, F4 squad view. A key with nothing to do stays the device's.
- **On the device:** six slots as tiles, 3 wide by 2 tall, the picked one lit; the key hints always on the bottom.
- **Beside the man:** the panel is centred on a shaded box, the EKG under it; hidden while the tablet (any dialog) or the map is up.

## What you see

- **World panel** beside the target, moving with him (profiles that draw one; medical needs the AiTR goggles). Full panel within 5 m, name and one value out to 15 m, beyond that a tag: slot number, state colour, one value (*Shrink at distance*). Nothing past 60 m.
- **Device panel** over the top of the walking view's map (side device or phone): the profile's icon and name, slots used, each slot's lines, the key hints. In *Full* prompt mode it shows "9: ADD TO MEDICAL" while you look at a valid target.
- **Key hints:** an icon per F-key - the report key's is the profile's own (med kit, binoculars...) - with the key as you bound it and its word in *Full* mode, the icon alone in *Reduced*. A key with nothing to do is dimmed.
- **Side device 2** shows a second watched profile; the current one stays on the side device, the phone and the tablets.
- **Tablets** (the vehicle tablet too): a WATCH panel with the same text while a profile is on.
- **Alerts** a profile raises (medical: T1, tourniquet over 10 min, SpO2 under 90, MIST stale) go through the notification row once when they start.
- **ACE self-interaction > Watch:** each slot's Report, Pin / Unpin, the profile's own actions (Map, Share, set triage), Clear, and All off.

## Settings

On the tablet, SETTINGS > WATCH HUD (and Addon Options): prompt mode, shrink at distance, auto-clear, self aid, squad view time, HUD on / off per profile (medical, team lead, engineer, recon contacts, JFO), the slot list (press: pin / unpin, <: clear), add a squad member without looking, and the action key as bound. HUD switches hide the drawing for you only. A server or mission that forces a setting locks it.

## Clearing

*Auto-clear*: a target that dies, or is lost past 300 m for a minute, comes off. Pinned slots stay.

## Self aid

*Self aid* setting: your own bleeding, pain, consciousness and tourniquets on the device panel. Everyone has it.

## Recon (everyone)

Look at an enemy man or vehicle and press 9. The server keeps the contact and checks line of sight once a second:

- **Any friendly has line of sight:** every friendly within 2 km sees a solid box (through AiTR goggles) and a map track.
- **Nobody has:** a dashed box and a hollow track at the last known position, with time lost - the spotter's group only.
- **Share** (ACE self > Watch): pushes a lost contact to every friendly within 2 km for *Share time* (20 s).
- **Map:** a permanent marker for everyone.
- Forgotten after *Drop lost contacts after* (5 min) without line of sight.
- Panel: in sight or lost, range and bearing, SPOTREP age. REPORT opens the SALUTE card filled in.

## Team lead (TL and ATL - the role's isLeader)

- 9 on a man of your own squad: name, health (DOWN, BLEEDING, HURT, OK), role, rifle magazines, AT and its rounds, distance and bearing, NO SIGNAL when he carries no device. Asked before medical, so 9 on your own man is this panel; his vitals stay on ACE > Show vitals (AiTR).
- **F4 squad view:** the whole squad on the device panel - role, name, status colour, magazines or NO SIGNAL - for *Squad view time* (30 s). F4 again hides it.

## JFO (isJFO)

Through the AiTR goggles, every live fire mission of your side: a ring on the ground the size of its sheaf (50 m at least), the shell, and the time to impact - IMPACT once due. From `jmfsb_support_fires`' impact areas. No slots, no device panel. Questions from support assets come to the device's answer strip as before.

## Engineer (ACE engineer or EOD)

- Panel header: your own charges - how many still out, how many armed, the nearest one's trigger and distance.

- Mines and explosives within *Engineer detect range* (15 m) that you did not lay are revealed to your side and become threat contacts - same visibility as recon. No detector needed.
- 9 on a mine: type, armed or safe, trigger (from its class: pressure, tripwire, remote, timed), distance. REPORT opens the UXO / IED 9-line, lines 1-4 filled.
- 9 on a friendly vehicle: damaged parts, fuel, ammunition, ACE cargo space, whether you carry a toolkit. REPORT opens the DEFREP.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `jmfsb_tacpad`
- `jmfsb_tacpad_apps`
- `cba_settings` _(external)_
- `cba_keybinding` _(external)_

## Ships

44 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_watch_prompt` | LIST | Prompt mode |
| `jmfsb_watch_shrink` | CHECKBOX | Shrink at distance |
| `jmfsb_watch_autoClear` | CHECKBOX | Auto-clear |
| `jmfsb_watch_shareSeconds` | SLIDER | Share time |
| `jmfsb_watch_dropMinutes` | SLIDER | Drop lost contacts after |
| `jmfsb_watch_detectRange` | SLIDER | Engineer detect range |
| `jmfsb_watch_squadViewSeconds` | SLIDER | Squad view time |
| `jmfsb_watch_hud_medical` | CHECKBOX | HUD: Medical |
| `jmfsb_watch_hud_team_lead` | CHECKBOX | HUD: Team lead |
| `jmfsb_watch_hud_engineer` | CHECKBOX | HUD: Engineer |
| `jmfsb_watch_hud_recon` | CHECKBOX | HUD: Recon contacts |
| `jmfsb_watch_hud_jfo` | CHECKBOX | HUD: JFO impact areas |
| `jmfsb_watch_selfAid` | CHECKBOX | Self aid |

## Functions

<details><summary>44</summary>

- `jmfsb_watch_fnc_actionKey`
- `jmfsb_watch_fnc_allOff`
- `jmfsb_watch_fnc_button`
- `jmfsb_watch_fnc_contactAdd`
- `jmfsb_watch_fnc_contactDraw`
- `jmfsb_watch_fnc_contactDrop`
- `jmfsb_watch_fnc_contactMark`
- `jmfsb_watch_fnc_contactMarkers`
- `jmfsb_watch_fnc_contactName`
- `jmfsb_watch_fnc_contactSeen`
- `jmfsb_watch_fnc_contactShare`
- `jmfsb_watch_fnc_contactTick`
- `jmfsb_watch_fnc_current`
- `jmfsb_watch_fnc_draw`
- `jmfsb_watch_fnc_engineerReport`
- `jmfsb_watch_fnc_engineerRow`
- `jmfsb_watch_fnc_goggles`
- `jmfsb_watch_fnc_hasSignal`
- `jmfsb_watch_fnc_health`
- `jmfsb_watch_fnc_hudDraw`
- `jmfsb_watch_fnc_hudOn`
- `jmfsb_watch_fnc_isEngineer`
- `jmfsb_watch_fnc_jfoDraw`
- `jmfsb_watch_fnc_leadRow`
- `jmfsb_watch_fnc_lookTarget`
- `jmfsb_watch_fnc_ownCharges`
- `jmfsb_watch_fnc_panel`
- `jmfsb_watch_fnc_panelText`
- `jmfsb_watch_fnc_profileFor`
- `jmfsb_watch_fnc_reconReport`
- `jmfsb_watch_fnc_reconRow`
- `jmfsb_watch_fnc_register`
- `jmfsb_watch_fnc_screen`
- `jmfsb_watch_fnc_selected`
- `jmfsb_watch_fnc_selfAidRow`
- `jmfsb_watch_fnc_selfMenu`
- `jmfsb_watch_fnc_settingsRows`
- `jmfsb_watch_fnc_slotShare`
- `jmfsb_watch_fnc_slotShared`
- `jmfsb_watch_fnc_squadView`
- `jmfsb_watch_fnc_threatScan`
- `jmfsb_watch_fnc_tick`
- `jmfsb_watch_fnc_toggle`
- `jmfsb_watch_fnc_trace`

</details>
