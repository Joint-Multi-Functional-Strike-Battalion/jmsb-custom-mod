# DESIGN_SUPPORT_V2 — TAC//SUPPORT redesign

**Reference only (2026-11-01): the screen parts - the board, the type screens, their overlays - are withdrawn in favour of `docs/DESIGN_SUPPORT_MESSAGING.md` (step 9 removed the TAC//SUPPORT app).**

Build handoff. Planning spec, not code. Supersedes the screen part of
`docs/DESIGN_SUPPORT.md` ("The screen"); the support core contract stays.

Mockups: design canvas **"TAC//APP UI mockups"**, artboards
`Support2.dc.html` (map-first board), `AltCAS.dc.html`, `AltArty.dc.html`,
`AltTrans.dc.html`. `Support.dc.html` is the rejected stepped form, kept for reference.

Status: design agreed in chat 2026-11-01. Items marked **OPEN** need a user
decision before that part is built. Ask, do not guess.

---

## 1. What changes, in one picture

```
 NOW                                   NEW
 tab per type                          map-first board (one entry for all types)
   └ form: UNIT, TASK, LOCATION,         click target on map
     PARAMETERS, READY, CONFIRM            └ "who can reach it" card, best fit first
                                             └ press an asset's task button
                                                 └ type screen (CAS / ARTY / TRANSPORT)
                                                     = the PAC template for that task
                                                     SEND = files a TAC//MSG thread
                                                     thread replies = mission status
```

Three ideas carry the whole design:

1. **Target first, asset second.** The player says where. The board answers who
   can reach it, how soon, and with what. (Real-world precedent: DARPA PCAS /
   KILSWITCH, ATAK JTAC tools.)
2. **The request is the report.** Every request is one of the existing PAC
   message templates (`cas`, `callforfire`, `hlz`, `casevac`, `airdrop`), filed
   through `jmfsb_messaging`. No second request object.
3. **The thread is the status.** `ISSUED › RECEIPT › ACCEPTED › IN_PROGRESS ›
   CLOSED` (and `DECLINED`) from the existing reply templates drive every status
   shown on the board, the tile and the map.

---

## 2. Scope

| In | Out |
| --- | --- |
| `tacpad_apps` `fnc_appSupport` and its helpers (`supportMapDraw`, `supportMapLive`, `supportPointSet`, `supportPointVars`, `supportRequestParams`, `supportStepper`, …) | Native-map dialog geometry rework (keep both hosts working as today) |
| New provider hook for reach/ETA/effect (section 6) | New asset kinds |
| Wiring support requests to `jmfsb_messaging` templates | Voice / radio side of support |
| Template edits listed in section 8 | Phone / side-device support UI |
| Map overlays for request and in-flight missions | |

Rules from existing READMEs that still bind:

- Draw only with the tacpad primitives (`drawFill`, `drawFrame`, `drawText`,
  `drawHit`, `fnc_row`, `appFrame`). No new colour constants: theme tokens only,
  plus the existing fixed status colours.
- Both hosts: native map (dialog `jmfsb_tacpad_apps_supportDlg`) and tablet
  (open app on the device dialog). The board claims the map with
  `jmfsb_tacpad_appMapClaim` while it takes clicks.
- Exactly one addon knows ALiVE (`jmfsb_adapter_alive`). Providers stay behind
  the support core.
- **"Nothing is auto-filled"** (tacpad README, Composing). See section 7 for how
  computed values are offered without breaking this.

---

## 3. Map-first board (`Support2.dc.html`)

```
┌ TAC//SUPPORT  [ALL 7][CAS 3][ARTY 2][TRANS 1][LOGI 1]   hint text    [CLOSE] ┐
├───────────────┬──────────────────────────────────────────────────────────────┤
│ IN FLIGHT  2  │                                                              │
│  card+progress│        MAP  (host map, claimed)                              │
│  SPLASH 0:12  │          target ◆  danger-close ring  FLOT line              │
│  BDA button   │          ┌ TARGET 0451 7829 ───────────┐                     │
│ QUEUED     1  │          │ target description line     │                     │
│  2 · grid     │          │ BEST FIT FIRST              │                     │
│ READY      4  │          │ asset · ETA · weapon/stores │                     │
│  asset rows   │          │  [task][task][task]         │                     │
│               │          │ out-of-range asset + reason │                     │
│               │          └─────────────────────────────┘                     │
│               │   legend: CLICK / SHIFT / ALT / RIGHT-CLICK                  │
├───────────────┴──────────────────────────────────────────────────────────────┤
│ FOX 1-1 will ADJUST FIRE on 0451 7829   params…   ETA      [SEND · DANGER CLOSE]│
└──────────────────────────────────────────────────────────────────────────────┘
```

| Region | Content | Source |
| --- | --- | --- |
| Filter chips | `ALL n`, one chip per support type with count. Filter only; no tabs. | `jmfsb_support_fnc_types`, `assets` |
| IN FLIGHT | One card per open support thread: asset, task, state, progress or countdown (`SPLASH m:ss` for fires, `EN ROUTE m:ss` for air), SITREP / ABORT / RTB. Finished in the last N min: one line + **BDA** button. | thread index + provider `sitrep` |
| QUEUED | Targets the player shift-clicked but has not sent. Click = make active. | client state |
| READY | Idle assets: name, kind, platform, stores/rounds. Hover = range ring on map. Click = start from that asset (old order, kept as second way in). | `assets` |
| Map | Active target, danger-close ring, FLOT/friendly line, queued targets (numbered outline diamonds), in-flight impact rings with countdown, planned legs. | section 5 |
| Reach card | Opens at the clicked point. Rows = assets that can reach, ranked (section 6). Each row: name, kind, ETA, one line of weapon/stores, task buttons. Top row tagged **BEST FIT**. Assets that cannot reach: one dim line with the reason. | new hook, section 6 |
| Order bar | The pending order as a sentence, the task's parameters (steppers), ETA, one SEND button. Danger close: red line naming the friendly unit and distance; button reads `SEND · DANGER CLOSE` and needs two presses. | template + section 7 |

Map input (map claimed):

| Input | Does |
| --- | --- |
| Click | Set / move target |
| Shift-click | Queue another target |
| Alt-click | Add ingress / egress / via to the active order |
| Right-click | LZ / drop / hold point (transport) |

Pressing a task button on the reach card opens the type screen for that task
(sections 4.1–4.3), prefilled with the asset and the target. **OPEN:** whether
simple tasks (e.g. SMOKE, LOITER) skip the type screen and send from the order
bar directly. Default proposal: tasks whose template has no required field left
empty send from the order bar; others open the type screen.

---

## 4. Type screens

All four share: header with type + template id + thread id; state steps along
the top (`DRAFT › ISSUED › WILCO › ON TASK › CLOSED`); left = the template as
rows; right = map with that template's geometry; one primary action.

Each template line is one row: `line id · label · value · FROM`. `FROM` says
where the value came from: `MAP`, `MARKER`, `BFT`, `TYPED`, `STORES`,
`MANIFEST`, `STRIP`, `CART`. A row the player must still fill shows the accent edge.

### 4.1 CAS (`AltCAS.dc.html`, template `cas`)

| Line | Label | Filled from |
| --- | --- | --- |
| Line 1 | Grid reference | map click (target) |
| Line 2 | Map reference | nearest marker, offered (MARKER) |
| Line 3 | Ingress location | alt-click |
| Line 4 | Egress location | alt-click |
| Line 5 | Target description | typed |
| Line 6 | Range from friendlies + DANGER CLOSE | BFT nearest friendly, offered (section 7) |
| Line 7 | Marked by + code | button row SMOKE / LASER / IR / TRACER / NONE |
| Optional | Preferred munitions | buttons from the asset's stores |
| Remarks | | typed |

Above the form: the aircraft strip from its `checkin` thread (type, position,
alt, ordnance, time on station, abort code). Below the form: the thread
(messages with state), then **CLEARED HOT / ABORT / CLOSE**.

CLEARED HOT is enabled only in state ACCEPTED or IN_PROGRESS.
**OPEN:** does CLEARED HOT post a message into the thread (new reply template
`clearedhot`) or is it a provider call only? Proposal: a reply template, so the
log is complete.

Map: ingress → target line, egress line, target diamond with L1/L2, danger-close
ring, friendly unit with L6 distance, the lasing asset with code.

### 4.2 ARTY (`AltArty.dc.html`, template `callforfire`)

Left column = `callforfire` lines, compact:

| Line | Shown as |
| --- | --- |
| Observer | own call sign (template autoFill, existing) |
| Warno 1 | A–D as one choice row |
| Warno 2 | text |
| Warno 3A/3B/3C | **one row** with a GRID / POLAR / SHIFT switch (see section 8) |
| Description | typed |
| Engagement | shell choice + rounds |
| Danger Close | DC + distance from BFT, offered |
| Control | A–F choice; TOT row appears only for C |

Under it: battery reply (from the thread), then the **round log**: one row per
round (`n · SPLASH · where it landed` / `n · correction · IN FLIGHT · SPLASH m:ss`).

Right side: map with observer–target line (OT direction in mils), target,
numbered splashes, in-flight round ring with countdown, friendly line. Over the
map, the **adjust pad**:

```
        [ ADD ]
 [LEFT]  50 M  [RIGHT]
        [DROP ]
 [25][50][100][200][400]      step
 or click the map where the next round should land
 [ SEND CORRECTION ]
 [ FIRE FOR EFFECT · n ]
 [REPEAT] [CHECK FIRE] [EOM]
```

Corrections are along the OT line. A map click is converted to the nearest
correction in the chosen step. Each correction is a thread message (section 8,
new template `adjust`). EOM sends `close`.

### 4.3 TRANSPORT (`AltTrans.dc.html`, template `hlz`, also `casevac`, `airdrop`)

Top: **route strip** `PZ › VIA… › LZ › THEN (RTB / HOLD / LOITER)`, each leg with
distance and time. PZ and LZ boxes carry name, grid, security state; a RED LZ is
outlined red.

Left: **manifest** — seat bar (filled per squad), one row per squad with state
(`AT PZ`, `300 M OUT`) and REMOVE; buttons `+ MY SQUAD`, `+ SQUAD AT PZ`, `+ CARGO`.
Under it: the brief. A switch above the brief selects the template:
`HLZ` (default) · `CASEVAC` · `AIRDROP`.

| `hlz` line | Filled from |
| --- | --- |
| Line 1 HLZ location | strip (LZ) |
| Line 2 Name / marker | LZ marker name |
| Line 3 Extract contents | manifest count |
| Line 4 Security | GREEN / YELLOW / RED buttons |
| Line 5 Marking | choice + text |
| Line 6 / 7 Ingress / egress | strip legs |

Map: route legs, threat rings the route avoids, PZ/LZ, via points.
Shift-click adds a via; dragging a leg bends it.

Bottom bar: sentence (`RAVEN lifts 7 from HAWKINS to FALCON · wheels down 3:20`),
`HOT LZ · confirm twice` when Line 4 is RED, **LAUNCH**.

### 4.4 LOGISTICS (template `resupply`, 2026-11-01)

Provider `logi` (`addons/support_logistics`). The click is the delivery point.

Left: the **cart** — one row per item from the asset's catalog (`− count +`,
REMOVE), `+ ITEM` opens the catalog list (names as the module publishes them).
Over it a **capacity bar**: items in the cart / the module's capacity; full,
`+` greys out. SLING lists only what the hook can lift. The cart is parameter
slot 49, `[[catalog index, count], ...]`; the board clears it after SEND.

Under the cart: **method** AIRDROP / SLING (button row; only the ones the asset
flies), then the `resupply` card:

| Line | Label | Filled from |
| --- | --- | --- |
| Item 1–4 | Catalog item + count | CART (one line per cart row) |
| Location | Delivery point | MAP (the click) |
| Method | AIRDROP / SLING | the method buttons |
| Marking | SMOKE / IR STROBE / CHEMLIGHT / FLARE / NONE + colour | button row |
| Remarks | | TYPED |

Map: delivery point; the leg in from where the aircraft appears (module, or
the spawn distance out); SLING: one set-down mark per helicopter, 60 m apart.

Bottom bar: `MULE drops 2 HUNTER, 1 CRATE on 0451 7829 · ETA 4:10`, **SEND**.

---

## 5. Map overlays

| Overlay | When | Drawn |
| --- | --- | --- |
| Target | active order | filled accent diamond + grid label |
| Queued targets | queue not empty | outline diamond + number |
| Danger-close ring | friendly inside threshold | red ring, label names the friendly unit + distance |
| FLOT / friendly line | always on the board | dashed line through friendly unit positions (BFT). **OPEN:** source of the line — convex hull of friendly groups, or a mission-drawn marker line? |
| Range ring | READY row hovered, or asset picked | dashed accent circle |
| Route legs | CAS ingress/egress, transport legs | solid accent line, leg label |
| In-flight impact | fires mission in flight | red filled ring + `NAME · SPLASH m:ss` |
| Splashes | arty adjust | numbered dots |

Use `supportMapDraw` / `supportMapLive` and the provider `overlay` call; add the
new layers there, not in a second draw handler.

---

## 6. New support-core call: reach

The board needs, for one map point, every asset's answer at once.

```
jmfsb_support_fnc_reach   [pos, typesFilter]  ->  [[assetId, can, eta, why, effect, tasks], ...]
```

| Field | Meaning |
| --- | --- |
| `can` | bool, the asset can service this point now |
| `eta` | seconds, -1 unknown |
| `why` | short reason when `can` is false (`OUT OF RANGE 14/12 KM`, `NO STORES`, `TASKED`) |
| `effect` | one line for the card (`155 HE · kill radius 50 m · 24 rds`) |
| `tasks` | task ids valid at this point (from the provider's task declarations) |

Provider side: a new optional provider hook `reach [assetId, pos] -> [can, eta, why, effect, tasks]`.
A provider without it falls back to the core using its existing `preview` per
asset/task. Call `reach` once per target click, not per frame.

**Ranking** (best fit first): (1) `can`, (2) effect match to the target
description class (vehicle → AT-capable first, infantry → HE/airburst first;
unknown → skip this key), (3) ETA. **OPEN:** whether effect matching is in
scope for v2 or ranking is ETA-only first.

**OPEN (performance):** cost of `reach` across all providers per click is
unknown. Measure before adding effect matching.

---

## 7. Computed values vs "nothing is auto-filled"

The tacpad rule: a location is never silently filled. This design computes
several values (L6 range from friendlies, danger close, Line 2 marker, manifest
count, strip legs). Rule for v2:

- A value the player **clicked or pressed** fills directly (map click, alt-click,
  marker pick, button choice).
- A value the board **computed** is shown as an offer in the row:
  `250 M (BFT) · USE`. One press accepts it; typing overrides. On a required
  line it shows the accent edge and counts as missing until accepted; on an
  optional line it is shown and, if not taken, left out (user, 2026-11-01).
  An offered danger-close tick holds SEND on any line.
- Exception, matching the existing FILE CASEVAC FOR rule: when the action names
  the thing it fills from (`+ MY SQUAD` fills the manifest), it fills directly.

Danger close itself is never auto-unticked: if the computed distance is under
the threshold the DC tick is offered; the player can only tick it, not clear a
computed DC without typing a distance.

---

## 8. Template changes (`messaging/templates.inc.sqf`)

Line titles are field keys (messaging README). Do not rename existing line
titles; add lines and templates.

| # | Change | Why |
| --- | --- | --- |
| T1 | **New reply template `adjust`**: fields direction (ADD/DROP/LEFT/RIGHT, exclusive pairs) and distance (number), `kind reply`, allowed from ACCEPTED / IN_PROGRESS | arty corrections as thread messages |
| T2 | New reply templates `ffe`, `repeat`, `checkfire` (no fields) | adjust pad buttons; EOM reuses `close` |
| T3 | **OPEN** new reply template `clearedhot` (no fields) | CAS log completeness (section 4.1) |
| T4 | `callforfire`: keep Warno 3A/3B/3C lines as-is for data; the UI renders them as one row with a switch | no data change; UI only |
| T5 | `callforfire`: add a danger-close threshold option (proposal 600 m) used for the offered DC tick | `cas` has 300 m in its hint text, arty has none |
| T6 | `hlz`: add lines `Wind` (text) and `Obstacles` (text) | `airdrop` has winds, `hlz` does not |
| T7 | `airdrop`: add line `Contents` (text or choice of crate types) | the drop's cargo is not stated |
| T8 | `checkin` Line 1 autoFill `ownCallsign` is wrong when a JTAC or the AI provider files it. Proposal: provider-filed check-ins pass the asset callsign explicitly. | AI assets need a check-in thread too |
| T9 | **OPEN** a second CAS template `nineline` (doctrinal 9-line: IP/BP, heading, distance, elevation, description, location, mark, friendlies, egress) for player pilots | `cas` is a request format, not a 9-line |

---

## 9. Messaging integration

- **SEND** = `jmfsb_messaging_fnc_submit [templateId, answers, addressees]`.
  Addressee = the asset's provider box. **OPEN:** box naming per asset
  (`B:SUPPORT:<assetId>`?) vs one shared `B:SUPPORT`.
- The provider (server) listens for threads filed to its box and **replies as
  the asset** through the existing callsign override in `srvSubmit`: ROGER on
  receipt, WILCO when it accepts, ON TASK when executing, CANTCO with reason,
  CLOSE when done. That is what moves the thread state the board shows.
- IN FLIGHT cards, the SUPPORT tile and the map all read the thread index
  (`jmfsb_messaging_index`) filtered to support templates. No second state.
- Countdown values (`SPLASH`, `EN ROUTE`) come from the provider's `sitrep`,
  shown on the card; the thread carries state, not timers.
- BDA button: files a `tasking` (or new `bda`) thread to the nearest friendly
  drone provider. **OPEN.**

---

## 10. Build order

1. Template edits T1, T2, T4–T8 (data only). Run the messaging self-tests
   (`#jmfsb msg.*`).
2. Provider auto-replies (section 9) for existing providers, so a request filed
   through the current UI already produces thread states.
3. `jmfsb_support_fnc_reach` + provider hook, ETA-only ranking.
4. Map-first board shell: chips, rails, reach card, order bar. Keep the old
   form reachable behind a setting until 7 is done.
5. CAS screen.
6. ARTY screen + adjust pad.
7. TRANSPORT screen (HLZ, then CASEVAC / AIRDROP switch).
8. Overlays (section 5), then remove the old form.
9. Effect-matched ranking if 3 measured cheap enough.

Each step should leave the board usable on both hosts.

---

## 11. Acceptance checks

- Click a point: reach card lists every asset; out-of-range assets say why.
- Press a task: correct template opens, target line filled from the click,
  computed rows shown as offers, not filled.
- SEND files a thread; `#jmfsb msg.threads` shows it with the template id.
- Provider replies move the state steps on the screen and the IN FLIGHT card.
- Danger close needs two presses; the bar names the friendly unit.
- Arty: three corrections then FFE produce 5 thread messages in order.
- Transport: RED LZ needs two presses; manifest count matches HLZ Line 3.
- ESC closes the board, not the tablet; map clicks never close the board while
  it holds the claim.
- Works in native and tablet host.

---

## 12. Decisions (user, 2026-11-01)

| # | Question | Decided |
| --- | --- | --- |
| D1 | Simple tasks send from the order bar, or always open the type screen | A task whose template has no required field left empty sends from the order bar; the rest open the type screen. Transport (`hlz`) therefore sends from the bar; the bar's BRIEF button opens any type's screen on demand (user, 2026-11-01) |
| D2 | CLEARED HOT as a reply template (T3) | Yes: reply template `clearedhot` |
| D3 | `nineline` template for player pilots (T9) | Yes, in v2 |
| D4 | FLOT line source | Both: the mission's marker line when it has one, else the hull of friendly groups (BFT) |
| D5 | Effect-matched ranking in v2, or ETA only | ETA only first; effect matching after `reach` is measured |
| D6 | Provider box naming | One box per asset: `B:SUPPORT:<assetId>` |
| D7 | BDA: `tasking` thread or new `bda` template | New `bda` template |
| D8 | Arty danger-close threshold value | A per-card option on `callforfire` in JMSB.templates, 600 m to start |
