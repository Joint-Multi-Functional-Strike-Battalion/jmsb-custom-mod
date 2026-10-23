# Plan - bring the TAC suite to the "Arma 3 Messaging UI Mockups" designs

Date 2026-10-19. Source: `docs/Arma 3 Messaging UI Mockups/` (three handoffs, one package).

## What the mockups are

They are not a new system. Every report card is drawn from the template registry that is already
in the database (`JMSB.templates`: the 12 root reports, the six replies, plus TASKING), and the
combat-support screens redraw the TAC//SUPPORT app that already runs. The work is a fidelity pass
over screens that exist, plus three pieces that do not exist yet.

| Design | Handoff | In the mod today | Size of the gap |
|---|---|---|---|
| Report forms (12 root + replies) | `design_handoff_report_forms` | `tacpad/fnc_composeCard` and friends: REQ, AUTO, ranges, exclusive bools, colour swatches, OPENS TASK / MAP ANCHOR badges, SUBJ footer all present | small - layout and a few cells |
| Thread view 1a (3 panes) | `tacmsg_package/design_handoff_tacmsg_thread_view` | reader: net view, thread view, composer | medium - layout, tabs, quick-reply row, FLASH banner |
| Combat support: CAS, transport | `design_handoff_combat_support` 2a / 2b | `tacpad_apps/fnc_appSupport` (asset > unit > task chain, steppers, ROE) | medium - group-label guidance, RTB arming, passengers, map overlay |
| Combat support: ADD TASK | 2c | nothing | skipped (user, 2026-10-19) |
| TAC//ADMIN console | `design_handoff_tacadmin_console` | `addons/adminpanel` (GPL-3, own PBO) | large restyle - separate licence, last |
| Live tiles / squad status | `tacmsg_package` live-tiles | tiles (`fnc_tileData`), squad app | out of scope here except where the reader docks |

## Decisions (user, 2026-10-19)

1. **Typeface: the one the suite uses now** (RobotoCondensed / RobotoCondensedBold). Archivo is
   not converted; sizes and weights from the handoffs map onto it.
2. **Canvas**: laid out in fractions of the host rectangle, as the suite already does.
3. **DICTATE becomes VOICE MSG**: a recorded voice clip of up to 15 s, left in the thread like a
   reply. See "Voice messages" below.
4. **Tasks: skipped.** Phase 5 (ADD TASK) is dropped.

## Phases

### 1. Tokens (shared, do first)
- The theme already carries ground / ink / accent / line (`tacpad/fnc_theme`). Add the derived
  steps the designs use - accent 100 / 600 / 700 / 800 and neutral 200 / 600 / 700 - **computed
  from the three tokens**, never typed, so the Night/NVG and custom schemes still repaint.
- Rules from every handoff: zero radius, 2px region dividers, 1px row dividers, accent only for
  selection, FLASH, primary action and alerts, body-size accent text uses accent-700.
- Font: RobotoCondensed family, unchanged.

### 2. Report forms (smallest gap, most used)
Compare each of the 12 cards against `report-forms-1a-root-reports.png` and fix in `composeCard`:
- Grid fields carry two attached cells, **CUR LOC** and **MARKER**; ingress / egress lines carry
  MARKER only.
- Header tag box in accent for the high-priority templates (CASEVAC, TIC, CFF, CAS, CANTCO).
- Every root report ends with REMARKS (before ROUTING where it exists) - a registry check, then a
  database edit if any template lacks it.
- Empty required field on SEND: 2px accent border, REQ stays accent.
- Reply set per `report-forms-1b-replies.png`: ROGER / WILCO / ON TASK as one-tap tiles,
  assignee-only and issuer-only gating as the registry already defines.

### 3. Thread view 1a
Restyle the reader to the three-pane layout inside the tablet screen:
- **Rail**: nets with unread counts, ON NET roster with square online markers, self block.
- **Thread list**: filter row + NEW, tabs ALL / OPEN / MINE / ACK, rows with priority chip, type,
  time, subject, preview, reply meta; selected row = accent-100 with 4px accent left border;
  closed rows dimmed.
- **Detail**: header with PIN TO MAP + ACK, the template card in two columns, the reply spine,
  quick-reply tiles, + TEMPLATE / + GRID / + MARKER, input + SEND.
- **FLASH banner** over the current view with open-thread and a 60 s snooze.
- On the phone and side devices the reader is not shown (spec: no messaging app yet).

### 4. Combat support 2a / 2b
In `appSupport`:
- Group labels carry the guidance sentence flush right, bound to the current selection; no
  explanatory copy inside list rows.
- **ORDER UNIT RTB**: disabled while idle; double-confirm (label becomes CONFIRM RTB, second press
  within 3 s commits).
- Transport: **PASSENGERS** group listing assigned fireteams with seat counts.
- Map overlay language on the real map: task point = accent square with halo, effect radius =
  accent square outline with a caption that follows the radius stepper.
- CONFIRM TASKING enabled only with asset, unit and task set; committed task row turns accent.

### 5. Voice messages (replaces DICTATE)
Hold VOICE MSG to record, release to send; up to 15 s; the clip lands in the thread as a reply
with a PLAY cell, and plays in the listener's ear.

**Arma cannot record a microphone from script.** The only thing in the mod set that already
captures the mic, encodes Opus and plays audio is the TFAR standalone extension DLL
(`task_force_radio_pipe`, mic capture + Opus + playback mixer). So the clip is built there:
- **Record**: new extension verbs `VMSG_REC_START` / `VMSG_REC_STOP`. The DLL keeps the Opus frames
  it already encodes for transmission in a 15 s buffer (about 45 KB at voice bitrate) and hands
  them back to SQF in base64 chunks through its callback, as pacdb does.
- **Carry**: the clip rides the messaging server as a thread attachment, in chunks, and is kept
  with the thread. Optionally saved to the PAC database so a clip outlives the mission.
- **Play**: new verb `VMSG_PLAY <chunks>`; the DLL decodes and mixes it into local playback - no
  radio effect, or the receiving radio's effect if wanted.

Costs and risks:
- The DLL is ltsammy's (`github.com/ltsammy/task-force-radio-standalone`). Either the verbs go
  upstream as a pull request, or the unit ships its own build of TFAR standalone - every client
  then loads ours instead of the Workshop item.
- A rebuilt DLL is a new binary to BattlEye: an unwhitelisted client DLL is blocked with
  BattlEye on. Upstream (already published) is the clean route.
- Fallback that needs no DLL: VOICE MSG sends a "call me" marker - weaker, but zero risk.

### 6. TAC//ADMIN console (last)
`addons/adminpanel` is GPL-3 and ships as its own PBO; the restyle happens there and only there,
no code moves across. Largest layout change; do after the shared tokens have settled.

## How each phase is checked
- `python tools/check_all.py` passes.
- In game, a screenshot of each screen next to its handoff PNG, on Field Grey and on Night/NVG.
- One entry per phase in `docs/new.md`.

## Out of scope
High-density ops log (1b), glove mode (1c), the admin template builder (1d panel 04), tile
arrange mode, drone / jamming / weather / radio full-size screens - the handoffs list these as
context, not scope.
