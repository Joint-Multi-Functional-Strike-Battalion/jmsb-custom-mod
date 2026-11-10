# DESIGN_SUPPORT_MESSAGING — support requests through TAC//MSG

Build handoff. Planning spec, not code.

**Decision (user, 2026-11-01):** no support interface. The support system stays.
The JTAC requests support by sending a message to the asset, the same way he
would message a player.

**Note (user, 2026-11-02): the ALiVE provider is removed.** "we should not be
relying on alive support" - "if alive is present we integrate - but not the
support". Support is the mod's own providers only (`cas`, `support_air`,
`support_fires`, `support_logistics`, `jumpmaster`). Every ALiVE provider
line below (CAS / ATO, artillery, transport, the BDA forwarded to ALiVE) is
history, not the design.

This replaces the screen parts of `DESIGN_SUPPORT_V2.md` (the map-first board
and the CAS / ARTY / TRANSPORT screens) and makes `STITCH_SUPPORT_PROMPTS.md`
moot. Both files are left in place for reference. The template work and the
reach idea from V2 carry over here.

Items marked **OPEN** need a user decision. Ask, do not guess.

---

## 1. The picture

```
 JTAC (player)                    messaging (server)              support provider (server)
 ─────────────                    ─────────────────               ─────────────────────────
 NEW → template cas
 TO: HOG
 fill lines → SEND  ───────────►  thread T0042 filed in
                                  HOG's box + FIRES.cas  ───────►  reads template fields
                                                                   checks: range, stores,
                                                                   danger close
                    ◄───────────  ROGER        ◄─────────────────  replies as HOG
                    ◄───────────  WILCO · ETA 2:40
 CLEARED HOT  ─────────────────►  reply       ──────────────────►  executes
                    ◄───────────  IN · OFF
                    ◄───────────  REQUEST BDA · RE-ATTACK? · 8 MIN ON STATION
 BDA: 1 BMP DESTROYED,
 RE-ATTACK NO  ────────────────►  reply       ──────────────────►  logs it
                    ◄───────────  ANY FURTHER TASKING?
 CLOSE  ───────────────────────►                                   RTB / back on station

                        or        CANTCO · OUT OF RANGE 14/12 KM
```

A player pilot or gun crew gets the same thread and answers by hand.
Same flow for AI and players.

---

### 1.1 Fixed-wing: on station first, then strike (user, 2026-11-01)

"need a request for on station fixed wing, then use the strike request we
have". Two threads to the aircraft's box:

1. **Request on station** - a new root card (`onstation`): the aircraft
   launches, flies to its hold 8,000 m beyond the map edge nearest the
   area (dark, per the support aircraft rules), and answers with a
   `checkin` (type, ordnance, time on station, abort code).
2. **Strike** - the existing `cas` card to the same aircraft: it comes in
   from the hold at 4,000 m ATL, strikes after CLEARED HOT, and returns to
   the hold. A `cas` to a fixed-wing that is not on station is answered
   CANTCO `NOT ON STATION`.

Off station: RTB, bingo, or the on-station thread closed.

### 1.2 Drone escorts (user, 2026-11-01)

An option on the support aircraft modules (3DEN), with the escort drone
classes set in the module:

| Lead | Escort | When |
| --- | --- | --- |
| Fixed-wing | 2 fixed-wing drones (module class) | every sortie, when the option is on |
| Helicopter | 2 rotary drones (module class) | when the request's LZ security (`hlz` Line 4) is YELLOW or RED; GREEN goes without |

The escorts fly with the lead under the same rules (dark, heights, route,
off-map hold), cover it and engage threats to it and round the target or
LZ, defend it with flares, and come home with it.

**Built 2026-11-01** (not seen in game): module attributes Drone Escorts /
Fixed-Wing Escort Class / Rotary Escort Class on JMSB - CAS, Transport
(rotary only), QRF Insertion and Logistics; support_air `escortLaunch`, the
core's `escort` watch and `lzSecurity` (support README, "Drone escorts").
A request card with no LZ security line (`cas`, `qrf`, `airdrop`), or no
thread, goes by the module option alone: escorted.

## 2. What stays, what goes

| Keep | Remove |
| --- | --- |
| Support core (`jmfsb_support`) and every provider (`support_air`, `support_fires`, `cas`, ALiVE provider): they fly, fire and land the assets | TAC//SUPPORT app on both hosts: `fnc_appSupport` and the `support*` helpers in `tacpad_apps` (`supportMapDraw`, `supportMapLive`, `supportPointSet`, `supportPointVars`, `supportRequestParams`, `supportStepper`, `supportCell`, `supportGroup`, `supportHover`, `supportPassengers`, `supportTint`) |
| Templates `cas`, `callforfire`, `hlz`, `casevac`, `airdrop`, `checkin` | The support request dialog `jmfsb_tacpad_apps_supportDlg` |
| FIRES nets in the reader (`FIRES`, `FIRES.cas`, `FIRES.arty`, `FIRES.trans`) | `support` from the soft-key app list (`SOFT_KEY_IDS`) and the walking-view button list |
| SUPPORT live tile (it now opens the reader, see 6.4) | |
| Support core calls `assets`, `types`, `request`, `preview`, `sitrep`, `overlay` | |

Remove last (build order, section 10), after the messaging path works end to
end. Grep for every caller of the removed functions before deleting.

---

## 3. Assets as mailboxes

Every support asset gets a messaging mailbox and appears in the TO picker like
a player or squad.

| Item | Rule |
| --- | --- |
| Box id | **OPEN** (D1). Proposal: one box per asset, `B:SUP:<assetId>`, display name = the asset's callsign (HOG, FOX 1-1, RAVEN). |
| Who sees the box in TO | The players' side. **OPEN** (D3): gate by role (JTAC / JFO / leaders, via the existing `isJFO` / `isISR` role flags) or everyone. |
| Contact row | callsign · type (CAS / ARTY / TRANS) · state from the provider: `IDLE`, `TASKED`, `RTB`, `REARMING`, `LOST`. A row that cannot take a task is dim and says why. |
| ETA in the row | **OPEN** (D2): show ETA to the sender's current GPS grid, or state only. |
| Also filed to | the matching FIRES sub-net (`FIRES.cas` / `FIRES.arty` / `FIRES.trans`), so everyone watching fires sees the request. |

Player assets (a player pilot, a player gun crew) keep their own player box.
The provider ignores threads addressed to player boxes.

**Alternative for D1** — one box per type (`B:SUP:CAS`): the provider picks the
best-fit asset and replies as that asset. The JTAC does not need to know what
is available, but he cannot choose. Per asset matches "message it like a
player"; per type is faster under fire. Both can exist: per-asset boxes plus a
per-type box that routes.

---

## 4. Templates → provider request

The provider reads the submitted template fields (messaging already flattens
them into named fields; line titles are field keys).

| Template | Field | Provider uses it as |
| --- | --- | --- |
| `cas` | `Line1.A` grid | target |
| | `Line2.A` | target label |
| | `Line3.A` / `Line4.A` | ingress / egress points; empty = provider picks |
| | `Line5.A` | target description (shown in replies; future: effect matching) |
| | `Line6.A` / `Line6.B` | range from friendlies / DC tick (danger-close check, 5.3) |
| | `Line7.A` / `Line7.B` | mark type / code (LASER code → laser-guided attack if the airframe can) |
| | `Optional.A` | preferred munition; provider picks if empty or not carried |
| `callforfire` | `Warno1` A–D | mission type: adjust / FFE / suppress / immediate suppression |
| | `Warno3A.A` or `Target2` (polar) or `Target3` (shift) | target location |
| | `Engagement` A–F + rounds | shell + count |
| | `DangerClose.A` / `.B` | DC tick / distance |
| | `Control` A–F, `TOT.A` | fire control |
| `hlz` | `Line1.A`, `Line2.A` | LZ |
| | `Line3.A` | what to carry (free text; passengers are those at the pickup) |
| | `Line4` | security; RED = hot LZ (5.3) |
| | `Line6.A` / `Line7.A` | ingress / egress |
| `casevac` | `Line1.A` | pickup site; `Line2`, `Line3` patients |
| `airdrop` | `Line1.A` | drop point; `Line5` winds; new `Contents` line (section 8) |

Pickup point for `hlz`: **OPEN** (D4). The template has no pickup line.
Options: the sender's position when sent; a new `Pickup` line; or a second
thread. Proposal: add a `Pickup` grid line to `hlz` (source mapClick, required).

---

## 5. Provider behaviour

### 5.1 Replies (as the asset)

Uses the existing `srvSubmit` call-sign override, so the message arrives
unread, notifies, and lands on the thread spine like a player's.

| When | Reply | Thread state |
| --- | --- | --- |
| Thread received | `roger` | RECEIPT |
| Accepted | `wilco` + text `ETA m:ss` | ACCEPTED |
| Cannot | `cantco` + reason (5.2) | DECLINED |
| Executing | `inprogress` | IN_PROGRESS |
| Milestones | new status replies (section 7): `shot`, `splash` (fires); `in`, `off` (CAS); `wheelsup`, `wheelsdown` (transport) | unchanged |
| Done | `close` + outcome text | CLOSED |

**Changed 2026-11-01** (user: "did get 2 messages roger wilco which is one
message, need more information like after rw inbound eta etc etc and an alert
to pop smoke when its close"; built, not seen in game):

- **ROGER + WILCO = one message.** The receipt waits 2 s (`RECEIPT_HOLD`); an
  asset that accepts inside it answers once, `ROGER, WILCO - ETA m:ss -
  <detail>`, and the thread lands on ACCEPTED; a CANTCO inside it goes alone.
  A slow asset still says ROGER, then WILCO. Every asset type (support core).
  The deck's `wilco` has no text line: the WILCO with a detail is the
  built-in `accepted` card (same for `ontask`).
- **On the way in** (transport, casevac, airdrop, resupply, QRF): WHEELS UP
  `INBOUND - ETA m:ss` at the launch; INBOUND `ETA m:ss - <grid>` every 60 s
  (`TRANSPORT_ETA_UPDATE_S`); a minute out `1 MIN OUT - POP SMOKE` (or the
  card's Line 5 marking: POP IR / FLARE), FLASH, folded with `1 MIN - LZ
  STATUS?` into one message at the card's LZ, plus the issuer's popup
  `<CALLSIGN> 1 MIN OUT - POP SMOKE` (upper right). CAS and fires keep their
  own milestones.
- **RED LZ**: WILCO `HOT LZ - REPLY CONFIRM TO LAUNCH`; CONFIRM shows in the
  quick replies.
- **The deck without the new cards still works**: the mod carries every card
  it defines, and the mod's own card always wins (2026-11-02) - the deck adds
  only ids the mod does not have. An RPT line names the deck cards skipped.

### 5.2 CANTCO reasons

Short, fixed words, so they read at a glance:
`OUT OF RANGE <n>/<max> KM` · `NO STORES` · `TASKED` · `RTB` ·
`DANGER CLOSE NOT ACKNOWLEDGED` · `HOT LZ NOT ACKNOWLEDGED` ·
`NO TARGET LOCATION` · `CANNOT LASE <code>`.

### 5.3 Safety checks (the provider refuses; no UI needed)

| Check | Rule |
| --- | --- |
| Danger close, CAS | nearest friendly (BFT) under 300 m (the `cas` template's own threshold) and `Line6.B` not ticked → CANTCO `DANGER CLOSE NOT ACKNOWLEDGED` |
| Danger close, artillery | under the arty threshold (**OPEN** D5, proposal 600 m) and `DangerClose.A` not ticked → CANTCO |
| Hot LZ | `hlz` Line 4 RED → the asset replies `wilco` with text `HOT LZ — CONFIRM`; it lifts only after the sender replies `confirm` (section 7) |

This replaces the double-press SEND of the old design. A real battery or pilot
refuses the same way.

### 5.4 The asset asks back

The asset does not just report; it prompts the JTAC for what it needs next,
the way a pilot or battery would on the net. Each prompt is a reply from the
asset (template `prompt`, section 7) whose text says what it wants, and whose
quick replies are the answers. A prompt never moves the thread state; the
JTAC's answer does.

| Type | When | Asset asks | JTAC's quick replies |
| --- | --- | --- | --- |
| CAS | after `wilco`, no CLEARED HOT in 60 s | `AWAITING CLEARED HOT` | CLEARED HOT · ABORT |
| CAS | after `off` | `REQUEST BDA` | BDA (opens `bda` card) |
| CAS | after BDA with re-attack = yes, or stores left | `RE-ATTACK? <n> <munition> LEFT` | CLEARED HOT · NO |
| CAS | after BDA, stores left | `<n> MIN ON STATION · FURTHER TASKING?` | new `cas` in thread · RTB · CLOSE |
| CAS | fuel / time on station low | `BINGO IN 2 MIN` | RTB · CLOSE |
| ARTY | after `splash` on an adjust round | `ADJUST?` | ADD / DROP / LEFT / RIGHT · FFE · EOM |
| ARTY | after FFE `splash` | `ROUNDS COMPLETE · REQUEST BDA` | BDA · REPEAT · EOM |
| ARTY | after BDA | `END OF MISSION?` | EOM · REPEAT |
| TRANS | 1 min out | `1 MIN · LZ STATUS?` | COLD · HOT (sets hot-LZ rule) |
| TRANS | circling the landing point, a mark seen (2026-11-02) | `I SEE <COLOUR> SMOKE` (`IR STROBE`, `<COLOUR> CHEMLIGHT`, `FLARE`), FLASH | CORRECT · WRONG (keeps circling, looks again) |
| TRANS | circling, no mark seen for 45 s (2026-11-02) | `CIRCLING · NO SMOKE SEEN · POP SMOKE` | NO SMOKE (land on the grid, no verification) |
| TRANS | verified or NO SMOKE - every landing, a hot LZ's too (2026-11-02) | `READY TO LAND · CLEARED?`, FLASH | CLEARED TO LAND · HOLD (asked again in 30 s) · ABORT (home, CLOSED) |
| TRANS | wheels down | `WHEELS DOWN · PAX OFF?` | PAX OFF · HOLD |
| TRANS | pax off | `HOLD, RTB OR NEXT LIFT?` | HOLD · RTB · new `hlz` in thread |
| CASEVAC | patients aboard | `PATIENTS ABOARD · DESTINATION?` | grid / marker reply · DEFAULT (nearest medical) |
| AIRDROP | after release | `PACKAGE AWAY · CONFIRM RECEIPT` | RECEIVED · NOT FOUND |
| Any | sender silent 3 min while a prompt is open | `NO RESPONSE · HOLDING` then `RTB` after 5 min | any of the above |

**Circle till the mark is verified, cleared to land** (user, 2026-11-02:
"support trans needs to circle till smoke is verified, caller pops smoke helo
verifies color, either way transport needs final permission to land"; built,
not seen in game). Every landing a support transport makes on a request thread
- the hlz's pickup and LZ, the casevac's pickup and destination, a QRF air
assault's insertion, ALiVE's transport point by point - circles the point and
does not land until CLEARED TO LAND. The support core runs the wait
(`jmfsb_support_fnc_lzClear`): smoke within 150 m, its colour from the class
(SmokeShellRed - RED, SmokeShell - WHITE), and the card's IR strobe /
chemlight / flare when its marking asks. A hot LZ still needs its CONFIRM, and
this clearance too. D9 runs on every prompt while it circles.

Rules:
- Prompts go to the thread, so the JTAC sees them with the request and the map pin.
- A prompt is FLASH priority only when the asset is waiting to release
  (`AWAITING CLEARED HOT`), to land (`I SEE ... SMOKE`, `READY TO LAND ·
  CLEARED?`, 2026-11-02) or about to leave (`BINGO`); others are routine.
- The BDA answer is kept on the thread and passed to the provider: the CAS
  provider uses re-attack; the ALiVE provider forwards it as a report
  (`jmfsb_adapter_alive_fnc_postReport`, like CONTACTREP / SITREP today).
- Timeouts (60 s, 3 min, 5 min): **OPEN** (D9), proposals above, per asset type.
  Decided (section 12) and built for CAS 2026-11-01 (step 5).

### 5.5 Who may reply

Follow-ups (CLEARED HOT, adjust, ABORT, BDA, answers to prompts…) are accepted from the thread's issuer,
and from the observer named in `callforfire` Observer if different.
**OPEN** (D6): also anyone on the FIRES net?

---

## 6. Reader changes (TAC//MSG)

### 6.1 TO picker

- Support assets listed in their own group, `SUPPORT`, under squads and players.
- When the template is a support one (`cas`, `callforfire`, `hlz`, `casevac`,
  `airdrop`), the picker opens on that group, filtered to the matching type,
  and shows each asset's state (and ETA if D2 = yes).
- **@ mentions - built 2026-11-01** (not seen in game; user: "want to use an
  @[unit] to enable ai support units", "need to have the proper template
  also for the type of unit"). The CC line's @ list offers the SUPPORT
  group's assets, every type. A mention puts the asset's box on TO and opens
  its type's card: CAS `cas` (a fixed-wing the AI flies, not on station:
  `onstation`, 1.1), artillery / cruise / loitering `callforfire` (CFF GRID;
  a CFF POLAR or SHIFT being written is kept, 2026-11-02), transport `hlz`
  (LIFT REQUEST; an EXTRACTION being written is kept), logistics `resupply`,
  QRF `qrf`. A card the deck lacks: the card
  stays and the status line says so. Typed text moves across or is asked
  about first (tacpad README, "Composing"). The SUPPORT group lists every
  type (`MAILBOX_TYPES`, support README).

### 6.2 Quick replies per template

Quick replies under an open thread already come from the template's
`replyableWith` and are drawn only when the server would accept them. Extend
`replyableWith` per support template:

| Thread template | Sender's quick replies |
| --- | --- |
| `cas` | CLEARED HOT · ABORT · RTB · CLOSE |
| `callforfire` / `cffpolar` / `cffshift` (2026-11-02) | ADD · DROP · LEFT · RIGHT (each opens a distance pick: 25 50 100 200 400) · FFE · REPEAT · CHECK FIRE · EOM |
| `hlz` / `extract` (2026-11-02) / `casevac` / `airdrop` | CONFIRM · ABORT · RTB · CLOSE |

**Built 2026-11-01** (not seen in game): the rows above, to the thread's
sender, from the reader itself (tacpad `QUICK_SUPPORT`; the server does not
check `replyableWith`, so the deck needs no change for them). Drawn only
where the server would take them (state, sender rule, the card in the
deck). A card with no required line files in one press; one with a required
line (`bda`) opens in the composer on the thread. ADD / DROP / LEFT / RIGHT
open the distance pick in the row (25 50 100 200 400, BACK) and file
`adjust` in that press. Anyone else on a support thread (the player crew it
went to) keeps the one-tap replies of the card's `replyableWith` (tacpad
README, "Composing").

### 6.3 Thread map pin

Threads already anchor to their grid. For support threads the pin also draws:
target / LZ marker, danger-close ring, ingress/egress lines from the template,
and while in progress the impact ring (fires) or route (transport) from the
provider's `overlay`. No new map layer system; extend the thread pin.

**Built 2026-11-01** (not seen in game; support README, "The thread's map
pin"): local markers beside the thread's own pin, on the game map and the
tablet's map, for a man the support card was pushed to or who opened the
thread. The card's points (TARGET, LZ, PICKUP, DZ, ...), IN / OUT legs, a red
danger-close ring while a BFT friendly is inside it; IN_PROGRESS, the
asset's overlay, rounds in the air as a red ring with `SPLASH m:ss`, and its
route. A 2 s poll, never per frame; gone when the thread closes.

### 6.4 SUPPORT tile

Same tile, same data (assets available, in flight). Pressing it opens the
reader on the `FIRES` net instead of the removed app.

---

## 7. New and changed templates (`messaging/templates.inc.sqf`)

Line titles are field keys. Add; never rename existing line titles.

| Id | Kind | Fields | Sent by | Allowed from |
| --- | --- | --- | --- | --- |
| `clearedhot` | reply | — | issuer | ACCEPTED, IN_PROGRESS |
| `abort` | reply | — | issuer | ACCEPTED, IN_PROGRESS |
| `rtb` | reply | — | issuer | any open |
| `confirm` | reply | — | issuer | ACCEPTED |
| `adjust` | reply | Direction (ADD / DROP / LEFT / RIGHT, exclusive pairs), Distance (number) | issuer / observer | ACCEPTED, IN_PROGRESS |
| `ffe` | reply | Rounds (number, optional) | issuer / observer | ACCEPTED, IN_PROGRESS |
| `repeat` | reply | — | issuer / observer | IN_PROGRESS |
| `checkfire` | reply | — | issuer / observer | IN_PROGRESS |
| `shot`, `splash` | reply | Text (optional, e.g. `TOF 32`) | asset | IN_PROGRESS |
| `in`, `off` | reply | — | asset | IN_PROGRESS |
| `wheelsup`, `wheelsdown` | reply | — | asset | IN_PROGRESS |
| `prompt` | reply | Text (what the asset asks), Answers (list of reply ids offered as quick replies) | asset | any open |
| `bda` | reply | Target (text, prefilled from the request's description), Effect (DESTROYED / DAMAGED / NO EFFECT / UNKNOWN, exclusive), Count (number), Re-attack (bool), Remarks (text) | issuer / observer | IN_PROGRESS |
| `cold`, `hot`, `paxoff`, `hold`, `received`, `notfound`, `no` | reply | — | issuer | IN_PROGRESS |

EOM = existing `close`.

`prompt` is the one template that sets quick replies at runtime: the reader
draws its `Answers` as the quick-reply row while it is the newest message in
the thread, falling back to the template's `replyableWith` otherwise.
**Built 2026-11-01** (not seen in game, tacpad `readerQuickTiles`): the
Answers ids are the tiles, with the same rules as 6.2 (`adjust` is the four
directions); a prompt whose answers the thread takes none of falls back. The
prompt reads on the thread as its Text alone, at the title size on the
accent.

Changes to existing templates:

| Template | Change |
| --- | --- |
| `cas`, `callforfire`, `hlz`, `casevac`, `airdrop` | extend `replyableWith` per 6.2 |
| `callforfire` | add a danger-close threshold option (D5) |
| `hlz` | add `Pickup` grid line (D4); add `Wind` and `Obstacles` text lines |
| `airdrop` | add `Contents` line |
| `checkin` | when the provider files it for an AI asset, pass the asset callsign (Line 1 autoFill `ownCallsign` is for pilots filing their own) |

~~**OPEN** (D7): a doctrinal 9-line template for player pilots. `cas` is a
request format, not a 9-line.~~ Built as `nineline` (2026-11-01), **retired
2026-11-02** (user: "CAS REQUEST and CAS 9-line do not need both" - CAS
REQUEST stays): no built-in card, no reader, no mailbox, no pin; the review
script removes it from the deck. A player pilot is mentioned with `cas`.

**The decisions of 2026-11-02** (user; built, not seen in game - the support,
messaging, tacpad, support_air, support_logistics and adapter_alive READMEs
carry the detail):

| Card | Change |
| --- | --- |
| `callforfire` | CFF GRID ("break arty in to 3 reports grid polar and shift fire"): its keys kept; the grid required; the polar and shift lines go to their own cards (an older deck's are still read) |
| `cffpolar` (new) | CFF POLAR: Polar (direction, distance from the observer - Observer.B's grid, else the sender), then CFF GRID's lines. Kind `fire` |
| `cffshift` (new) | CFF SHIFT: Known (a grid or a map marker), Lateral LEFT / RIGHT m, Range ADD / DROP m, Vertical UP / DOWN m - along the observer-target line; then CFF GRID's lines. Kind `fire` |
| `onstation` | AREA a map marker, required ("REQUEST ON STATION should require a map marker"): messaging `markerOnly`; a typed grid or none is refused `PICK A MAP MARKER FOR THE AREA`. The aircraft takes its station from it |
| `extract` (new) | EXTRACTION (HLZ) ("need a pick up version where the pick up is the hot zone"): Pickup (required), LZ SECURITY, Marking, Passengers, Wind (autofill), Obstacles, Remarks. The full approach at the pickup, then a low hover - never touching down - until ALL IN, then home (2026-11-08: "extraction should be a low hover never touching ... then rtb on all in"; the Destination line dropped) |
| `resupply` | the items are picks of the pre-made crates ("we have pre made crates so the requested items should be a drop down of them"): messaging `choicesFrom` `logiCatalog`, filled by the composer from the logistics asset's catalog |

A battery takes all three calls for fire (an @ mention opens CFF GRID); a
transport takes `hlz`, `extract`, `casevac` and `airdrop` (an @ mention opens
LIFT REQUEST); the picker shows every card. A required exclusive tick group
(CFF's TYPE OF MISSION) is "tick one", marked once on its line in the composer.

---

## 8. Players as assets

- A player pilot or gun crew is messaged like any player; nothing changes for
  them except the new reply templates being available.
- The provider never acts on a thread addressed to a player box.
- **OPEN** (D8): should a player-crewed gun or aircraft also appear in the
  SUPPORT group of the TO picker (by role), so the JTAC finds it in one place?
  **Decided yes and built 2026-11-01** (not seen in game): a player in a crew
  seat (not a passenger) of a gun with an artillery computer is listed ARTY,
  of an aircraft with seats to carry TRANS, of any other aircraft CAS - in
  the TO picker's SUPPORT group and on the @ list, after the assets, with his
  player box `P:<uid>`, state PLAYER and his vehicle's name; no ETA (support
  README, "Assets as mailboxes"). No AI acts on his box.

---

## 9. Edge cases

| Case | Behaviour |
| --- | --- |
| Asset destroyed mid-task | provider replies `cantco` `LOST`, closes the thread |
| Two threads to one asset | second gets `cantco` `TASKED`; **OPEN** whether it queues instead |
| Sender dies / disconnects | thread stays open; anyone on FIRES with the right role may take over (claim) — existing `claimedBy` |
| Jammed / no DATA link | messaging's existing link rules apply: no link, no delivery. No special case. |
| Asset is ALiVE combat support | the ALiVE provider maps the same fields through `jmfsb_adapter_alive` (only addon that knows ALiVE) |

---

## 10. Build order

1. Template additions and changes (section 7). Run `#jmfsb msg.*` self-tests.
2. Mailboxes for assets + SUPPORT group in the TO picker (section 3, 6.1).
   **CAS built 2026-11-01** (not seen in game): the SUPPORT group lists CAS
   rows; artillery, transport and logistics are one `MAILBOX_TYPES` entry
   each (support README, "Assets as mailboxes"). **Every type listed
   2026-11-01** with the @ mentions (6.1); only CAS acts on its thread yet.
3. Provider reads `cas` threads and replies ROGER / WILCO / CANTCO / CLOSE. Test
   with one CAS module.
   **CAS built 2026-11-01** (not seen in game): the core hands a task card to
   the provider's server `thread` hook and the issuer's follow-ups to its
   `reply` hook; CLEARED HOT releases; drones, support_air CAS and ALiVE CAS /
   ATO (support README, "Acting on the thread"). The 1.1 flow is built with it:
   the `onstation` card (built in), the hold, the check-in, the
   strike from station, off station on RTB / BINGO / the thread closed
   (support_air README).
4. Safety checks (5.3) for CAS.
   **Built 2026-11-01** (not seen in game): danger close by the core's
   `dangerClose`, used by all three CAS providers.
5. Asset prompts (5.4) and `bda` for CAS.
   **Built 2026-11-01** (not seen in game): the core's `promptCleared` (60 s,
   `AWAITING CLEARED HOT`, FLASH) and `casPrompt` (`in`, `off` + `REQUEST
   BDA`, `RE-ATTACK? n store LEFT`, `n MIN ON STATION - FURTHER TASKING?`,
   `BINGO IN 2 MIN`, FLASH), D9 through `prompt` (FLASH by messaging's new
   server-only priority on `srvSubmit`); the BDA kept on the thread
   (`threadBda`) and used as the re-attack's target. Drones hold over the grid
   after the strike (time on station 30 min or a quarter tank of fuel);
   support_air's strike from station holds at the hold, a helicopter's run
   short of the target (BINGO: time on station - the module's, from the first
   pass for a helicopter - or fuel); ALiVE NEO aircraft by a watch on their
   rounds and fuel, and the BDA forwarded to ALiVE as a sitrep
   (`postReport`). A new `cas` card in the thread re-tasks. Cards `in`, `off`
   and the `bda` COUNT / RE-ATTACK lines are built in.
   Per provider: cas, support_air, adapter_alive READMEs.
6. `callforfire` + adjust replies; `shot` / `splash`; arty prompts.
   **Built 2026-11-01** (not seen in game): a CALL FOR FIRE to a virtual
   battery's box is fired from the card (the core's `readOrder` kind `fire`:
   grid / polar / shift, shell, rounds, guns, danger close 600 m, AT MY
   COMMAND, TOT); adjust rounds on the board's adjust machinery, SHOT /
   SPLASH, the 5.4 ARTY prompts with D9 (3 min `NO RESPONSE - HOLDING`, 5 min
   stand-down); follow-ups `adjust` / `ffe` / `repeat` / `checkfire` /
   `confirm` / `bda` / EOM; D6 in the core (issuer, the card's Observer, the
   FIRES net); ALiVE batteries fire one FFE mission (support_fires README,
   "Call for fire by message"; adapter_alive README). Cards `shot`, `splash`,
   `prompt`, `rtb`, `abort`, `confirm`, the `ffe` ROUNDS line, `bda` as a
   reply and D4's `hlz` Pickup line are built in.
   The reader drawing a prompt's Answers as quick replies (6.2, 7): built
   2026-11-01, not seen in game.
7. `hlz`, `casevac`, `airdrop` with their prompts.
   **Built 2026-11-01** (not seen in game): TRANSPORT, CASEVAC, AIRDROP,
   LOGISTICS (`resupply`) and QRF called by message. support_air transport:
   `hlz` (Pickup -> LZ, hot LZ waits for CONFIRM, 1 MIN - LZ STATUS? with a
   hold short, WHEELS DOWN - PAX OFF?, HOLD, RTB OR NEXT LIFT?, a NEXT LIFT
   card in the thread), `casevac` (PATIENTS ABOARD - DESTINATION?, DEFAULT the
   nearest medical facility), `airdrop` as a PARADROP (PACKAGE AWAY - CONFIRM
   RECEIPT); support_air QRF (`qrf`: link-up, WHEELS UP / DOWN, SQUAD DOWN -
   LINKED UP?); support_logistics (`resupply` by catalog name, `airdrop`
   Contents, PACKAGE AWAY - CONFIRM RECEIPT); ALiVE transport point by point.
   D9 for all (the core's `prompt`). Cards `wheelsup`, `wheelsdown`, `cold`,
   `hot`, `paxoff`, `hold`, `received`, `notfound`, `no`, `destination`, and
   `confirm` IN_PROGRESS too, are built in. Per
   provider: support_air, support_logistics, adapter_alive READMEs.
8. Thread map pin overlays (6.3); SUPPORT tile → reader (6.4).
   **6.3 built 2026-11-01** (not seen in game).
9. Remove the TAC//SUPPORT app (section 2). Grep for callers first.
   **Built 2026-11-01** (not seen in game): the app, its 87 helpers, its
   dialog, the `support` app id (MENU row, device soft key, walking-view
   button) and the board-only Danger close distance setting are gone; the
   core and every provider stay, and the core's reach fallback previews with
   an empty parameter array (tacpad_apps README, "TAC//SUPPORT — REMOVED").

Each step leaves support usable: until step 9 the old app still works.

---

## 11. Acceptance

- JTAC sends `cas` to HOG; HOG answers ROGER then WILCO with an ETA within a few seconds.
- Out-of-range asset answers CANTCO with the range in the text.
- Friendly at 250 m, DC not ticked → CANTCO `DANGER CLOSE NOT ACKNOWLEDGED`.
- CLEARED HOT quick reply appears only after WILCO; the aircraft attacks only after it.
- Arty: CFF adjust → SHOT / SPLASH → ADD 50 → SHOT / SPLASH → FFE → EOM: one thread, in order.
- RED LZ: helicopter waits for CONFIRM.
- Same request to a player pilot's box: no AI acts; the player sees the thread and replies by hand.
- After the attack the aircraft sends `REQUEST BDA`; the JTAC's BDA reply shows in the thread; with stores left the aircraft asks for further tasking.
- No CLEARED HOT for 60 s → `AWAITING CLEARED HOT` (FLASH).
- Transport asks `LZ STATUS?` 1 min out and `HOLD, RTB OR NEXT LIFT?` after pax off.
- After step 9: no reference to `fnc_appSupport` or `supportDlg` remains; the SUPPORT tile opens the reader on FIRES.

---

## 12. Open decisions

Decided (user, 2026-11-01): D1 one box per asset - the box the server
already answers, `B:SUPPORT:<assetId>` (built 2026-11-01, support README
"Threads"), display name the asset's call sign; D2 state + ETA to the
sender's grid (from `jmfsb_support_fnc_reach`); D3 whoever the CBA setting
Support tasking tag (`jmfsb_support_tag`) allows - the gate tasking already
uses. D5 and D7 carry over from DESIGN_SUPPORT_V2 (the `callforfire` card's
`dangerClose` option, 600 m; the `nineline` card, in the deck script - retired
2026-11-02, section 7).

| # | Question |
| --- | --- |
| D1 | Mailbox per asset, per type, or both - **decided: per asset** |
| D2 | ETA in the asset's contact row - **decided: state + ETA** |
| D3 | Who sees support assets in TO (role-gated or everyone) - **decided: the Support tasking tag** |

Also decided (user, 2026-11-01): **D4** a new required `Pickup` grid line on
`hlz` (map click); **D6** follow-ups are accepted from the issuer, the
`callforfire` Observer, and anyone on the FIRES net; **D8** player-crewed
guns and aircraft are listed in the SUPPORT group by role, with their player
box (no AI acts on them); **D9** 60 s without CLEARED HOT -> `AWAITING
CLEARED HOT`, 3 min silent on a prompt -> `NO RESPONSE · HOLDING`, 5 min ->
RTB.
| D4 | `hlz` pickup point: new line, sender position, or second thread |
| D5 | Artillery danger-close threshold (proposal 600 m) |
| D6 | Who may send follow-ups (issuer + observer, or anyone on FIRES) |
| D7 | 9-line template for player pilots |
| D8 | Player-crewed assets listed in the SUPPORT group |
| D9 | Prompt timeouts per asset type (proposal: 60 s cleared-hot, 3 min no-response hold, 5 min RTB) |
