# Report cards review - 2026-11-02

Review of the TAC//MSG report cards (message templates). Planning doc; the user's decisions were applied on 2026-11-02 - see section 7.

Sources read (the live deck in the database was not read):

- `D:\Git\DIVINER\addons\messaging\templates.inc.sqf.migrated` - the seeded deck.
- The 9-line MEDEVAC deck script (deleted 2026-11-02) - it replaced the `casevac` card's lines with the NATO 9-line (same id).
- The support deck script (deleted 2026-11-02) - it added `nineline`, `bda`, `resupply`, `onstation`, the support replies, and lines (hlz Pickup/Wind/Obstacles, airdrop Contents, bda Count/Re-attack).
- `addons/support/functions/fnc_builtinCards.sqf` - the mod's built-in copies (at the time the deck's card won; since 2026-11-02 the mod's own card always wins - section 7).
- `addons/pac/functions/fnc_registerTemplates.sqf` - `opord`, `mettc`.
- Readers: `support/fnc_readOrder.sqf` + key tables in `support/script_component.hpp`, `messaging/fnc_srvForward.sqf` (ALiVE), `support/fnc_lzSecurity.sqf`, `support/fnc_observer.sqf`, `support/fnc_dangerClose.sqf`, the providers (`support_air`, `support_fires`, `support_logistics`, `cas`), `support_air/fnc_checkIn.sqf`, `tacpad_apps/fnc_ticSend.sqf`.
- Composer: `tacpad/fnc_composeCard.sqf`, `fnc_composeHarvest.sqf`, `fnc_composeSend.sqf`. Engine: `messaging/fnc_validate.sqf`, `fnc_srvThreadFor.sqf`.

If the live deck was edited by hand in PAC, check it against this review before acting on it.

---

## 1. Summary

**Scope.** 18 report cards: 12 seeded, 4 added by the support script, 2 from PAC. The `casevac` card has two layouts (6-line as seeded, 9-line after the MEDEVAC deck script). Together they have 188 fields, or 205 counting both casevac layouts. There are also 32 reply cards; 14 of them have fields (16 fields in all).

**Duplicates.** 52 entries in the register (section 4):

- 8 within a card
- 25 the system already knows
- 19 across cards

**The real problems are not the duplicates.** In order of harm:

1. **Required fields block sends for no reason.**
   - The 9-line MEDEVAC forces six inputs: Lines 1, 2, 4, 6, 7, 8. Line 8 is patient nationality, which means nothing in game.
   - CALL FOR FIRE requires a typed TARGET DESCRIPTION. That is the most likely reason yesterday's call for fire would not send (section 3.6).
   - HLZ requires PICKUP, but the transport already uses the sender's position when it is empty.
2. **Contact reports cannot be acknowledged.** TIC, CONTACTREP, SITREP, MIST, DEFREP, CHECK-IN and METT-TC open an OPEN thread. ROGER, WILCO, ON TASK and CANTCO all have `allowedFrom` lists without OPEN, so the server refuses them. The deck still offers them. On a TIC, the receiver can only answer with a free-text MESSAGE.
3. **CUR LOC is offered on target grids.** It appears on CAS Line 1, CFF Warno 3A, 9-line Line 6 and BDA Target. One wrong press calls fire on the sender. `noCur` is only set on ingress and egress.
4. **Lines nobody reads.** The airdrop has two lines nobody reads (POI altitude, friendlies) and one that is only a fallback (the DZ mark). Winds are only echoed back in the WILCO. Ingress and egress are flown by a transport paradrop, but not by a logistics drop.
5. **Typed grids do not anchor the thread.** `srvThreadFor` anchors only on a position array. A grid typed by hand puts the thread's map anchor on the sender, although the support pin (`readOrder` + `gridPos`) is right.
6. **The CALL FOR FIRE defaults to ADJUST.** With no mission type ticked, the battery fires one round and waits. To the sender this looks like "it fired once and stopped".
7. **Two cards share a name.** "CONTACT REPORT (TIC)" and "CONTACTREP" (short "CONTACT") are different cards. `nineline` is short-titled "9-LINE", next to a MEDEVAC that is also a 9-line.

### Top 10 changes, ranked by typing saved and failures prevented

| # | Change | Card | Saves / prevents | Code? |
|---|---|---|---|---|
| 1 | Drop `required` on Lines 2, 4, 7 and 8; make Line 8 optional (or drop it). Leave Line 1 required and Line 6 required | casevac (9-line) | 4 forced inputs on the most urgent card | deck only |
| 2 | TARGET DESCRIPTION and OBSERVER not required. Drop the POLAR and SHIFT ticks (infer the method from the line that is filled). Drop Control E CHECK FIRE and F FIRE AGAIN (they are reply cards). State the default mission | callforfire | 1 required textarea and 2 ticks per mission; the likely send block | deck + `readOrder` (shift inference) |
| 3 | Autofill VEHICLE, DAMAGE and FUEL from the vehicle the sender is in | defrep | 3 of 4 lines, every report | composer: new autoFill sources |
| 4 | PICKUP not required (empty = your position, as the code already does) and moved to the top. Drop Line 2 NAME (the grid field's marker list does it). WIND autofilled from the game | hlz | 1 required pick, 2 typed lines | deck; composer for wind |
| 5 | Drop POI ALTITUDE, DZ MARK, FRIENDLIES and WINDS. Keep ingress/egress for a transport paradrop. Or split it: supplies go to RESUPPLY (decision 3) | airdrop | 4 typed lines that nothing uses | deck + `DROP_CARDS` |
| 6 | Let ROGER (and CLOSE) answer an OPEN thread. Trim `replyableWith` on the OPEN cards to what can be sent | roger + 7 report cards | the receiver can acknowledge at all | deck (`allowedFrom`) |
| 7 | `noCur` on every target grid | cas, callforfire, nineline, bda | fire on own position | deck |
| 8 | Drop CALL SIGN (sender is on every message). Autofill STATUS AMMO and CAS from the squad's ACE letters | sitrep, mettc | 1 line each; 2 picks | deck + `srvForward` fallback; composer for ACE |
| 9 | TARGET autofilled from the thread anchor when filed as a reply; not required then | bda | 1 required grid per BDA | composer: new autoFill source |
| 10 | Drop Line 2 MAP REFERENCE (same point as Line 1) | cas | 1 line | deck |

These come next:

- one marking list for every card
- QRF: LINE 1 optional, and add RECOGNITION SIGNALS
- SPOTREP: ACTIVITY as a pick
- merge WILCO with WILCO WITH DETAIL
- typed grids anchor the thread

### Decisions for the user

1. **Which casevac card is live: the 6-line or the 9-line MEDEVAC?** Recommendation: the 9-line only. If it is the 9-line, `#jmfsb msg.flash` and `seedTest` are broken. They file 6-line keys (`Line4.B`, `Line5.A` "SMOKE"), and the 9-line's required Line 4 is empty, so the server refuses them.
2. **Required policy.** Should the rule be "required = only what the receiver cannot act without (the location), everything else optional"?
3. **Airdrop.** Today both the logistics and the transport assets take it. Make it PARADROP (personnel or vehicles, flown by transport) and leave supplies to RESUPPLY? Or keep it for both?
4. **Two CAS cards.** Keep `cas` (quick request, AI asset) and `nineline` (player pilots), or one card?
5. **New autofill sources.** Approve the composer work for some or all of these: vehicle, vehicle damage, fuel, wind, terrain elevation at a grid, squad ACE, thread anchor, heading/distance between two grids.
6. **Doctrine vs game.** On the 9-line MEDEVAC, keep Line 8 (nationality) and the frequency half of Line 2 (VON nets)?
7. **ROGER on OPEN threads.** Add OPEN to ROGER's `allowedFrom` (the thread moves to RECEIPT), or add a no-transition ACK reply?
8. **WILCO / ON TASK.** Give the deck's `wilco` and `inprogress` an optional DETAIL line and retire `accepted` and `ontask` (duplicate cards)?
9. **Title renames (labels only, keys unchanged).**
   - TIC -> TROOPS IN CONTACT
   - CONTACTREP -> SPOTREP (SALUTE)
   - `nineline` short -> CAS 9-LINE
   - HLZ BRIEF -> LIFT REQUEST (HLZ)

   Yes or no?
10. **ADJUST FIRE.** Keep one correction per message, or take a lateral and a range correction in one card, as on the net?
11. **Reordering lines.** Line titles are keys, so moving a line breaks no reader. Approve reordering where the flow is wrong (HLZ Pickup first, CFF target first)?

---

## 2. How the cards work (the rules every proposal respects)

- **A line title is a field key.** Fields are lettered by position in the line: `Line6.B` is the second field of the line titled "Line 6".
  - Renaming a title renames the key and breaks its readers.
  - Renaming a label (the text the player sees) breaks nothing.
  - Moving a whole line breaks nothing.
- **Dropping fields.**
  - Dropping a whole line is safe at runtime. Every reader uses `getOrDefault` and gets `""` or `-1`. Old threads keep their payloads. A stale client's extra field is dropped by `validate` with an INFO line.
  - Dropping a trailing field of a line is safe.
  - Dropping a leading or middle field re-letters the rest and breaks readers. Example: dropping cas `Line6.A` would make the DANGER CLOSE tick `Line6.A`, and `STRIKE_CARDS` reads `Line6.B`.
- **What the system already knows** about every message:
  - `fromCallsign` = "group name" (server-set)
  - `sentTime` and `gameTime` (the date-time group)
  - the TO mailbox, which for a support asset is `B:SUPPORT:<id>`
  - an optional pin
  - grid fields offer CUR LOC, MAP and the marker list
- **Autofill sources that exist today:**
  - `ownCallsign` = the group id
  - `missionTime` = HHMM
  - `pac:<section>.<field>` = the OPORD

  Anything else listed here as "autofill" needs composer code (decision 5).
- **Where a change lands:**
  - the deck in the database: data edits through a `tools/pac_*.py` script
  - `fnc_builtinCards.sqf` for the built-in cards (`check_invariants.py` keeps the ids in step)
  - the seed file in DIVINER
  - `support/script_component.hpp` key tables, when a read key moves
- **Thread states.**
  - A root with `transitionsTo ISSUED` is a task.
  - A root without one is an OPEN message thread.
  - ROGER needs ISSUED. WILCO needs ISSUED or RECEIPT. ON TASK needs ACCEPTED or RECEIPT. CANTCO needs any task state. CLOSE is issuer only. MESSAGE always works.

---

## 3. Card by card

Column key for the tables:

- **Req**: R = required.
- **Fill**: AUTO = autofill, MAP = map click / CUR LOC / marker list, MK = marker name list.
- **Read by**: what consumes the key.
- **Verdict**: K = keep, D = drop, O = make optional, A = autofill, M = move, W = reword.

### 3.1 `casevac` - 9-LINE MEDEVAC (the layout after the MEDEVAC deck script)

**Purpose / doctrine.** The NATO / US 9-line MEDEVAC request. Lines 1-9 match doctrine in order and wording, including both Line 9 variants (wartime NBC / peacetime terrain). Doctrine's Lines 6 and 9 are wartime-only. Line 2's frequency is meaningless with VON nets. Line 8 (patient nationality) does nothing in game.

| Key | Label | Type | Req | Fill | Read by | Verdict |
|---|---|---|---|---|---|---|
| Line1.A | PICK-UP SITE LOCATION | grid | R | MAP | readOrder pickup, anchor, subject | K - the one field that must be required |
| Line2.A | RADIO FREQ, CALL SIGN, SUFFIX | text | R | AUTO ownCallsign | nobody (readOrder reads Line2.A as the patient count, which harmlessly parses to -1 here) | O; or D (decision 6). Duplicates the sender |
| Line3.A-E | PATIENTS BY PRECEDENCE: A URGENT, B URG-SURG, C PRIORITY, D ROUTINE, E CONVENIENCE | number x5 | - | - | readOrder urgent/priority/routine (A-C), patients = sum | K. Note: readOrder maps B (URGENT-SURGICAL) to "priority" and C (PRIORITY) to "routine" - see 3.1 receiver |
| Line4.A | SPECIAL EQUIPMENT | choice | R | - | nobody | O, default A NONE |
| Line5.A-B | PATIENTS BY TYPE: L LITTER, A AMBULATORY | number x2 | - | - | readOrder takes Line5.A as a marking candidate (skipped, a number) | K (the crew loads litters). Second count of the same patients - accept |
| Line6.A | SECURITY AT PICK-UP SITE: N/P/E/X | choice | R | - | lzSecurity: N GREEN, P YELLOW, E/X RED (hot LZ, escorts) | K, R. It decides escorts and the hot-LZ CONFIRM |
| Line7.A-B | METHOD OF MARKING + colour/detail | choice + text | R (A) | - | readOrder marking (Line 7) | O; one marking list (D45) |
| Line8.A | PATIENT NATIONALITY AND STATUS | choice | R | - | nobody | O or D (decision 6) |
| Line9.A-B | NBC + terrain/obstacles | choice + text | - | - | nobody | K |
| Remarks.A | REMARKS ("MIST, anything...") | text | - | - | readOrder remarks | W: textarea, like every other REMARKS |

**Flow under fire.** About 9 presses and choices before SEND, four of them forced by `required` (2, 4, 7, 8) though none changes what the helicopter does. With the proposal it is one map click (Line 1), one choice (Line 6), counts in Line 3, then SEND.

**Validation.**
- The precedence counts have `min 0` and no max. Add `max 99`.
- Nothing stops all-zero counts. `readOrder` then gets 0 patients. Acceptable: the crew still lifts.

**Receiver.** `CASEVAC_CARDS` reads Line 1, Line 2 (6-line count), Line 3 by letter, Line 5 or Line 7 marking, and REMARKS. **Defect:** `urgent / priority / routine = Line3 A / B / C`. On the 9-line, B is URGENT-SURGICAL and C is PRIORITY, so a 9-line's PRIORITY patients are reported as "routine". The fix is in `readOrder`: map the 9-line letters by label, or sum A+B as urgent, C as priority, D+E as routine.

**Replies / state.** A task (ISSUED). Replies: roger wilco inprogress cantco freetext close + confirm abort rtb, plus `destination` from the asset's prompt. Good. Missing: MIST in the thread (see 3.2).

**Wording.**
- Title "9-LINE MEDEVAC" and short "MEDEVAC" are right.
- Subject "MEDEVAC - {Line1.A}" should carry the count: "MEDEVAC {Line3 sum} - grid" needs a computed subject. Keep it as is.

**Revision.** Line1 R, Line2 optional AUTO, Line3 (A-E), Line4 optional, Line5, Line6 R, Line7 optional (common marking list), Line8 optional, Line9, Remarks (textarea).

### 3.2 `casevac` - 6-LINE CASEVAC (the seeded layout)

**Purpose.** An Arma-community short form, not a doctrinal report. It is superseded by the 9-line on the same id.

| Key | Label | Type | Req | Read by | Verdict |
|---|---|---|---|---|---|
| Line1.A | PICK-UP SITE LOCATION | grid | R | pickup, anchor, subject | K |
| Line2.A | NUMBER OF PATIENTS | number | R | patients (max with the Line 3 sum), subject | D or O - the same number as the Line 3 sum (D04) |
| Line3.A-C | URGENT / PRIORITY / ROUTINE | number | - | by letter | K |
| Line4.A-C | LZ SECURITY GREEN/YELLOW/RED | bool, exclusive | - | lzSecurity | K (or one choice, D46) |
| Line5.A-B | MARKING + colour | choice + text | - | marking | K |
| Remarks.A | REMARKS | textarea | - | remarks | K |

**Verdict.** Retire this layout (decision 1). One MEDEVAC card, the 9-line, with the requirements cut as in 3.1, is as fast as the 6-line and is the format pilots know. If kept, drop Line 2's `required`. The subject "CASEVAC {Line2.A} pax" then needs a new wording.

### 3.3 `mist` - MIST

**Purpose / doctrine.** The UK (AT)MIST casualty handover: Age, Time of injury, Mechanism, Injuries, Signs/symptoms, Treatment. The card folds Time into M, has no Age (fine in game), and is one card for all casualties, where doctrine has one per casualty.

| Key | Label | Type | Req | Verdict |
|---|---|---|---|---|
| M.A | MECHANISM OF INJURY & TIME | text | R | O (a handover without a known mechanism is still a handover) |
| I.A | INJURIES SUSTAINED | textarea | - | K |
| S.A | SYMPTOMS AND VITALS (A-E) | textarea | - | K; the hint "E-Everything else" overlaps REMARKS |
| T.A | TREATMENT GIVEN | textarea | - | K; ACE treatments are known to the game (future autofill, not now) |
| Remarks.A | REMARKS | textarea | - | D (S's "E" and T cover it) or K for consistency |

**Receiver.** Nobody reads any key. It is a human-to-human card.

**Overlap.** The 9-line's REMARKS hint says "MIST". MIST opens its own thread (kind root), apart from the MEDEVAC it belongs to.

**Replies / state.** An OPEN thread, so ROGER is refused (section 1, item 2).

**Revision.** Kind `both`, so it can be filed inside the MEDEVAC thread to the crew. M optional. Add an optional `Patient` line ("casualty 1 of n / name") before M so several MIST cards in one thread can be told apart. Drop REMARKS or keep it (consistency rule: "every root report ends with REMARKS" - a `both` card may skip it).

### 3.4 `tic` - CONTACT REPORT (TIC)

**Purpose.** The "contact, wait out" alarm, then: location, enemy, own casualties, intentions, assistance. It matches what a section commander says on the net. It is not a SALUTE.

| Key | Label | Type | Req | Read by | Verdict |
|---|---|---|---|---|---|
| Location.A | LOCATION ("of the contact") | grid | R | anchor, subject, srvTic marker, ticSend (GPS) | K; W the hint: the quick key sends the sender's GPS fix, so say "your position or the contact's" |
| Enemy.A | ENEMY | text | R | subject | O - the alarm with a location is already worth sending; the key fills "CONTACT - DETAILS TO FOLLOW" anyway |
| Casualties.A | FRIENDLY CASUALTIES | text | - | nobody | K; or two numbers KIA/WIA like the SITREP (D38) |
| Intentions.A | INTENTIONS | text | - | nobody | K; could be a pick: RETURNING FIRE / BREAKING CONTACT / ASSAULTING / HOLDING + text |
| Assistance.A | ASSISTANCE REQUIRED | text | - | nobody | K; could be ticks: CAS / FIRES / CASEVAC / QRF - and each tick a shortcut to that card prefilled from this one |
| Remarks.A | REMARKS | textarea | - | nobody | K |

**Flow.** The quick key (`ticSend`) is right: GPS fix plus two lines, no form. The card is for the follow-up. The follow-up should not be a second TIC. It should be a SPOTREP (CONTACTREP) inside the TIC thread, but CONTACTREP is root-only today.

**Replies / state.** An OPEN thread. ROGER, WILCO and CANTCO are offered and refused. This is the card where an acknowledgement matters most.

**Wording.** Title clash with CONTACTREP. Recommend "TROOPS IN CONTACT" with short "TIC" (decision 9).

**Revision.** Location R (MAP, CUR LOC first), Enemy optional, Casualties (KIA / WIA numbers), Intentions (pick + text), Assistance (ticks), Remarks. Keys unchanged except where Casualties grows a second field (trailing, safe).

### 3.5 `contactrep` - CONTACTREP (SALUTE)

**Purpose / doctrine.** SALUTE spot report: Size, Activity, Location, Unit/uniform, Time, Equipment. "R REMARKS" is not part of SALUTE, but it is harmless. The order and wording match.

| Key | Label | Type | Req | Read by (ALiVE spotrep) | Verdict |
|---|---|---|---|---|---|
| S.A | SIZE | text | R | size (fallback "Unknown") | K; O would be fine since ALiVE has a fallback |
| A.A | ACTIVITY | text | - | activity, upper-cased (fallback STATIC) | W to a choice: STATIC / MOVING / PATROLLING / ATTACKING / DEFENDING / OTHER, plus a text field `A.B`. ALiVE then gets a clean word |
| L.A | LOCATION | grid | R | loc (fallback the anchor), anchor, subject | K; noCur would be wrong (a spot may be at you) - keep CUR LOC |
| U.A | UNIT ("type of unit") | text | - | type, subject | W the label: "UNIT / UNIFORM" |
| T.A | TIME | time | - | dateTime (fallback NOW) | K - AUTO missionTime; the sighting time can differ from the send time (D19) |
| E.A | EQUIPMENT | textarea | - | joined into remarks | K |
| R.A | REMARKS | textarea | - | joined into remarks | K |

**Overlap.** TIC Location/Enemy, SITREP Location/Enemy (D36, D37). The difference is real: TIC = alarm, SALUTE = the detail, SITREP = own state.

**Replies / state.** An OPEN thread, so ROGER is refused. Make it kind `both`, so it can be the TIC's follow-up in the same thread. L then defaults to the thread anchor (new autofill, the same source as BDA's).

**Wording.** Title "CONTACTREP" with short "CONTACT" collides with the TIC's title. Recommend "SPOTREP (SALUTE)", short "SPOTREP".

**Revision.** S R, A (choice + text), L R, U, T AUTO, E, R. Kind `both`.

### 3.6 `callforfire` - CALL FOR FIRE

**Purpose / doctrine.** The US/NATO observer call for fire:

1. observer identification
2. warning order: type of mission, size of element, method of target location
3. target location (grid / polar / shift from a known point)
4. target description
5. method of engagement (incl. danger close)
6. method of fire and control

The card follows this order. Where it deviates:

- Location is spread over five lines (Warno 3A/3B/3C, Target 2, Target 3) with two "tick if using..." helpers.
- The shift's known point is the Warno 3A grid rather than a known-point name (accept; it is what the reader uses).
- Control E CHECK FIRE and F FIRE AGAIN are in-mission commands that now exist as reply cards. They do not belong in the initial call.

| Key | Label | Type | Req | Read by | Verdict |
|---|---|---|---|---|---|
| Observer.A | OBSERVER ID/CALL SIGN | callsign | R | observer() matches group id / name, falls back to the issuer | O (AUTO stays). Empty = the sender, as the code already does (D12) |
| Warno1.A-D | TYPE OF MISSION: adjust / FFE / suppress / immediate | bool, exclusive | - | mission; empty = ADJUST | K; W: say "empty = ADJUST FIRE (one round, then your corrections)" in the line label, or default to FFE (decision) |
| Warno2.A | SIZE OF ELEMENT TO FIRE | text | - | guns = first number; 0 = all | W: number "Guns (empty = all)" - a text box the reader mines for a number |
| Warno3A.A | TARGET LOCATION: GRID | grid | - | target; known point for a shift; anchor, subject | K; noCur; M to the top of the card - it is what the observer has first |
| Warno3B.A | POLAR tick | bool | - | method | D - fill Target 2 and it is polar (readOrder already infers polar from Target 2 when there is no grid) (D06) |
| Warno3C.A | SHIFT tick | bool | - | method | D - fill Target 3 and it is a shift (readOrder: shift when any Target 3 field is filled) (D07) |
| Target2.A-B | POLAR: direction (deg), distance (m) | number x2 | - | polar | K; W: "Direction (deg, 0-360) - mils not accepted" |
| Target3.A-C | SHIFT: lateral, range, vertical | text x3 | - | lateral (LEFT/minus), range (DROP/minus); vertical unread | K A-B; C vertical: nobody reads - keep (trailing) or D |
| Description.A | TARGET DESCRIPTION | textarea | R | WILCO words, ALiVE fire thread | O (D: the likely send block) |
| Engagement.A-F | HE / Smoke / Illum / Cluster / Laser-guided / Airburst | bool, exclusive | - | shell; empty = the battery's first | W to one choice field? No - it would re-letter `.G` rounds. Keep the ticks |
| Engagement.G | Number of rounds | number 1-200 | - | rounds per gun | K; W "per gun" (the reader treats it as per gun) |
| DangerClose.A | DANGER CLOSE tick | bool | - | dcTick - the acknowledgement | K |
| DangerClose.B | Distance to friendlies (m) | number 0-5000 | - | friendlies, if stated | K optional (trailing) - the server measures it anyway (D32) |
| Control.A-D | ready / at my command / TOT / cannot observe | bool, exclusive | - | control | K |
| Control.E-F | check fire / fire again | bool, exclusive | - | control | D - they are the CHECK FIRE and REPEAT replies (D08, D09). Trailing, so safe |
| TOT.A | TIME ON TARGET (IF C) | time | - | tot (HHMM or HH:MM); empty with C: CANTCO NO TOT | K; W the hint "HHMM"; AUTO missionTime +5 min would help |
| Remarks.A | REMARKS | textarea | - | remarks | K |

**Why a call for fire would not send (yesterday's failure, candidates in order).**

1. **TARGET DESCRIPTION is required** and is a textarea far down the card. A grid-only mission is refused with "TARGET DESCRIPTION is required". This is the most likely cause.
2. **OBSERVER is required.** It is autofilled, so it blocks only if the box was cleared.
3. **Number ranges:**
   - polar direction over 360 (a mils value) is refused
   - distance over 30000
   - rounds 0 or over 200
   - danger-close distance over 5000
4. **Not a send failure, but read as one** (the CANTCO comes back in the thread):
   - NO TARGET LOCATION: no grid and no polar distance, or a shift without the Warno 3A grid
   - DANGER CLOSE NOT ACKNOWLEDGED: any friendly unit within 600 m of the target and the tick not set. The server measures this, so the sender may not know a friendly is there
   - NO STORES SMOKE / ILLUM: the battery does not carry it
   - NO TOT: control C with an empty TOT
   - busy or out of range
5. **No mission ticked = ADJUST.** One round lands and the battery waits for ADJUST / FFE. It looks like the mission failed.

The notification beside SEND names the field ("<label> is required"). Ask the player for that text.

**Flow.** Today the observer scrolls past six lines before the target. Proposed order: TARGET (grid, or polar/shift lines) -> TYPE OF MISSION -> DESCRIPTION -> ENGAGEMENT -> DANGER CLOSE -> CONTROL / TOT -> OBSERVER (auto) -> SIZE -> REMARKS. Reordering does not change any key.

**Replies / state.** A task. Replies:

- roger wilco inprogress cantco freetext close
- adjust ffe repeat checkfire
- from the asset: shot, splash

Good. Missing:

- "END OF MISSION" by name. CLOSE THREAD does it; its OUTCOME line could be labelled "END OF MISSION - effect".
- A two-axis ADJUST (decision 10). A real correction is "RIGHT 50, ADD 100" in one transmission. Today it takes two messages.

**Wording.**
- "Warno 3A / 3B / 3C" and "Target 2 / Target 3" are cTab artifacts. There is no "Target 1". Labels should read "TARGET - GRID", "TARGET - POLAR FROM OBSERVER", "TARGET - SHIFT FROM THE GRID ABOVE".
- `dangerClose` for this card is 600 m (D8), but no hint says so. Put "600 m" in the DANGER CLOSE label.

**Revision.** In order:

1. Warno3A (TARGET GRID, noCur)
2. Target2 (POLAR)
3. Target3 (SHIFT A-B, C kept)
4. Warno1 (TYPE OF MISSION, label states the default)
5. Description (optional)
6. Engagement A-G
7. DangerClose A-B ("DANGER CLOSE - under 600 m")
8. Control A-D
9. TOT
10. Observer (AUTO, optional)
11. Warno2 (GUNS)
12. Remarks

Dropped: Warno3B, Warno3C, Control E-F.

### 3.7 `cas` - CAS REQUEST

**Purpose / doctrine.** Not a doctrinal format. It is a ground unit's request for an AI or human CAS asset, closest to the "6-line CAS" Arma groups use. Run-in as two map fixes (ingress, egress) is a good game choice. For a player pilot the doctrinal brief is the 9-line (3.13).

| Key | Label | Type | Req | Read by | Verdict |
|---|---|---|---|---|---|
| Line1.A | GRID REFERENCE (target) | grid | R | target, anchor, subject | K; noCur; W "TARGET LOCATION" |
| Line2.A | MAP REFERENCE | text | - | label, appended to the WILCO description | D - the same point as Line 1, and the grid field already offers the marker list (D01) |
| Line3.A | INGRESS LOCATION | grid, noCur | - | ingress (AI flies it) | K |
| Line4.A | EGRESS LOCATION | grid, noCur | - | egress (AI flies it) | K |
| Line5.A | TARGET DESCRIPTION | textarea | R | description (WILCO, ALiVE, BDA) | K R - a pilot needs it. W the hint "what, how many, moving?" |
| Line6.A | RANGE FROM FRIENDLIES (m) | number 0-10000 | - | friendlies (danger close if under the threshold) | K optional - the server measures it (D31). Leading field: cannot be dropped without re-lettering the tick |
| Line6.B | DANGER CLOSE ("Under 300 m") | bool | - | dcTick - the acknowledgement | K |
| Line7.A-B | MARKED BY + colour/code | choice + text | - | mark (LASER needs a laser-capable store: else "cannot lase <code>"), code | K; one marking list (D45). W: "code" means laser code - say "Colour / laser code (4 digits)" |
| Optional.A | PREFERRED MUNITIONS | text | - | munition | K; W the title "Optional" is a poor key but cannot be renamed. Label it "MUNITIONS (optional)" |
| Remarks.A | REMARKS | textarea | - | remarks | K |

**Flow.** Map click target -> description -> SEND is the fast path. Good once Line 2 is gone.

**Receiver.**
- A fixed-wing that is not on station refuses: "NOT ON STATION". The sender has to file REQUEST ON STATION first.
- The TO picker opens `onstation` for such an asset (MAILBOX_CARD_STATION). Good, but the CANTCO wording should say "REQUEST ON STATION FIRST".

**Replies / state.** A task + clearedhot; asset prompts in, off, bda. Good.

**Wording.** "Under 300m is DANGER CLOSE!" appears in two places. The card's own `dangerClose` option is the truth. Keep one place: the tick's label.

**Revision.** Line1 R noCur, Line5 R, Line3, Line4, Line6 A-B, Line7, Optional, Remarks (moved so the target and description come first). Line2 dropped.

### 3.8 `checkin` - AIRFRAME CHECK-IN

**Purpose / doctrine.** The JFIRE aircraft check-in: mission number / call sign, number and type, position and altitude, ordnance, playtime (time on station), abort code, capabilities. It matches. **Missing:** CAPABILITIES (FMV / laser / IR pointer / NVG) and LASER CODE. A JTAC asks for both.

| Key | Label | Type | Req | Read by | Verdict |
|---|---|---|---|---|---|
| Line1.A | AIRFRAME CALL SIGN | callsign | R | subject; filled by the provider for an AI asset | O (AUTO stays) (D13) |
| Line2.A | NUMBER AND TYPE | text | - | subject; provider fills | K |
| Line3.A-B | POSITION, ALT (m) | grid + number | - | anchor; provider fills | K; a pilot uses CUR LOC; ALT could be AUTO (own altitude) |
| Line4.A | ORDNANCE | textarea | - | provider fills | K |
| Line5.A | TIME ON STATION | text | - | provider fills "n MIN" | W number (minutes), matching onstation Line 1 |
| Line6.A | ABORT CODE | text | - | provider fills | K |
| Line7.A | REMARKS | text | - | provider fills | K - key `Line7` not `Remarks` (cannot rename). W type textarea |

**Overlap.** It answers `onstation` (D52). That is a question and its answer, not a duplicate.

**Replies / state.** Filed by the asset inside the on-station thread, so it is fine there. Filed by a player pilot as a root it opens an OPEN thread, and ROGER is refused.

**Revision.** Add `Capabilities` (ticks: FMV, LASER, IR, NVG) and `Laser` (code, number 1111-1788) before Line 7. Line 5 becomes a number.

### 3.9 `hlz` - HLZ BRIEF

**Purpose / doctrine.** Today the card is two things:

- The HLZ brief (LZ location, name/marking, security, marking, approach and departure, wind, obstacles). That describes one landing zone.
- With D4's PICKUP line, it is also a lift request: pickup -> HLZ.

The labels still say "brief" and "EXTRACT CONTENTS", which reads as if the HLZ were the pickup. **Players will put the pickup grid in Line 1.**

| Key | Label | Type | Req | Read by | Verdict |
|---|---|---|---|---|---|
| Line1.A | HLZ LOCATION | grid | R | lz (destination), anchor, subject | K R; W "DROP-OFF LZ" |
| Line2.A | LZ/DZ NAME / MAP MARKING | text MK | - | lzName (no consumer), lz fallback | D (D02); subject loses it -> "LIFT {Pickup.A} - {Line1.A}" |
| Line3.A | EXTRACT CONTENTS | text | - | carry (in the WILCO words) | K; W "PASSENGERS / LOAD" (number of pax would be better: number + text, trailing) |
| Line4.A-C | SECURITY GREEN/YELLOW/RED | bool, exclusive | - | lzSecurity (escorts; RED = hot LZ, CONFIRM) | K - but of which LZ? It is read as one value. W "SECURITY AT THE DROP-OFF" |
| Line5.A-B | MARKING + colour/code/location | choice + text | - | marking (smoke / strobe the AI looks for) | K; one list (D45) |
| Line6.A | INGRESS | grid noCur | - | lzVia (flown) | K |
| Line7.A | EGRESS | grid noCur | - | flown on the way out | K |
| Pickup.A | PICKUP | grid | R | pickup; empty = the issuer's position (liftLegs) | O; M to the top; CUR LOC (D34) |
| Wind.A | WIND | text | - | wind (no consumer) | D, or AUTO from the game wind (D27) |
| Obstacles.A | OBSTACLES | text | - | obstacles (no consumer) | K - human information for a player pilot |
| Remarks.A | REMARKS | textarea | - | remarks | K |

**Flow.** Proposed: PICKUP (CUR LOC, already the default) -> DROP-OFF LZ (map) -> LOAD -> SECURITY -> MARKING -> SEND. Ingress, egress, wind and obstacles are for a player pilot or a careful JTAC.

**Replies / state.** A task + confirm abort rtb; asset prompts cold, hot, paxoff, wheelsup, wheelsdown. Good.

**Overlap.** CASEVAC pickup/security/marking (D45, D46). AIRDROP ingress/egress and wind (D26, D27).

**Revision.** In order:

1. Pickup (optional, CUR LOC, "empty = your position")
2. Line1 R ("DROP-OFF LZ")
3. Line3 ("LOAD")
4. Line4 ("SECURITY AT DROP-OFF")
5. Line5 (marking)
6. Line6, Line7
7. Obstacles
8. Wind (AUTO, or dropped)
9. Remarks

Title "LIFT REQUEST (HLZ)" (decision 9). Line2 dropped.

### 3.10 `airdrop` - AIRDROP BRIEF

**Purpose / doctrine.** A DZ brief: point of impact, DZ name/mark, friendlies, surface winds, run-in. With `Contents` it is also a supply request. Two assets take it:

- logistics: supplies by catalog name
- transport: paradrop (`liftLegs` ORDER_DROP)

| Key | Label | Type | Req | Read by | Verdict |
|---|---|---|---|---|---|
| Line1.A | POINT OF IMPACT | grid | R | point, anchor, subject | K |
| Line2.A | POI ALTITUDE (m) | number | - | nobody | D - terrain height is known (D24) |
| Line3.A | DZ DESCRIPTION / MARK | text MK | - | dzName (no consumer), point fallback | D (D03) |
| Line4.A | FRIENDLIES LOCATION / MARK | text MK | - | nobody | D - BFT knows (D25) |
| Line5.A | SURFACE WINDS | text | - | winds, echoed in the WILCO only | D or AUTO (D26) |
| Line6.A | INGRESS | grid noCur | - | flown by a transport paradrop (liftJob -> lzVia); **not flown** by logistics ("legs are the module's") | K for paradrop |
| Line7.A | EGRESS | grid noCur | - | transport: flown on the way out; logistics: not | K for paradrop |
| Contents.A | CONTENTS | text | - | contents: "2 x HUNTER, CRATE" parsed against the catalog; empty = first item | W - free text that must match catalog names; a mismatch is CANTCO NO STORES <NAME> |
| Remarks.A | REMARKS | textarea | - | remarks | K |

**Verdict.** Four of the nine lines do nothing: altitude, friendlies, winds, and the mark (which is only a fallback). RESUPPLY with METHOD = AIRDROP already does the supply case, with counted items and catalog checking. Decision 3: keep `airdrop` as PARADROP for transport (personnel or vehicle out of the cabin) and send supplies through RESUPPLY.

**Revision (as PARADROP).** Line1 R, Contents ("LOAD"), Marking (new line, common list), Line6, Line7, Remarks. Dropped: Line2, Line3, Line4, Line5. The `DROP_CARDS` keys for Line3 and Line5 become "" (the readers tolerate it).

### 3.11 `defrep` - VEHICLE REPORT (DEFREP)

**Purpose.** A vehicle state report: damage, equipment, fuel, coloured GREEN-BLACK. It is not a doctrinal format (closest: a LOGSTAT line or a "vehicle status" in a SITREP). The precedent in this mod: the ACE report was removed because the screen carries the state live. Damage and fuel are things the engine knows exactly.

| Key | Label | Type | Req | Read by | Verdict |
|---|---|---|---|---|---|
| Vehicle.A | VEHICLE (call sign / type) | text | R | subject | A from the vehicle the sender is in (D16); O |
| Line1.A-D | DAMAGE G/Y/R/B | bool, exclusive | - | nobody | A from vehicle damage (D17); player may override |
| Line2.A-D | EQUIPMENT G/Y/R/B | bool, exclusive | - | nobody | K - "optic out" is not known to the engine |
| Line3.A-D | FUEL G/Y/R/B (>1/2, <1/2, <1/4, empty) | bool, exclusive | - | nobody | A from `fuel` (D18) |
| Remarks.A | REMARKS | textarea | - | - | K |
| Command.A | ROUTING: also to the command group | bool | - | `routing` option -> srvDeliver | K |

**Flow.** Today: type the vehicle, three ticks, SEND. With autofill: check, SEND.

**Replies / state.** An OPEN thread; ROGER is refused. A DEFREP that asks for recovery has no task to accept. A RECOVERY / REPAIR request is a gap for later, not this review.

**Wording.**
- "DEFREP" is not a term players know. Title "VEHICLE STATUS", short "VEH STATUS".
- The colour meanings differ per line. Fine, but the labels should put the meaning first ("1/2+ FUEL") so the colour is secondary.

**Revision.** Vehicle (AUTO, optional), Line1 (AUTO), Line2, Line3 (AUTO), Remarks, Command.

### 3.12 `qrf` - REACT/QRF LINK-UP

**Purpose / doctrine.** A link-up plan: who, link-up point, route, attachments, actions on arrival. **Missing the most important link-up element: RECOGNITION SIGNALS** (far and near). A link-up without them is how blue-on-blue happens.

| Key | Label | Type | Req | Read by | Verdict |
|---|---|---|---|---|---|
| Line1.A | WHO LINKS WITH WHO | text | R | who (WILCO words), subject | O - it is the sender and the QRF it is addressed to (D15) |
| Line2.A | LINK-UP LOCATION | grid | R | linkup, anchor, subject | K |
| Line3.A | SUGGESTED ROUTE | text | - | route (scanned for words) | K; could be grids, but text is right for "via MSR TAMPA" |
| Line4.A | SPECIAL ATTACHMENTS | text | - | attachments (scanned) | K |
| Line5.A | ACTION ON ARRIVAL | text | - | action, upper-cased, decides the task | W to a pick: CORDON / BLOCK / CCP / REINFORCE / ASSAULT + text. The provider reads a word, so a pick makes it reliable |
| Remarks.A | REMARKS | textarea | - | remarks | K |

**Revision.** Line2 R, Line5 (choice + text), Signals (new: far / near, text), Line3, Line4, Line1 (optional), Remarks.

### 3.13 `nineline` - CAS 9-LINE

**Purpose / doctrine.** The JTAC-to-pilot CAS brief (JP 3-09.3): IP/BP, heading (+offset), distance, target elevation, description, location, mark (+code), friendlies, egress, then remarks and restrictions. It matches line for line, in metres (deliberate).

Doctrine's remarks/restrictions carry: final attack heading, danger close (with the ground commander's initials), laser-target line, ACA, threats. The card leaves danger close to typed words in REMARKS. That is inconsistent with CAS and CFF, which have a tick.

| Key | Label | Type | Req | Read by | Verdict |
|---|---|---|---|---|---|
| Line1.A | IP / BP | text MK | - | ingress (as a marker or grid) | K |
| Line2.A-B | HEADING (deg) + OFFSET | number + choice | - | nobody | A: heading from Line1 to Line6 when both are set (D29); K for a pilot |
| Line3.A | DISTANCE (m) | number | - | nobody | A: same (D29) |
| Line4.A | TARGET ELEVATION (m ASL) | number | - | nobody | A from terrain at Line 6 (D28) |
| Line5.A | TARGET DESCRIPTION | textarea | R | description | K |
| Line6.A | TARGET LOCATION | grid | R | target, anchor, subject | K; noCur |
| Line7.A-B | TYPE OF MARK + colour/laser code | choice + text | - | mark, code | K; one list (D45) |
| Line8.A-B | FRIENDLIES: direction from target + distance (m) | choice + number | - | friendlies = Line8.B | K for a pilot; the server measures for AI (D30) |
| Line9.A | EGRESS | grid noCur | - | egress | K |
| Remarks.A | REMARKS ("...danger close") | textarea | - | remarks; "DANGER CLOSE" in it = dcTick | K; add a tick line |

**Flow.** A JTAC reads the 9-line top to bottom on the net. In the composer, Line 6 (map) and Line 5 come first in practice. Lines 2-4 are arithmetic once Lines 1 and 6 exist, so autofill them.

**Wording.**
- Short "9-LINE" clashes with the 9-LINE MEDEVAC. Use "CAS 9-LINE".
- Add a `DangerClose` line (tick) after Line 9. That is a new key, so it needs `STRIKE_CARDS` to name `DangerClose.A` as the nineline's tick and keep the REMARKS words as a fallback.

**Revision.** Line1-Line9 as is (Lines 2-4 AUTO when possible, Line6 noCur), DangerClose (tick, new), Remarks.

### 3.14 `bda` - BATTLE DAMAGE ASSESSMENT

**Purpose / doctrine.** The BDA the JTAC or observer passes after a strike: target location, effect, count, re-attack. It matches the short form. Doctrine adds time and mission number; the thread carries both.

| Key | Label | Type | Req | Read by | Verdict |
|---|---|---|---|---|---|
| Target.A | TARGET LOCATION | grid | R | target, targetText, anchor, subject | In a thread (the usual case: answering REQUEST BDA): A from the thread anchor, not required (D33). As a root: R. noCur |
| Result.A | RESULT | choice | - | effect | K - consider R: a BDA without a result says nothing |
| Count.A | COUNT | number | - | count | K; W "How many destroyed / damaged" |
| Reattack.A | RE-ATTACK | bool | - | reattack | K |
| Remarks.A | REMARKS | textarea | - | remarks | K |

**Replies / state.** Kind `both`, `allowedFrom` ACCEPTED / IN_PROGRESS. Right.

**Revision.** Target (AUTO thread anchor, optional), Result R, Count, Reattack, Remarks.

Making Target required only as a root would need a "required unless in a thread" option that the engine does not have. Optional is enough: the reader already tolerates an empty target.

### 3.15 `resupply` - RESUPPLY REQUEST

**Purpose / doctrine.** A LOGREQ: items and counts, delivery point, method, marking. Good shape.

| Key | Label | Type | Req | Read by | Verdict |
|---|---|---|---|---|---|
| Item1-4.A | ITEM n: catalog item | text | R (1) | items, matched against the catalog | W - typed names must match the catalog, and a mismatch is CANTCO "NO STORES <NAME>". A pick from the asset's catalog is the real fix (needs a dynamic `choices` source). Until then, the hint should list how to see the catalog |
| Item1-4.B | COUNT | number, min 1 | R (1) | count; empty = 1 | O on Item 1 - the reader already treats empty as 1 |
| Location.A | DELIVERY POINT | grid | R | point, anchor | K; CUR LOC is fine |
| Method.A | AIRDROP / SLING | choice | R | method; empty = the module's first | O - the reader has a default |
| Marking.A-B | MARKING + colour | choice + text | - | marking, colour (smoke and chemlight colours) | K; one list (D45) |
| Remarks.A | REMARKS ("threats, wind, who receives") | textarea | - | remarks | K; W drop "wind" from the hint (D26) |

**Revision.** Item1 (name R, count optional), Item2-4, Location R, Method (optional), Marking, Remarks.

### 3.16 `onstation` - REQUEST ON STATION

**Purpose.** Ask a fixed-wing to launch and hold. Not doctrinal (it stands in for an air support request), but minimal and right.

| Key | Label | Type | Req | Read by | Verdict |
|---|---|---|---|---|---|
| Line1.A | TIME ON STATION (MIN) | number 1-120 | - | minutes; empty = the aircraft's | K |
| Line2.A | GENERAL AREA | grid | - | area; empty = your position | K |
| Remarks.A | REMARKS | textarea | - | remarks | K |

No change. It is the model the others should follow: every field optional, with a stated default.

### 3.17 `sitrep` - SITREP

**Purpose / doctrine.** The SITREP's US form is: DTG, reporting unit, location, activity, effective strength, enemy, friendly, admin/log, assessment. The card covers unit, location, enemy, friendly, civil, a status block (ammo, casualty state, vehicles, combat effectiveness - the LACE / ACE idea), and remarks. Fair for the game.

| Key | Label | Type | Req | Read by (ALiVE sitrep) | Verdict |
|---|---|---|---|---|---|
| Callsign.A | CALL SIGN | callsign | - | callsign (fallback ""), subject | D (D10); the forwarder falls back to the sender's group id (one line in `srvForward`); subject "SITREP {Location.A}" |
| Location.A | LOCATION | grid | - | loc (fallback the anchor / the sender), anchor, subject | K; CUR LOC |
| Enemy.A-B | ENEMY: text, EKIA | text + number | - | en, ekia | K |
| Friendly.A-C | FRIENDLY: text, FKIA, FWIA | text + numbers | - | ff, fkia, fwia | K |
| Civ.A | CIVILIAN | text | - | civ | K |
| Status.A | AMMO | choice | - | ammo (fallback GREEN) | A from the squad's reported ACE "A" (worst of the group) (D21) |
| Status.B | CAS (medical) | choice | - | cas | A from ACE "C" (D22) |
| Status.C | VEH | choice | - | veh | K |
| Status.D | CE (combat effectiveness) | choice | - | cs | K |
| Remarks.A | REMARKS | textarea | - | remarks | K |

**Replies / state.** Kind `both`. As a root it is OPEN, so ROGER is refused.

**Wording.**
- The line label says "GREEN/AMBER/RED/BLACK"; the ACE app and DEFREP say YELLOW. Pick one word (AMBER or YELLOW) across the suite.
- `ALiVE` takes the choice words as they are; check what ALiVE expects before changing.

**Revision.** Location, Enemy A-B, Friendly A-C, Civ, Status A-D (A-B AUTO), Remarks. Callsign dropped.

### 3.18 `opord` and `mettc` (PAC)

`opord` - filled by PAC's OPORD post, not typed.
- `Header.B` DATE duplicates the DTG (D20); AUTO it, or drop it.
- Paragraph 3 (Execution) is merged into "2. MISSION AND EXECUTION", so the numbering jumps 2 -> 4. Relabel "2-3." or split.

`mettc` - METT-TC estimate, leader only.
- `Callsign.A` duplicates the sender (D11). Drop it and change the subject to "METT-TC {Mission.A}".
- The rest is doctrinal and good. M, E and C prefill from the OPORD.

### 3.19 Reply cards

| Card | Fields | Finding | Proposal |
|---|---|---|---|
| roger | - | `allowedFrom` ISSUED only: refused on every OPEN thread (TIC, SPOTREP, SITREP, MIST, VEH STATUS, CHECK-IN, METT-TC) | add OPEN (decision 7) |
| wilco / accepted | - / DETAIL | the same reply twice; `srvReply` picks the one with a line | give `wilco` an optional DETAIL (`Text.A`); retire `accepted` (decision 8) |
| inprogress / ontask | - / DETAIL | same | same |
| cantco | Reason R | fine | K |
| freetext | Text R | also the CASEVAC DESTINATION answer | K |
| close | Outcome | the fires END OF MISSION | W the label "OUTCOME / END OF MISSION" |
| adjust | Direction R, Distance R | one axis per message | two lines: LATERAL (L/R + m), RANGE (ADD/DROP + m), either optional (decision 10) |
| ffe | Rounds | fine | K |
| shot, splash, wheelsup, wheelsdown | Text "TEXT" | same key `Text.A` as DETAIL on inbound/accepted/ontask | W one label: "DETAIL" everywhere |
| prompt | Text R, Answers | Answers is machine data (reply ids) shown to a player who files by hand | W the hint "asset use - leave empty" |
| destination | Destination grid | fine; empty = DEFAULT | K |
| repeat, checkfire, clearedhot, rtb, abort, confirm, cold, hot, paxoff, hold, received, notfound, no, in, off | - | fine | K |

Missing on the net:

- SAY AGAIN: ask for a repeat of a garbled card.
- An ACK for OPEN threads (decision 7).

---

## 4. Duplicate register

Within-card = (a); across cards = (b); system already knows = (c).

| ID | Card | Field(s) | Kind | Duplicates | Proposal | Impact |
|---|---|---|---|---|---|---|
| D01 | cas | Line2.A map reference | a | Line1 point | drop | `label` "" (WILCO loses the bracket); keys unchanged |
| D02 | hlz | Line2.A name/marking | a | Line1 point | drop | `lzName` "" (no consumer); `lz` loses the marker fallback; subject must change |
| D03 | airdrop | Line3.A DZ mark | a | Line1 point | drop | `dzName` "" (no consumer); `point` fallback lost |
| D04 | casevac 6-line | Line2.A patient count | a | sum of Line3 | drop / optional | readOrder already uses max(count, sum); subject uses it |
| D05 | casevac 9-line | Line5.A-B litter/ambulatory | a | Line3 total | keep | doctrinal; the crew needs litter count |
| D06 | callforfire | Warno3B.A polar tick | a | Target2 filled | drop | `FIRE_CARDS` key ""; readOrder already infers polar |
| D07 | callforfire | Warno3C.A shift tick | a | Target3 filled | drop | readOrder: infer shift from Target3 (small change) |
| D08 | callforfire | Control.E check fire | b | reply `checkfire` | drop | trailing; `FIRE_CONTROLS` entry unused |
| D09 | callforfire | Control.F fire again | b | reply `repeat` | drop | trailing; same |
| D10 | sitrep | Callsign.A | c | fromCallsign | drop | `srvForward` fallback groupId; subject change |
| D11 | mettc | Callsign.A | c | fromCallsign | drop | subject change (PAC code) |
| D12 | callforfire | Observer.A | c | sender | optional, AUTO kept | observer() already falls back to the issuer |
| D13 | checkin | Line1.A | c | sender / asset | optional, AUTO kept | provider still writes it |
| D14 | casevac 9-line | Line2.A call sign/freq | c | sender | optional (decision 6) | readOrder reads Line2.A as the count (harmless) |
| D15 | qrf | Line1.A who | c | sender + addressed asset | optional | `who` "" in the WILCO words; subject change |
| D16 | defrep | Vehicle.A | c | `vehicle player` | AUTO, optional | subject |
| D17 | defrep | Line1 damage | c | vehicle damage | AUTO | none read |
| D18 | defrep | Line3 fuel | c | `fuel` | AUTO | none read |
| D19 | contactrep | T.A time | c | gameTime | keep (AUTO) | ALiVE dateTime; sighting time may differ |
| D20 | opord | Header.B date | c | gameTime | AUTO / drop | none read |
| D21 | sitrep | Status.A ammo | c | squad ACE "A" | AUTO | ALiVE ammo |
| D22 | sitrep | Status.B casualty state | c | squad ACE "C" | AUTO | ALiVE cas |
| D23 | sitrep | Friendly.B-C vs Status.B | a | the same casualties, as numbers and as a colour | keep both | ALiVE takes both |
| D24 | airdrop | Line2.A POI altitude | c | terrain height | drop | none read |
| D25 | airdrop | Line4.A friendlies | c | BFT | drop | none read |
| D26 | airdrop | Line5.A winds | c | game wind | drop / AUTO | WILCO echo only |
| D27 | hlz | Wind.A | c | game wind | drop / AUTO | none consumed |
| D28 | nineline | Line4.A elevation | c | terrain at Line6 | AUTO | none read |
| D29 | nineline | Line2.A, Line3.A heading/distance | c | Line1 -> Line6 | AUTO | none read |
| D30 | nineline | Line8.A-B friendlies | c | server measures | keep (pilot) | friendlies = Line8.B |
| D31 | cas | Line6.A range from friendlies | c | server measures | keep optional (leading field) | friendlies |
| D32 | callforfire | DangerClose.B distance | c | server measures | keep optional | friendlies |
| D33 | bda | Target.A (as a reply) | c | thread anchor | AUTO, optional | target / subject / anchor |
| D34 | hlz | Pickup.A required | c | issuer position (code default) | optional, move to top | none (code already defaults) |
| D35 | sitrep | Location.A | c | sender position | keep (already optional, CUR LOC) | ALiVE fallback exists |
| D36 | tic / contactrep / sitrep | Location / L / Location | b | one place, three cards | SPOTREP and SITREP filed inside the TIC thread, location AUTO from the anchor | kind `both` on contactrep |
| D37 | tic / contactrep / sitrep | Enemy / S, A, U, E / Enemy.A | b | the enemy, three times | keep; TIC short, SPOTREP the detail | - |
| D38 | tic / sitrep | Casualties (text) / FKIA, FWIA | b | own casualties | TIC to two numbers | trailing field added |
| D39 | cas / nineline | Line1 / Line6 target | b | same request | decision 4 | - |
| D40 | cas / nineline | Line5 description (same key) | b | | decision 4 | - |
| D41 | cas / nineline | Line7 mark + code (same key) | b | | decision 4 | - |
| D42 | cas / nineline | Line4 / Line9 egress | b | | decision 4 | - |
| D43 | cas / nineline | Line3 ingress / Line1 IP | b | | decision 4 | - |
| D44 | cas / nineline | Line6 / Line8 friendlies | b | | decision 4 | - |
| D45 | casevac 6/9, hlz, resupply, cas, nineline | marking lists | b | five different lists: "CHEM-LIGHT" vs "CHEMLIGHT", "A PANELS" vs "PANEL", FLARE on one only | one list per kind (ground-to-air: SMOKE, IR STROBE, PANEL, CHEMLIGHT, FLARE, NONE, OTHER; target marks: SMOKE, LASER, IR, TRACER, NONE) | the providers upper-case the word; check `MARK_CLASSES` / colour tables in support_logistics and support_air before renaming a word |
| D46 | casevac 6-line, casevac 9-line, hlz | security | b | ticks vs N/P/E/X choice | keep (lzSecurity reads both) | - |
| D47 | hlz, airdrop, resupply | Line3 load / Contents / Items | b | what is carried | keep per card; airdrop per decision 3 | - |
| D48 | airdrop vs resupply | the whole card (METHOD AIRDROP) | b | supplies by air | decision 3 | `DROP_CARDS`, `MAILBOX_TYPES` logistics |
| D49 | hlz / casevac 9-line | Obstacles / Line9.B terrain | b | hazards at the LZ | keep (different cards, same words fine) | - |
| D50 | mist / casevac 9-line | the MIST card / Remarks "MIST" | b | casualty detail | MIST filed in the MEDEVAC thread (kind `both`) | - |
| D51 | casevac 6-line / 9-line | whole card, same id | b | | decision 1 | test commands |
| D52 | checkin / onstation | Line5 / Line1 time on station | b | question and answer | keep | - |

Totals:

- (a) within a card: 8 (D01-D07, D23)
- (c) system already knows: 25 (D10-D22, D24-D35)
- (b) across cards: 19 (D08, D09, D36-D52)

Proposals:

- drop: 11
- drop or autofill: 4 (D04, D20, D26, D27)
- optional: 5
- autofill: 8
- restructure: 4 (D36, D38, D45, D50)
- wait on a decision: 8 (D39-D44, D48, D51)
- keep: 12

---

## 5. Rules for the whole deck

1. **Required = the receiver cannot act without it.** That is the location, on every card. Everything else is optional with a stated default, as on `onstation`. Today 29 fields are required (counting the 9-line casevac); under this rule it would be about 14. The location stays required everywhere except CALL FOR FIRE, which can be polar.
2. **No CUR LOC on a target.** Set `noCur` on the target grids of cas, callforfire, nineline and bda.
3. **One marking vocabulary** (D45).
4. **One colour word** (AMBER or YELLOW) across SITREP, DEFREP and ACE.
5. **REMARKS last, always a textarea, always titled "Remarks".** CHECK-IN's `Line7` and the 9-line's `text` are the exceptions. They are fixed in type and label only, since keys cannot change.
6. **Line labels say the unit and the default.** "(m)", "(min)", "HHMM", "empty = your position", "under 600 m".
7. **Picks over typing** wherever a reader looks for a word: ACTIVITY (SPOTREP), ACTION ON ARRIVAL (QRF), GUNS (CFF), resupply items (catalog).
8. **New cards get semantic line titles** (`Target`, `Pickup`), never `Line N`. A `Line N` title cannot be renumbered without breaking a reader.
9. **Typed grids should anchor.** `srvThreadFor` should parse a typed grid as `readOrder`'s `gridPos` does, so the thread's map anchor is the target and not the sender.
10. **Built-in and deck stay in step.** Superseded 2026-11-02: every card the mod defines is built in and always wins; the deck adds only ids the mod does not have.

---

## 6. Order of work, once decided

1. **Card changes** (planned as a deck script; since 2026-11-02 they are the mod's built-in cards, which always win), plus the matching edits in the DIVINER seed:
   - required flags
   - `noCur`
   - dropped trailing fields and whole lines
   - labels, hints and titles
   - line order
   - `allowedFrom` on roger
2. **Reader changes:**
   - `readOrder`: shift inference, 9-line precedence letters
   - `STRIKE_CARDS`: nineline DC tick
   - `srvForward`: call sign fallback
   - `srvThreadFor`: typed-grid anchor
   - `#jmfsb msg.flash` and `seedTest` updated to the live casevac layout
3. **Composer autofill sources** (decision 5), one at a time: thread anchor, vehicle/damage/fuel, squad ACE, terrain/heading/distance, wind.
4. **Bigger items, later:**
   - catalog picks on RESUPPLY
   - two-axis ADJUST
   - the QRF signals line
   - CHECK-IN capabilities
   - MIST as `both`

---

## 7. Applied 2026-11-02

The user's decisions: CASEVAC the 6-line only; required = only what the receiver cannot act without; ROGER answers any
open report; the rest as recommended here (both CAS cards kept, AIRDROP a paradrop, the autofills, the renames,
reordering, ADJUST two-axis, the top 10, `noCur` on every target, typed grids anchor, the test commands, the doctrine
gaps). Built, not seen in game.

**MIST and CONTACTREP (SALUTE) are kept as they are** (user, 2026-11-02: "SALUTE and mist need to stay they are - the
original way not shortened"). The script no longer touches them: no SPOTREP rename, no ACTIVITY pick, no Patient line,
no autofill, their reply list and kind unchanged. The proposals for them in section 3 are withdrawn. CONTACTREP's
title (and short title) becomes **SALUTE** (user: "CONTACTREP call it a salute") - the name only.

**One CAS card: CAS REQUEST** (user, 2026-11-02: "CAS REQUEST and CAS 9-line do not need both" - CAS REQUEST stays).
The `nineline` card is retired (reverses decision D3 of DESIGN_SUPPORT_V2 and decision 4 of this review).

**TROOPS IN CONTACT stays quick and simple** (user, 2026-11-02: "TROOPS IN CONTACT is meant to be a quick simple, most
of the time only the button will be pressed"): its seeded plain lines, no casualty counts, no intentions pick, no
assistance ticks; only LOCATION is required (the TIC key fills it), so ENEMY is optional. The title TROOPS IN CONTACT
and the ROGER reply stay. After contact the sender is prompted for a SITREP (below, the same day).

**How it reaches the game.** With the mod (user, 2026-11-02: nobody runs a script against the database): every
card below is built in - messaging `fnc_builtinCards.sqf` (reports, common replies), support `fnc_builtinCards.sqf`
/ `fnc_builtinFires.sqf` / `fnc_builtinReplies.sqf`, PAC `fnc_registerTemplates.sqf` (METT-TC) - and the mod's own
card always wins; the deck's copy of a built-in or retired id is skipped. No line title a reader uses was renamed.

Per card (D = line dropped, O = made optional, A = autofilled, R = renamed / relabelled, M = moved, + = added):

| Card | Changes |
|---|---|
| `casevac` | The 6-LINE CASEVAC put back (the 9-line MEDEVAC retired). O Line 2 (empty = the sum of Line 3). Marking: the ground-to-air list. Subject `CASEVAC <grid>` |
| `mist` | + Patient (first). O M. Kind `both` (filed inside the MEDEVAC/CASEVAC thread). Replies roger / freetext / close |
| `tic` | R title TROOPS IN CONTACT. O Enemy. Casualties two numbers (KIA, WIA). Intentions a pick + detail. Assistance ticks CAS / FIRES / CASEVAC / QRF + text. Location hint "your position or the contact's". Replies roger / freetext / close |
| `contactrep` | R title SPOTREP (SALUTE), short SPOTREP. Activity a pick + detail. A Location from the thread when filed in one. R U UNIT / UNIFORM. Kind `both`. Replies roger / freetext / close |
| `sitrep` | D Callsign (the ALiVE forwarder sends the sender's group id). A Status AMMO and CAS from the squad's ACE A and C. Subject `SITREP <grid>`. Replies roger / freetext / close |
| `callforfire` | (Later the same day it became CFF GRID - below.) M target first (grid, polar, shift), then mission, description, engagement, danger close, control, TOT, observer, guns. D Warno 3B / 3C (the method is the line that is filled), Control E / F. O Description, Observer. R labels: TARGET - GRID / POLAR FROM OBSERVER / SHIFT FROM THE GRID ABOVE, TYPE OF MISSION states EMPTY = ADJUST FIRE, DANGER CLOSE states the card's distance, GUNS a number. `noCur` on the grid |
| `cas` | M target and description first. D Line 2 MAP REFERENCE. `noCur` on Line 1. R Line 6 FRIENDLIES / DANGER CLOSE (the one place that says 300 m), Line 7 code = laser code, Optional MUNITIONS (OPTIONAL). Target marks list |
| `checkin` | O Line 1. + Capabilities (FMV, LASER, IR, NVG), + Laser code (1111-1788). Line 5 a number of minutes (the AI's check-in files one). Line 7 a textarea. Replies roger / freetext / close |
| `hlz` | R title LIFT REQUEST (HLZ); Line 1 DROP-OFF LZ, Line 3 LOAD, Line 4 SECURITY AT THE DROP-OFF. M + O Pickup first (empty = your position). D Line 2. A Wind. Subject `LIFT <pickup> - <LZ>` |
| `airdrop` | R PARADROP (a transport flies it; supplies go by RESUPPLY - the TO picker offers it on TRANS rows, a LOGI box answers CANTCO). D Lines 2-5. + Marking. Contents LOAD |
| `defrep` | O + A Vehicle. A Damage, Fuel. Replies roger / freetext / close |
| `qrf` | M link-up first. Line 5 a pick (CORDON, BLOCK, CCP, REINFORCE, ASSAULT) + detail. + Signals (far / near recognition). O Line 1 |
| `nineline` | Retired later the same day (below) - removed from the deck, the built-ins and the support script |
| `bda` | O + A Target (the thread's point), `noCur`. Result required |
| `resupply` | O Item counts, Method. Ground-to-air marking list. Remarks hint without "wind" |
| `onstation` | No change in the review; later the same day AREA a required map marker (below) |
| `mettc` | D Callsign; subject `METT-TC <mission>`; replies roger / freetext / close |
| `opord` | R `2-3. MISSION AND EXECUTION` |
| `roger` | allowedFrom ISSUED + OPEN (the thread moves to RECEIPT) |
| `wilco`, `inprogress` | + DETAIL line; `accepted`, `ontask` retired (removed from the deck, the built-ins and the support script) |
| `close` | R OUTCOME / END OF MISSION |
| `adjust` | + the other axis (Second: a correction and its metres, optional) - "RIGHT 50, ADD 100" in one message |
| `shot`, `splash`, `wheelsup`, `wheelsdown` | R the text line DETAIL |
| `prompt` | R Answers hint "asset use - leave empty" |

Required report fields left: 14 (casevac 1, tic 1, contactrep 2, cas 2, hlz 1, paradrop 1, qrf 1, nineline 2, bda 1,
resupply 2).

**Autofills built** (tacpad, each a small client function; `composeAutoFill` applies them before every draw, and a field
the player changed is his): `vehicle`, `vehicleDamage`, `vehicleFuel`, `wind`, `squadAce:<letter>`, `threadAnchor`,
`elevation:<key>`, `bearing:<from>:<to>`, `distance:<from>:<to>`.

**Code.** messaging `fieldPos` (new) and a typed grid anchoring the thread (`srvThreadFor`; maptools' `gridToPos` when
loaded - messaging cannot require maptools, which requires tacpad); `srvForward` call sign fallback; `subject` drops a
dangling dash; `seedTest` / `msg.flash` on the live keys. support `readOrder` (shift inference, ADJUST corrections, the
9-line DC tick, the 6-line precedences, the paradrop), `MAILBOX_TYPES`, `STRIKE_CARDS`, `CASEVAC_CARDS`, `DROP_CARDS`,
`ADJUST_CARDS`. support_fires: both axes. support_logistics: the paradrop refused. support_air: the check-in's minutes,
REINFORCE. tacpad_apps `ticSend`: the INTENTIONS word. tacpad: one-tap replies are reply cards with nothing required.

**Not done, and why.**

- DEFREP's title VEHICLE STATUS (3.11): not in the user's list of renames.
- One colour word (AMBER / YELLOW, rule 4): ALiVE takes SITREP's words as they are and was not checked; the autofill
  maps YELLOW to AMBER on SITREP's picks.
- RESUPPLY items as a pick from the asset's catalog: needs a dynamic `choices` source the engine does not have; the
  hint says to use the asset's names. (Built later the same day - `choicesFrom`, below.)
- SAY AGAIN reply, TIC assistance ticks as shortcuts to the matching cards, CFF TOT as mission time + 5 min, CHECK-IN
  altitude from the aircraft, MIST treatment from ACE: not in the decisions or the top 10 (the review called several
  "future").
- OPORD Header.B (date): PAC's OPORD post fills it, nobody types it - left.
- The 9-line MEDEVAC's defects (precedence letters, Line 8): moot, the card is retired.
- The CAS 9-line's autofills (`bearing`, `distance`, `elevation` - tacpad `autoLeg`, `autoElevation`): removed with
  the card later the same day; no other card used them.
- The AI's check-in does not fill CAPABILITIES or LASER CODE: they are a player pilot's lines.
- The DIVINER seed (`templates.inc.sqf.migrated`) and mission config decks (`JMFSBFR_Templates`): data the mod does
  not own - since 2026-11-02 the mod's built-in card replaces a mission card of the same id (messaging README).

**After contact, a SITREP** (user, 2026-11-02: "after contact a sitrep should be sent"; built, not seen in game). The
SITREP is kind `both` (the built-in card), so it files inside the TIC thread. The TIC thread offers SEND SITREP to
its sender and his squad leader: the SITREP in the composer, in the thread, LOCATION the TIC's grid, STATUS AMMO / CAS
from the squad's ACE. A deck still holding the SITREP as a root card gets a SITREP thread of its own on the TIC's net,
REMARKS `SITREP AFTER TIC <grid> - THREAD <id>` (the subject is the card's, `SITREP <grid>`, the same grid). After his
TIC the sender's machine waits for 180 s with no shot by, near or at his group and no new TIC from it, then says
`CONTACT OVER? SEND SITREP` upper right and over the tile; contact again arms it again; his SITREP or the thread
closing ends it. The tacpad README has the detail.

### Later the same day (user, 2026-11-02)

Built, not seen in game. The built-in cards carry all of it, and the mod's own card always wins (2026-11-02);
`check_invariants.py` rule 3 fails the build when a card id the mod names is not built in.

| Decision | Built |
|---|---|
| CALL FOR FIRE as three cards ("break arty in to 3 reports grid polar and shift fire") | `callforfire` is **CFF GRID** (title CALL FOR FIRE - GRID): its keys kept, Warno 3A required, Target 2 / Target 3 dropped (an older deck's are still read). New **CFF POLAR** (`cffpolar`: Polar direction + distance from the observer - the Observer line's grid, else the sender's position) and **CFF SHIFT** (`cffshift`: Known point - a grid or a map marker - and LEFT / RIGHT, ADD / DROP, UP / DOWN metres along the observer-target line). Each carries TYPE OF MISSION (required, tick one), engagement + rounds, DANGER CLOSE (600 m), control + TOT, observer, guns, remarks. `FIRE_CARDS` reads all three as kind `fire`: every battery, launcher and ALiVE's artillery answers them alike. A battery takes all three (`MAILBOX_TYPES` field 10); `@FOX 1-1` opens CFF GRID; the pin draws the target of each |
| One CAS card ("CAS REQUEST and CAS 9-line do not need both" - CAS REQUEST stays) | `nineline` retired: never built in, a deck's copy skipped (messaging `CARDS_RETIRED`), gone from the built-ins, `STRIKE_CARDS`, `MAILBOX_TYPES`, `PIN_CARDS`, and the composer's 9-line autofills (`autoLeg`, `autoElevation`). A player pilot is mentioned with CAS REQUEST |
| REQUEST ON STATION requires a map marker | Line 2 AREA: required, `markerOnly` (a new field option, messaging `registerTemplate`). The composer offers the MARKER cell alone (no CUR LOC); a marker's pick is a position, typing is text, and messaging `validate` refuses text or nothing with `PICK A MAP MARKER FOR THE AREA` - on the sender's machine and again on the server. The aircraft takes its station from it: a helicopter or a drone loiters over it, a fixed-wing holds off the map nearest it |
| EXTRACTION ("need a pick up version where the pick up is the hot zone") | New root card `extract`, EXTRACTION (HLZ): Pickup (required), LZ SECURITY (GREEN / YELLOW / RED), Marking (the ground-to-air list), Passengers, Wind (autofill), Obstacles, Destination (empty = home base), Remarks. Kind `extract`: support_air flies the whole landing procedure at the pickup (1 MIN OUT - POP SMOKE with LZ STATUS?, a RED one confirmed, circle, smoke CORRECT / WRONG, CLEARED TO LAND), loads every man of the side in range, then lands at the destination with the same clearance, or flies home without one. ALiVE flies it as a lift and refuses one without a destination. A transport takes `hlz`, `extract`, `casevac`, `airdrop`; its @ mention opens LIFT REQUEST |
| RESUPPLY items from the pre-made crates ("we have pre made crates so the requested items should be a drop down of them") | Each Item N name is a choice with `choicesFrom` `logiCatalog` (a new field option) and empty `choices`, so validation passes any name. The composer draws a drop-down (tacpad `composeDrop`) filled from support_logistics `catalogNames` - the catalog of the logistics asset on TO, else of every logistics asset of the side, read off what the server already publishes. The server matches the name to the catalog as before. Each item keeps its COUNT |
| Required exclusive tick group | The composer marks the line once (`REQ - TICK ONE` on its head) and frames the group once in the accent after a SEND that found none ticked; `composeSend` lists the group once. No mark on each tick |

Required report fields after this: the 14 above less the 9-line's 2, plus CFF GRID's target, CFF POLAR's direction
and distance, CFF SHIFT's known point, the extraction's pickup and ON STATION's area - 18, and TYPE OF MISSION (tick
one) on each call for fire.

Not done: the casevac stays a transport card (the user named `hlz`, `extract` and the paradrop; dropping `casevac`
would leave CASEVAC by message with no taker); UP / DOWN on CFF SHIFT is read but the guns aim at the ground, so it
changes nothing in game; an EXTRACTION's passenger count is said in the WILCO, the load is everyone in range.
