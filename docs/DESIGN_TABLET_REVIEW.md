# DESIGN_TABLET_REVIEW — tablet apps, review 2026-11-01

Build handoff. Fix list from a screenshot review of the large tablet
(JMSB Night, TABLET mode). Planning spec, not code. TAC//SUPPORT is out of
scope here; it has its own doc, `DESIGN_SUPPORT_V2.md`.

Screens reviewed: TAC//MSG, map with panels, DRONES (Fleet, Enemy), JAMMER,
WEATHER, TIMER, RADIO (Nets, Calls, Manage).

Function names below are where I expect the code to be, from the addon READMEs.
If a name is wrong, find the real one and say so; do not create a new file to
match this doc.

Items marked **OPEN** need a user decision. Ask, do not guess.

---

## 1. Fix order

| # | Item | Section |
| --- | --- | --- |
| 1 | Remove developer text from player UI | 2.1 |
| 2 | Solid ground under apps | 2.2 |
| 3 | Filter air defence out of DRONES | 3.3 |
| 4 | Label/value layout | 2.4 |
| 5 | Frame key labels match numpad 6–9 | 2.5 |
| 6 | Everything else, by screen | 3 |

Each item stands alone; ship them one at a time.

---

## 2. Shell-wide

### 2.1 Developer text in the player UI

Player-facing strings that are notes to developers or internal ids:

| Where | Text now | Fix |
| --- | --- | --- |
| RADIO › Calls, under contacts | "While a call is live, + ADD rings that person into it. ADD TO CALL on the map or the squad list is not built." | Keep the first sentence. Drop "… is not built." |
| RADIO › Calls, callbacks | "… Cancelling one is not built." | Drop the sentence. |
| TAC//MSG header | "BANSHEE 1-1 VANILLA - TASK_FOR" | Show the group callsign only. `TASK_FOR` is an internal value. |
| Notification line | "Loadout kept for teamleadBanshee (3 of 3)" | Use the role's display name, not its class name. |

Rule for all apps: no "not built", "TODO", class names or variable names in a
drawn string. Grep the `tacpad_apps`, `devices`, `pac`, `ew`, `jamming` and
`hacking` functions for `not built` and fix every hit that reaches the screen.
Text that explains a missing feature belongs in the README, not the UI.

### 2.2 Solid ground under apps

WEATHER, TIMER and JAMMER draw over the map with the map showing through.
Panels may be translucent (`opacity` setting); apps must not.

- `appFrame` (tacpad) fills the app body with `ground` at alpha 1, whatever
  `jmfsb_tacpad_opacity` says.
- Check every app uses `appFrame` for its body. Any that fills its own ground
  with the panel opacity: switch it.

### 2.3 Type and letter tracking

- Letter tracking (the spaced-glyph trick in `drawText`) only on short labels:
  column headers and section titles of 12 characters or fewer.
- Never track names, callsigns, grids or values. Examples to fix:
  "B A N S H E E 1 - 1 V A N I L L A" in the reader chip and in RADIO › Manage.
- Minimum drawn size for body text and values: the current label size + 1 step.
  **OPEN:** exact size, depends on `textScale` default. Proposal: values at
  the tile detail size, never smaller.

### 2.4 Label/value layout

WEATHER and DRONES › Enemy draw a label at the far left and its value at the
middle of a full-width row: about 600 px of travel per line.

- Key/value lists: label column width = its longest label + padding; value
  starts right after it.
- On a wide app, split the list into 2 or 3 columns instead of stretching.
- One shared helper for key/value rows so every app does it the same way.
  **OPEN:** extend `fnc_row` or add `fnc_kvRow`.

### 2.5 Frame keys vs binds

The binds are numpad 6 / 7 / 8 / 9 for the device keys (RADIO › Nets › KEYS
shows "6 [NUM] 7 [NUM] 8 [NUM] 9 [NUM] — device keys F1 F2 F3 F4"). The frame
art still prints F1–F4.

- Label the frame keys with what the player presses. Options:
  (a) regenerate the frame textures with 6 / 7 / 8 / 9 (`tools/gen_devices.py`
  inputs in `art/devices`); (b) draw the key label over the art at runtime from
  `CBA_fnc_getKeybind`, so a rebind shows the real key.
  **OPEN:** (a) or (b). (b) follows rebinding; (a) is simpler.
- Same for the arrow keys (0 / .).
- Rename the setting labels "F1 key on the tablet opens" → "Device key 1 opens",
  so the setting doesn't name a key the player doesn't use.

### 2.6 Bottom strip

When the player is on no net, the net row shows only "NO VOICE NET" in a
~40 px strip.

- Draw the net row as usual with one dim cell reading `NO NET`. Same height,
  same place, so the row doesn't change shape when a net appears.

### 2.7 Small consistency fixes

| Item | Now | Fix |
| --- | --- | --- |
| DRONES tile kicker | "DRON" (cut) | Fit "DRONES": shrink the qualifier chip, or kicker min width = 6 glyphs. |
| PAC tile | Kicker larger than other tiles; detail "NO OPORD -" | Same kicker size as all tiles; drop the trailing " -". |
| Grids | 6 figures on DRONES › Enemy, 8 in the header | Use `jmfsb_devices_gridDigits` everywhere a grid is drawn. |
| Alert colour | DRONES tile uses a red qualifier fill and red value text | Alert = inverted accent block per the tile state rules (`tileData` header comment). Red only where the theme allows fixed status colours (squad health, net reachability). **OPEN:** confirm, since red reads well here. |
| Reader count | "1 NETS" | Plural only when count ≠ 1. Check every count label. |

---

## 3. Per screen

### 3.1 TAC//MSG (`fnc_appComms`, tacpad reader)

| Issue | Fix |
| --- | --- |
| Net list has a 3-letter prefix column (C2., FIR, MED, BAN) | Drop the column. Show sub-nets indented under their parent: `FIRES` then `  cas`, `  arty`, `  trans`. |
| Quick replies (ROGER, WILCO, WAIT ONE, SMOKE OUT, LZ SECURE) show with no thread open | Draw them only when a thread is open, and only those the thread accepts (already the rule in the docked reader). |
| "SEND TO C2" while ALL is selected | With ALL selected there is no send target: hide the send row, or show "pick a net to send". |
| Three ways to start a message: NEW (top), + TEMPLATE, + MESSAGE (bottom) | Keep NEW at the top. It opens compose with the template picker one press away. Remove + MESSAGE; keep + TEMPLATE only inside an open thread (a reply with a card). |
| Two empty states side by side ("NO TRAFFIC" in the list, "NOTHING ON THIS NET" in the thread pane) | List shows "No traffic on <net>"; thread pane shows nothing until a thread is picked. |

### 3.2 Map with panels (tablet)

| Issue | Fix |
| --- | --- |
| SQUAD panel is full height with one man in it | Panel height = rows needed + legend + REFRESH. `fnc_fit` should already do this; check the tablet path (`TABLET_PLACES`) isn't forcing the height. |
| Panels cover ~45% of the map | After the SQUAD fix, recheck. **OPEN:** collapse MAP TOOLS to one row (tool icons) until a tool is opened. |
| MAP TOOLS grid has an empty cell | Fill the grid or reflow so no hole is drawn. |
| Reader "1 NETS" | See 2.7. |

### 3.3 DRONES › Fleet (`fnc_appDrones`, `fnc_appDronesFleet`)

| Issue | Fix |
| --- | --- |
| Lists air-defence systems (ADS-1 NASAMS, ADS-2 Skynex, AN/MPQ-64 Sentinel) as drones | Fleet = UAVs a player can fly or task. Exclude air defence. **OPEN:** filter rule — by `vehicleClass` / simulation (air only), by an exclude list, or by `jmfsb_adsite` registration (anything `adsite` registered is not a drone). Proposal: exclude anything `adsite` registers, plus non-air UAV-class vehicles. |
| Every row reads NO RF, empty quality bar, "-" | When nothing has a link, one line: "No drone in data link range" and the rows without the link columns. |
| "Only the UAV operator flies drones." in a tiny footer | Put the reason on the dead buttons: CONNECT shows the `uavCan` reason as its label or under it. |
| "CONTROL NEEDS DATA LINK" drawn twice (tab bar and feed header) | Once, in the feed header. |
| Selected row not obvious | Selected row: ink fill (selected state). |

### 3.4 DRONES › Enemy (`fnc_appDronesEnemy`)

| Issue | Fix |
| --- | --- |
| One contact as a full-width key/value list | Draw a bearing scope: own position in the centre, range rings, contact at its bearing and range, airframe label on it. Key/values beside it per 2.4. **OPEN:** scope, or the contact pinned on the map behind. |
| Grid 6 figures | See 2.7. |

### 3.5 JAMMER (`fnc_appJamming` / EW app)

| Issue | Fix |
| --- | --- |
| "No jammer" said three times (title, bottom left, bottom right) | Once, in the title area, with the one action line ("Crew a vehicle with an EW jammer module in its cargo"). |
| Spectrum chart small, lots of empty space | Chart takes the full width of the right column, at least 2× current height. |
| Map shows through | See 2.2. |

### 3.6 WEATHER (`fnc_appWeather`)

| Issue | Fix |
| --- | --- |
| LOCAL TIME reads "DAY" | Show the time (`HH:MM`); DAY/NIGHT goes in the header qualifier as on the tile. |
| Full-width label/value rows | 2.4: two columns — conditions (cloud, rain, fog, wind, visibility) and light (local time, first light, last light, moon, date). |
| ROTARY / THERMAL verdicts at the bottom | Move them up, under the condition header; they are the reason a player opens the page. |

### 3.7 TIMER (`fnc_appTimer`)

Now: three ways to arm (preset minutes 1/2/3/5/10, CUSTOM ±, ALARM AT ±), and
it isn't clear whether a preset press arms straight away.

New layout:

```
ARMED ALARMS        (list, soonest first, DEL #n)
───────────────────────────────────────────────
[ IN ] [ AT ]        mode toggle
  -10  -1  [ 15:00 ]  +1  +10  +60     one stepper; presets 1 2 3 5 10 set it
[ ARM ALARM ]                          one button, says what it will do:
                                       "ARM · IN 15:00" / "ARM · AT 04:30 (16:28:47)"
───────────────────────────────────────────────
STOPWATCH   00:00     [START] [RESET]
```

Presets only set the stepper; ARM arms. One button arms, always.

**Reverted (user, 2026-11-01).** Built, then rejected: "the stop watch app is
weird what is this in and at stuff". The user chose "old timer but better
visual design". The timer is back to the old controls: quick keys 1/2/3/5/10
that arm on the press, CUSTOM ± with its own ARM, ALARM AT ± with its own ARM,
the armed alarms list, the stopwatch. The IN / AT toggle and the one stepper
are gone. The new drawing:

```
ARMED ALARMS                          [RINGING - SILENCE]
     12:40   #1  04:30  SMITH                    [DEL #1]
──────────────────────────────────────────────────────────
SET AN ALARM
    ARM IN   [1 MIN] [2 MIN] [3 MIN] [5 MIN] [10 MIN]
    CUSTOM   15:00
             (-10) (-1) (+1) (+10) (+60)
             [ARM IN 15:00]
  ALARM AT   04:30
             (-1H) (-10) (-1) (+1) (+10) (+1H)
             [ARM AT 04:30 - IN 16:28]
──────────────────────────────────────────────────────────
STOPWATCH
     READY   00:00
             [START] (RESET)
```

- A label column and a control column down the whole page.
- Filled keys arm. Outlined keys only change a value.
- Every key the same height. Values at the tile detail size or larger (R1),
  never letter-tracked.

### 3.8 RADIO › Nets (`fnc_appRadioNets`, `fnc_appRadioSounds`)

| Issue | Fix |
| --- | --- |
| Left half is "You are on no voice net." and nothing else | Say why and what to do: no set carried / not on a plan net / voice addon missing, whichever applies. |
| KEYS list cut off at the bottom | Scroll, or move KEYS to its own sub-tab. |
| TIC and PTT show UNBOUND as ordinary list rows | Unbound essential keys (TIC, PTT 1) shown as a warning line at the top of the page: "TROOPS IN CONTACT has no key — bind it in Configure Addons". |

### 3.9 RADIO › Calls (`fnc_appRadioCalls`)

| Issue | Fix |
| --- | --- |
| Header says "up to 8" calls; 10 slots drawn | Label the strip "VON channels 10" and mark which slots can hold calls (3–10). Or draw only the 8 call slots plus C2 / A2G separately. **OPEN.** |
| "not built" lines | See 2.1. |
| On the voice server the 8 is a VON limit that is not there | **No limit to the number of calls on the voice server** (user, 2026-11-01: "on the radio calls tab there should be no limit to the # of calls"). Mumble or LiveKit: ALL CALLS lists every call, as many as there are, scrolling, headed "n CALLS"; no "8 CALLS AT ONCE". Game VON keeps the 8-slot strip and C2 / A2G apart (R8). 8 people a call stays: a design rule, not a channel count. |

### 3.10 RADIO › Manage (`fnc_appRadioManage`, `fnc_radioCustomPanel`, `fnc_radioMembersPanel`)

| Issue | Fix |
| --- | --- |
| WHO CAN table has role columns and no marks | Fill each cell (✓ or —) from `fnc_radioRole` rules. An empty matrix reads as broken. |
| MEMBERS pane has no empty state | "Pick a net on the left to see and edit its members." |
| Squad chip under ADD NET overflows its box (tracked text) | 2.3: untracked; chip width from its text. |

---

## 4. Acceptance

- Grep finds no "not built" in any string a draw function renders.
- WEATHER, TIMER, JAMMER: no map visible through the app at any opacity setting.
- ~~DRONES › Fleet lists no NASAMS, Skynex or Sentinel.~~ Withdrawn: R6 reversed (section 5).
- Every key/value list: value within 40 px of its label's end.
- Frame keys show the keys the player actually presses.
- Net row present and the same height with no net.
- Every count label pluralises correctly.

## 5. Decisions (user, 2026-11-01)

| # | Question | Decided |
| --- | --- | --- |
| R1 | Body text minimum size (2.3) | Values and body text never smaller than the tile detail size |
| R2 | `fnc_row` extended or new `fnc_kvRow` (2.4) | New `fnc_kvRow` |
| R3 | Frame key labels: regenerate art or draw from binds (2.5) | Draw from the binds at runtime (`CBA_fnc_getKeybind`). **Changed** by the user after seeing it (2026-11-01: "way too small, put the F1 F2 etc back, then the keybind on hover"): the art's printed F1-F4 and arrows are kept, no caps; each key's tooltip names its bind |
| R4 | Red on the DRONES alert tile: keep or use the accent block (2.7) | Accent block, as the other tiles |
| R5 | MAP TOOLS collapsed by default (3.2) | Yes: one row of tool icons until a tool is opened. **Reversed** by the user after seeing it (2026-11-01: "like the old buttons better"): the full button grid is back on both hosts |
| R6 | Drone fleet filter rule (3.3) | Exclude anything `adsite` registers, plus UAV-class vehicles that are not aircraft. **Reversed** by the user after seeing it (2026-11-01): the fleet lists every live UAV-crewed vehicle of the side - placed drones and the air-defence turrets (NASAMS, Skynex, Sentinel) |
| R7 | Enemy contact: bearing scope or map (3.4) | Bearing scope |
| R8 | Call slots strip: 10 channels or 8 calls + C2/A2G (3.9) | The 8 call slots in the strip; C2 and A2G shown apart. **Game VON only** (user, 2026-11-01: "on the radio calls tab there should be no limit to the # of calls"): on the voice server (Mumble or LiveKit) calls are unlimited, and CALLS lists them all, "n CALLS" |
