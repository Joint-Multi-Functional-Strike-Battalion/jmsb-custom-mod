# TAC//MSG Workflows

How the unit reports and calls support in TAC//MSG.
For JTACs, squad leaders, RTOs, medics and pilots.

This follows the code as of 2026-11-02.
Most support flows are built but have not yet been seen in game.
Message text in `code` is what the asset sends, word for word.
`m:ss` is minutes and seconds. `<grid>` is a map grid.

Contents:

1. [Basics](#1-basics)
2. [Report flows](#2-report-flows)
3. [Support call flows](#3-support-call-flows)
4. [Quick reference](#4-quick-reference)

---

## 1. Basics

### 1.1 Send a card

1. Open TAC//MSG: the reader on the map screen, or on the tablet.
2. Press **NEW**. The box is a plain message.
3. Press **TEMPLATE** and pick the card.
4. Address it:
   - **TO - CHANGE** opens the picker: nets, squads, men, and the **SUPPORT** group (the assets).
   - Or type `@` and the asset's call sign on the CC line (`@HOG`). The asset moves to TO.
5. Fill every line marked **REQ**.
   - A location: **CUR LOC** (your GPS position), **MARKER** (the marker list, nearest first), or type a 6, 8 or 10 figure grid.
   - A target grid has no CUR LOC.
   - Some lines fill themselves (wind, your call sign, vehicle state). Anything you change stays yours.
6. Press **SEND**.

**@ on an asset opens its card.**

| Asset type | @ opens |
|---|---|
| CAS (helicopter, drone, player pilot) | CAS REQUEST |
| CAS (AI fixed-wing, not on station) | REQUEST ON STATION |
| ARTY, CRUISE, LOITER | CALL FOR FIRE - GRID |
| TRANS | LIFT REQUEST (HLZ) |
| LOGI | RESUPPLY REQUEST |
| QRF | REACT/QRF LINK-UP |
| JUMP | JUMP REQUEST |

- A card that asset also takes is kept. Pick CFF POLAR, CFF SHIFT, EXTRACTION, CASEVAC, PARADROP or REQUEST ON STATION first, then @ the asset.
- Text you typed moves to the new card where it fits. Otherwise you get `<CALLSIGN> TAKES THE <CARD> CARD - n TYPED FIELDS ARE NOT ON IT` with **SWITCH** / **KEEP**.

### 1.2 NOT SENT

A send refused on your machine never leaves it.
You see `NOT SENT - <reason>` beside SEND and upper right.

| Reason | Fix |
|---|---|
| `<line> is required` | Fill it |
| `<line> is required - tick one` | Tick one box in that group (TYPE OF MISSION, JUMP TYPE) |
| `only one of <line> may be ticked` | Untick the extra |
| `<line> must be a number` / `must be between a and b` | Correct the number |
| `<line> must be a position or a grid` | Use CUR LOC, MARKER or a grid |
| `PICK A MAP MARKER FOR THE AREA` | REQUEST ON STATION takes a marker only. Pick one from MARKER |
| `no addressee` | Add a TO |
| `link denied - your position is jammed` | Move out of the jammer |
| `messaging is disabled` | Mission setting |

- Near a jammer a send can be delayed: `Link degraded - transmitting in n s`.
- The server can also refuse (system chat, the card comes back):
  `that thread is closed`, `<CARD> is not allowed while the thread is <STATE>`, `only the issuer may send that`.
- In a support thread the server also refuses:
  `<CARD> opens its own thread` (a card that starts a thread, sent into one the asset does not take it in),
  `<CARD> is the asset's to send` (ROGER, WILCO, ON TASK, CANTCO from a player),
  `only the issuer may send <CARD> into this thread` (a new task in the thread from anyone but the sender).

**`NO ASSET ADDRESSED`** (upper right): you sent a support card with no asset on TO.
It went to the net. No AI answers it. @ the asset and send again.

### 1.3 Threads

Every card opens a thread. Every answer goes in that thread.

| State | Means |
|---|---|
| OPEN | A report. Nobody owes an action |
| ISSUED | A task, sent |
| RECEIPT | ROGER - received |
| ACCEPTED | WILCO - will comply |
| IN_PROGRESS | ON TASK |
| CLOSED | Done |
| DECLINED | CANTCO - cannot comply, with the reason |

- **ROGER** answers any open report and any new task.
- Only the sender (issuer) can **CLOSE** a thread.
- A thread nobody touches for 60 min closes itself (mission setting).
- FLASH cards (TIC, CASEVAC, calls for fire, CLEARED HOT, CHECK FIRE, the asset's urgent questions) raise the FLASH banner.
- An asset's first answer is one message: `ROGER, WILCO - <detail>`.
  Refused: `CANTCO - <reason>` alone.
  A slow asset: `ROGER` at 2 s, the WILCO when it comes.
- A support thread draws its points on the map (TARGET, LZ, PICKUP, DZ...), a red danger-close ring while a friendly is inside it, and the asset's route and rounds while it works. Gone when the thread closes.

### 1.4 Quick replies

The row of tiles under an open thread. In this order:

1. **What the asset just asked.** Its question is the last message. Its answers are the tiles.
   An answer that is a new task (**CAS** on REQUEST BDA, RE-ATTACK or FURTHER TASKING?, **HLZ** on HOLD, RTB OR NEXT LIFT?) opens that card in the composer, in this thread.
   Beside SEND: `IN THREAD <id> - A NEW TASK FOR <CALLSIGN>`.
2. **Your support card's row** (only for the man who sent it):

   | Card | Tiles |
   |---|---|
   | CAS REQUEST | CLEARED HOT, ALL ATTACK (fixed-wing with escorts), ABORT, RTB, CLOSE |
   | REQUEST ON STATION | ABORT, RTB, CLOSE |
   | CFF GRID / POLAR / SHIFT | ADD, DROP, LEFT, RIGHT, FFE, REPEAT, CHECK FIRE, EOM |
   | LIFT REQUEST | CONFIRM, ALL IN, ABORT, RTB, CLOSE |
   | EXTRACTION | CONFIRM, EXTRACT, ALL IN, ABORT, RTB, CLOSE |
   | CASEVAC, PARADROP | CONFIRM, ABORT, RTB, CLOSE |
   | RESUPPLY REQUEST | ABORT, CLOSE (RECEIVED / NOT FOUND come with its question) |
   | REACT/QRF LINK-UP | ABORT, RTB, CLOSE |
   | JUMP REQUEST | BOARD, ABORT, RTB, CLOSE |

3. **Any other thread:** the card's one-tap replies (ROGER, CLOSE...) and your own phrases.

**The asset's words are the asset's.** ROGER, WILCO, ON TASK and CANTCO are never offered to the man who sent a support card, nor to anyone in a thread an AI asset answers.
The server refuses them there. The asset sends them itself.

- Only replies the thread will take now are drawn.
- A tile with no required line sends in one press.
- A tile with a required line (BDA) opens the card in the thread.
- ADD, DROP, LEFT, RIGHT open a distance pick: 25, 50, 100, 200, 400, BACK. One press sends it.
- **+ TEMPLATE** offers every reply the thread takes (RTB, ABORT, ADJUST FIRE with a second axis...).
  In a thread an AI asset answers, its sender also gets the asset's own cards as a new task in the thread:
  CAS REQUEST in a CAS strike thread; LIFT REQUEST, EXTRACTION, CASEVAC, PARADROP in a lift thread.
- **+ GRID** sends your position. **+ MARKER** sends a marker's name and grid.

### 1.5 When the asset asks

- The asset's question sits last in the thread, its answers as tiles.
- **No answer for 3 min:** it asks again, `NO RESPONSE - HOLDING`.
- **No answer for 5 min:** it ends the job. What that means is in each flow.
- CAS adds one wait: no CLEARED HOT 60 s after its WILCO, it asks `AWAITING CLEARED HOT`.

### 1.6 Who can task support

- The SUPPORT group and the @ list show only to men the **Support tasking tag** setting allows. Empty = everyone. `JFO` = the mission's JFO slots.
- Each row: call sign, then `TYPE - STATE - ETA m:ss`.
  States: IDLE, TASKED, ON STATION, RTB, REARMING, LOST.
  A dim row says why it cannot take a task (`CAS - REARMING - COOLDOWN 40 S`).
- **Player crews** of your side are listed too (`CAS - PLAYER - AH-64D APACHE`). No AI answers; the crew answers like any message.
- The **jump aircraft (SKYTRAIN)** shows only to squad leaders and admins.
- In a support thread the asset listens to: the sender, the man named on the call for fire's OBSERVER line, and anyone on the FIRES net. Same side only.

### 1.7 Danger close

- CAS: 300 m. Artillery, missiles, munitions: 600 m.
- The server measures where your side's men are.
- Friendlies inside it, or your own range under it, without the DANGER CLOSE tick: `CANTCO - DANGER CLOSE NOT ACKNOWLEDGED`.
- Writing DANGER CLOSE in REMARKS also counts on a CAS REQUEST.

> Code: `addons/tacpad` (composer, quick replies), `addons/messaging` (threads, validation), `addons/support` (assets as mailboxes, threads, prompts).

---

## 2. Report flows

Default shared nets: `C2`, `C2.reports`, `FIRES`, `FIRES.cas`, `FIRES.arty`, `FIRES.trans`, `MEDICAL`, `MEDICAL.mist`, `MEDICAL.medevac` (mission setting).
A report is OPEN: the receiver answers **ROGER**. Replies offered: ROGER, MESSAGE, CLOSE.

### 2.1 TROOPS IN CONTACT

**When:** you take fire. One key press is the whole report.

1. **You:** press the **TIC key** (Numpad - by default; CBA keybind "Troops In Contact").
   Or the TIC button under the reader on the map screen.
   Or NEW > TROOPS IN CONTACT by hand (type your grid when you have no GPS).
2. **What it files:** TROOPS IN CONTACT, FLASH, on the first shared net (C2 by default).
   - LOCATION: your GPS position.
   - ENEMY: `CONTACT - DETAILS TO FOLLOW`.
   - INTENTIONS: `RETURNING FIRE`.
3. **Everyone on your side** (alive) gets the alert `<CALLSIGN> in contact - TIC <CALLSIGN> <HHMM>`.
4. **Your side's map** gets a red marker `TIC <CALLSIGN> <HHMM>` on the grid. It goes with the thread.
5. **C2 / leaders:** ROGER. Then send what is needed: CAS, call for fire, QRF, CASEVAC.

The key refuses with:

| Says | Why |
|---|---|
| `Contact report already sent - ns` | 30 s between TICs |
| `No command net configured` | The mission has no shared net |
| `No GPS fix - send the TIC from the card with your grid` | GPS denied. Use the card |
| `Not alive` | |

- A call ringing you: the key answers the call instead.
- By hand only LOCATION is required. ENEMY, FRIENDLY CASUALTIES, INTENTIONS, ASSISTANCE REQUIRED, REMARKS are optional.

> Code: `addons/tacpad_apps/functions/fnc_ticSend.sqf`, `addons/messaging/functions/fnc_srvTic.sqf`.

### 2.2 SITREP after contact

**When:** the shooting stops.

1. **The TIC thread** shows **SEND SITREP** first on its row. Only for the TIC's sender and his squad leader.
2. **Your machine** waits for 180 s with no shot by, near or at your group, and no new TIC from it.
   Then: `CONTACT OVER? SEND SITREP` upper right, and over the TIC thread's row.
   Contact again starts the wait again. Once per TIC.
3. **You:** press SEND SITREP. The SITREP opens inside the TIC thread.
   - LOCATION: the TIC's grid.
   - STATUS AMMO and CAS: the worst of the squad's ACE letters (YELLOW reads AMBER).
   - Add ENEMY (EKIA), FRIENDLY (FKIA, FWIA), CIV, VEH, CE, REMARKS. Nothing is required.
4. **SEND.** The SITREP or the thread closing ends the wait.
5. **C2:** ROGER. CLOSE belongs to the TIC's sender.

- An older deck that cannot file a SITREP in a thread: a new SITREP thread goes to the TIC's net, REMARKS `SITREP AFTER TIC <grid> - THREAD <id>`. Beside SEND: `THE DECK'S SITREP OPENS ITS OWN THREAD - THE TIC IS IN REMARKS`.
- A SITREP also goes to ALiVE as a sitrep when that setting is on.
- A SITREP can be sent any time: NEW > SITREP.

> Code: `addons/tacpad/functions/fnc_sitrepAfterTic.sqf`, `fnc_contactCheck.sqf`.

### 2.3 SALUTE

**When:** you see the enemy and are not in contact. The full report, unchanged.

| Line | |
|---|---|
| S - SIZE | **REQ** |
| A - ACTIVITY | |
| L - LOCATION | **REQ** |
| U - UNIT | |
| T - TIME | Fills with mission time |
| E - EQUIPMENT | |
| R - REMARKS | |

1. **You:** NEW > SALUTE, TO C2 or C2.reports (or your leader). SEND.
2. **Receiver:** ROGER. Plot it, pass it up, task on it.

- Goes to ALiVE as a spotrep when that setting is on.

### 2.4 MIST

**When:** handing a casualty to the medic or the CASEVAC crew. The full report, unchanged.

| Line | |
|---|---|
| M - MECHANISM OF INJURY & TIME | **REQ** |
| I - INJURIES SUSTAINED | |
| S - SYMPTOMS AND VITALS | A-Airway B-Breathing C-Pulse D-Responsive E-Everything else |
| T - TREATMENT GIVEN | |
| REMARKS | |

1. **You:** NEW > MIST, TO MEDICAL.mist or the medic. SEND. Its own thread, `MIST - <mechanism>`.
2. **Medic:** ROGER. Treat or prepare for the bird.

### 2.5 6-LINE CASEVAC (the report)

**When:** a casualty needs moving. FLASH.

| Line | |
|---|---|
| 1 PICK-UP SITE LOCATION | **REQ** |
| 2 NUMBER OF PATIENTS | Empty = the total of line 3 |
| 3 PRIORITY OF PATIENTS | URGENT / PRIORITY / ROUTINE counts |
| 4 LZ SECURITY | GREEN / YELLOW / RED |
| 5 MARKING METHOD | SMOKE, IR STROBE, PANEL, CHEMLIGHT, FLARE, NONE, OTHER + colour |
| REMARKS | MIST, anything the crew must know |

Who answers depends on TO:

- **A TRANS asset (AI):** it flies it. See [3.7](#37-casevac-by-transport).
- **A player crew or MEDICAL.medevac:** players answer: ROGER, WILCO, ON TASK, CANTCO, CLOSE.

- The Squad app's **FILE CASEVAC FOR \<name\>** opens the card with line 1 at that man's position.
- Send the MIST to the medic or crew after it.

### 2.6 VEHICLE REPORT (DEFREP)

**When:** your vehicle is hit or low.

- VEHICLE, DAMAGE and FUEL fill from the vehicle you are in. EQUIPMENT and REMARKS by hand. Nothing required.
- **ROUTING - CMD** tick also sends it to the command group (only when the mission names one).

1. **You:** NEW > DEFREP, TO your leader or C2. SEND.
2. **Receiver:** ROGER. Plan repair, recovery or replacement.

### 2.7 AIRFRAME CHECK-IN

- **AI aircraft** file their own, in your thread, once per sortie, when they get on station. See 3.1 and 3.2.
  It carries: call sign, `1x <type>`, position and altitude, ordnance left (`GBU-12 x2, 20mm x450`), minutes on station, a new 4-figure ABORT CODE, CAPABILITIES (FMV, LASER, IR, NVG), LASER CODE, REMARKS.
- **A player pilot:** NEW > AIRFRAME CHECK-IN to the JTAC when on station. Nothing required. Laser code 1111-1788.
- **JTAC:** ROGER. Note the abort code and the stores.

### 2.8 OPORD and METT-TC

- **OPORD:** an admin posts it from TAC//PAC to C2. Answer with ROGER, MESSAGE or METT-TC.
- **METT-TC:** leaders only. Send it as a reply in the OPORD thread (or alone). MISSION, ENEMY and CIVIL prefill from the current OPORD. Answered ROGER.

> Code (2.3-2.8): the mod's built-in cards (`addons/messaging/functions/fnc_builtinCards.sqf`, `addons/support/functions/fnc_builtinCards.sqf`), `addons/pac/functions/fnc_registerTemplates.sqf`, `addons/tacpad` autofills.

---

## 3. Support call flows

Every flow below starts the same way:
NEW > the card > TO the asset (CHANGE > SUPPORT, or `@CALLSIGN`) > fill > SEND.
Call signs in examples: HOG (CAS), FOX 1-1 (battery), RAVEN (transport), SKYTRAIN (jump).

CANTCO words any asset can give:
`TASKED`, `RTB`, `COOLDOWN n S`, `REPLACING`, `EXPENDED`, `LOST`, `NO TARGET LOCATION`, `NO STORES`, `DANGER CLOSE NOT ACKNOWLEDGED`, `OUT OF RANGE n/max KM`, `UNABLE - NO AIRFRAME`.

**Virtual until tasked** (2026-11-02). No CAS, CAS drone, transport, QRF, jump or logistics aircraft exists until it is tasked:

- Its row reads IDLE (READY) with its respawns. ETA: from the module to the task at its cruise speed.
- **Tasked** = the WILCO (a board order, a card accepted, REQUEST ON STATION; for a jump, the JUMP REQUEST).
- It is made at once, **in the air over its module**, engines on, flying, dark, full of fuel and stores.
  Height: helicopter 30 m (nap of the earth), fixed-wing 4000 m, CAS drone 4000 m, jump aircraft 2000 m, logistics its flight height (a sling 30 m plus rope and load).
- Two made together are kept 150 m apart (offset, else stacked higher).
- It flies the flow below. Then it flies home to the module and is **removed there** - crew and airframe, no wreck. A transport lands and unloads first.
- Not home in 20-30 min: removed where it is. Never with a player aboard.
- The next task makes a fresh one. No response delay.
- A module synced to an aircraft (CAS, transport) is not virtual: that aircraft takes off from its stand and parks back there, as before.

**Respawns** (2026-11-02). Every support module has **Respawns** (default 0) and **Respawn Delay**.

- Only an airframe **lost** uses one: destroyed, crew dead, or disabled (cannot fly 10 s).
- After a loss the row reads REPLACING for the delay. The next task after it makes a new airframe.
- Going home and being removed uses **none**.
- None left: the asset leaves the SUPPORT list. A card to it: `CANTCO - UNABLE - NO AIRFRAME`.

### 3.1 CAS - helicopter or drone

**Card: CAS REQUEST.**

| Line | |
|---|---|
| 1 TARGET LOCATION | **REQ**, no CUR LOC |
| 5 TARGET DESCRIPTION | **REQ** |
| 3 INGRESS / 4 EGRESS | Optional points. Empty: the aircraft picks |
| 6 FRIENDLIES / DANGER CLOSE | Range optional (the server measures). Tick DANGER CLOSE under 300 m |
| 7 MARKED BY | SMOKE, LASER, IR, TRACER, NONE + colour or laser code |
| MUNITIONS (OPTIONAL) | A store it carries. Else the heaviest |

1. **JTAC:** CAS REQUEST to HOG. SEND.
2. **HOG:** `ROGER, WILCO - ETA m:ss - <DESCRIPTION>`. ETA from the module.
   Or CANTCO: `NO TARGET LOCATION`, `DANGER CLOSE NOT ACKNOWLEDGED`, `CANNOT LASE <code>`, `NO STORES`, `TASKED`, `COOLDOWN n S`, `REPLACING`, `UNABLE - NO AIRFRAME`.
3. **HOG is made** over its module at once: helicopter 30 m, drone 4000 m. It flies to the grid. It releases nothing before CLEARED HOT.
   - Helicopter: orbits the run-in distance short of the target, nap of the earth.
   - Drone: orbits the grid at 4000 m, dark.
   - An INGRESS point given: it flies there first.
4. **AIRFRAME CHECK-IN** in the thread when it gets there.
   REMARKS: helicopter `HOLDING SHORT FOR CLEARED HOT`, drone `OVER THE GRID, HOLDING FOR CLEARED HOT`.
5. **No CLEARED HOT 60 s after the WILCO:** `AWAITING CLEARED HOT` (FLASH). [CLEARED HOT] [ABORT]
6. **JTAC: CLEARED HOT** (tile). ALL ATTACK is a fixed-wing flight's (3.2): a helicopter or drone answers `NO ESCORTS - USE CLEARED HOT`.
7. **HOG:** `IN` and ON TASK. It runs in. A laser spot or smoke near the grid takes over the aim.
8. **HOG, after the release:** `OFF - RETURNING TO STATION - REQUEST BDA`. [BDA] [CAS]
   - Helicopter: back to its point short of the target.
   - Drone: out past the egress point, then back over the grid.
9. **JTAC: BDA** (opens the card). TARGET fills with the thread's point.
   RESULT **REQ**: DESTROYED, DAMAGED, NO EFFECT, NOT OBSERVED. COUNT.
   **DECISION REQ - tick one:** RE-ATTACK or EGRESS. REMARKS.
10. **HOG answers the BDA:**
    - **RE-ATTACK**, stores left: `RE-ATTACK - <n> <STORE> LEFT - AWAITING CLEARED HOT` (FLASH). [CLEARED HOT] [CAS] [ABORT]
      CLEARED HOT runs in again, on the BDA's grid if you gave one. Back to step 7. Repeat as often as needed.
    - **EGRESS:** it flies your egress point (line 4; none - straight back), then home to the module and is removed. CLOSED `EGRESS - RTB`.
    - Nothing left: CLOSED `WINCHESTER`. Home to the module, removed. No respawn used.
11. **New target instead:** the CAS tile on step 8 or 10. The CAS REQUEST opens in this thread. Fill, SEND.
    HOG: `ROGER, WILCO - ETA m:ss - <DESCRIPTION>` from where it is, and holds for CLEARED HOT. Back to step 5.
    Cannot fly it: `FURTHER TASKING?` with the reason in front (`NO STORES`, `DANGER CLOSE NOT ACKNOWLEDGED`...). [CAS] [RTB] [CLOSE]

At any time:

- **ABORT** (tile): the strike is off. It flies home and is removed.
- **RTB / CLOSE:** home to the module, removed.
- **BINGO:** `BINGO IN 2 MIN` (FLASH). [RTB] [CLOSE]. No answer: CLOSED `BINGO` 2 min later, home.
  Helicopter: its time on station. Drone: 30 min from the request. Both: a quarter tank of fuel.
- **Silent 5 min** on any question: CLOSED `NO RESPONSE - RTB`, home.
- **Shot down or disabled:** CLOSED, a respawn used (or the asset is gone).

Notes:

- **New target, same sortie:** the CAS tile (step 11), or + TEMPLATE > CAS REQUEST in the thread, any time. Only the sender.
- **An older deck's BDA** (no DECISION line, RE-ATTACK not ticked): `<n> MIN ON STATION - FURTHER TASKING?`. [CAS] [RTB] [CLOSE]
- **Artillery's BDA** is the same card: tick either DECISION box. The battery does not read it (3.3).
- **Drone escorts:** a CAS REQUEST has no LZ security line - a helicopter gets none. A drone gets none. See [3.12](#312-drone-escorts).
- **Drone LOITER instead of a strike:** send REQUEST ON STATION (3.2 card). It answers `ROGER, WILCO - LAUNCHING - ON STATION IN m:ss`, is made over its module, orbits the marker dark at 4000 m, releases nothing, checks in `OVER THE GRID, DARK`. An ISR player who asked is given the gunner's seat. It holds 1 hour, then home.
- **Helicopter REQUEST ON STATION:** `ROGER, WILCO - LAUNCHING - ON STATION IN m:ss`. Made over the module, it loiters over the marker, weapons tight, the time asked, and checks in `OVER THE GRID, DARK`. A CAS REQUEST to it then strikes from there.
- **Player pilot:** @ him with CAS REQUEST. No AI answers. He replies by hand (WILCO, IN, OFF...).

> Code: `addons/cas` (drones: `fnc_launch.sqf`, `fnc_spawnDrone.sqf`, `fnc_runTick.sqf`, `fnc_recover.sqf`, `fnc_gone.sqf`, `fnc_killed.sqf`), `addons/support_air/functions/fnc_srvThread.sqf`, `fnc_casLaunch.sqf`, `fnc_casTick.sqf`, `fnc_casJob.sqf`, `fnc_homeTick.sqf`, `fnc_writeOff.sqf`, `fnc_replace.sqf` (helicopters), `addons/support/functions/fnc_spawnAirborne.sqf`, `fnc_casPrompt.sqf`, `fnc_promptCleared.sqf`.

### 3.2 CAS - fixed-wing

A fixed-wing flown by the AI must be on station first. REQUEST ON STATION is its task: the jet is made then, over its module, at 4000 m, and flies to its hold 8 km off the map. One CAS REQUEST per strike.

**Card 1: REQUEST ON STATION.**

| Line | |
|---|---|
| 1 TIME ON STATION (MIN) | 1-120. Empty: the aircraft's own. Never more than the module allows |
| 2 AREA | **REQ**. A map marker only - typing is refused |
| REMARKS | Threats, what it is for |

1. **JTAC:** place a map marker on the area. `@HOG` opens REQUEST ON STATION. Pick the marker. SEND.
2. **HOG** - it asks nothing about targets, danger close or stores:
   `ROGER, WILCO - LAUNCHING - ON STATION IN m:ss` (module to hold at cruise).
   The jet is made over its module at 4000 m, engines on, dark, with its two escort drones beside it (3.12).
   A synced jet takes off from its stand instead.
   CANTCO: `TASKED` (it is out on another task), `RTB`, `COOLDOWN n S`, `REPLACING` (after a loss, for the respawn delay), `UNABLE - NO AIRFRAME`... A battery or launcher: `NOT AN AIR ASSET`.
3. **HOG holds off the map:** its hold, 8 km outside the map edge nearest the marker, 4000 m, dark. The hold is the flow's station; it does not move.
4. **HOG: AIRFRAME CHECK-IN** in this thread. REMARKS `HOLDING OFF THE MAP, DARK`. Its row reads ON STATION.

**Card 2: CAS REQUEST** (as 3.1), a new message per strike.

5. **JTAC:** NEW, `@HOG` (now opens CAS REQUEST), fill, SEND.
   - Sent before it is on station: `CANTCO - NOT ON STATION`.
   - A second strike while one is open: `CANTCO - TASKED`.
6. **HOG:** `ROGER, WILCO - ETA m:ss - <DESCRIPTION>`. It waits at the hold.
7. **No CLEARED HOT in 60 s:** `AWAITING CLEARED HOT` (FLASH). [CLEARED HOT] [ALL ATTACK] [ABORT]
8. **JTAC: CLEARED HOT** - the jet only. Or **ALL ATTACK** - the jet and its escort drones (below).
9. **HOG:** `IN` and ON TASK. It comes in at 4000 m by your ingress point, strikes once, leaves by your egress point.
10. **HOG, on the way back to the hold:** `OFF - RETURNING TO STATION - REQUEST BDA`. [BDA] [CAS]
    After an ALL ATTACK: `OFF - RETURNING TO STATION - DRONES DESTROYED <n> - REQUEST BDA`.
11. **JTAC: BDA** with its DECISION (as 3.1 step 9).
    - **RE-ATTACK:** `RE-ATTACK - <n> <STORE> LEFT - AWAITING CLEARED HOT` (FLASH). [CLEARED HOT] [ALL ATTACK] [CAS] [ABORT]. In again from the hold. Back to step 9.
    - **EGRESS:** HOG flies your egress point, then home to the module and is removed. Both threads CLOSED `EGRESS - RTB`.
    - Nothing left: both threads CLOSED `WINCHESTER`. Home, removed.
12. **CAS** (tile) on step 10 or 11: the next strike in the same thread, as 3.1 step 11. HOG flies it from the hold.
    **CLOSE** on the strike thread: the strike ends, HOG stays on station.
    **RTB** on the strike thread: both threads close `RTB`, HOG flies home to the module and is removed.
13. **Next strike after a CLOSE:** a new CAS REQUEST (back to step 5).

A CAS REQUEST needs no REQUEST ON STATION while the jet is on its hold: it is flown as a strike from station.

**ALL ATTACK** (2026-11-02). CLEARED HOT for the jet **and** its two escort drones.

- Offered beside CLEARED HOT (the card's tiles, AWAITING CLEARED HOT, RE-ATTACK) to a fixed-wing flight with an escort up. Same senders as CLEARED HOT.
- HOG: `ON TASK - ALL ATTACK - FLIGHT IN HOT`. The jet runs its strike as CLEARED HOT.
- The drones break off and attack every hostile within 300 m of the target, each its own target: vehicles and statics first, then men. Their own weapons.
- Never a target with your men inside the module's Friendly Range, unless you ticked DANGER CLOSE.
- They rejoin the jet when the area is clear, when they are Winchester, after 5 min, or when the jet egresses or goes home.
- The OFF waits for them (up to 2 min) and counts what they destroyed.
- No escort up, or a helicopter or drone: `NO ESCORTS - USE CLEARED HOT` (FLASH). [CLEARED HOT] [ABORT]

Drone escorts: two on every fixed-wing sortie, always. See [3.12](#312-drone-escorts).

Off station - both threads close with the word, and HOG flies home to its module and is removed:

- **EGRESS - RTB:** a BDA's DECISION was EGRESS.
- **RTB:** you sent CLOSE, ABORT or RTB in the REQUEST ON STATION thread.
- **BINGO:** `BINGO IN 2 MIN` (FLASH) 2 min before the time asked is up, or at a quarter tank. CLOSED 2 min later.
- **WINCHESTER:** nothing left aboard.

Going home uses no respawn. The next REQUEST ON STATION makes a fresh jet. Shot down or disabled: a respawn is used; none left - `UNABLE - NO AIRFRAME`.

Silent 5 min on a strike's question: the strike is dropped, CLOSED `NO RESPONSE`. HOG stays on station.

> Code: `addons/support_air/functions/fnc_srvThread.sqf`, `fnc_casOrder.sqf`, `fnc_casLaunch.sqf`, `fnc_spawnAircraft.sqf`, `fnc_casTick.sqf`, `fnc_casJob.sqf`, `fnc_threadReply.sqf`, `fnc_allAttack.sqf`, `fnc_canAllAttack.sqf`, `fnc_checkIn.sqf`, `fnc_homeTick.sqf`, `fnc_replace.sqf`; `addons/support/functions/fnc_holdPoint.sqf`, `fnc_spawnAirborne.sqf`, `fnc_escortAttack.sqf`, `fnc_escortStrike.sqf`.

### 3.3 Call for fire - GRID, POLAR, SHIFT

**Three cards. Pick by how you know the target.**

| Card | Target lines (**REQ**) |
|---|---|
| CALL FOR FIRE - GRID | TARGET - GRID: a grid or marker, no CUR LOC |
| CALL FOR FIRE - POLAR | Direction in degrees (0-360, not mils) and distance in metres, from the observer |
| CALL FOR FIRE - SHIFT | KNOWN POINT (grid or marker), then LEFT / RIGHT and ADD / DROP metres along the observer-to-known-point line. UP / DOWN is read but changes nothing |

Lines on all three:

| Line | |
|---|---|
| TYPE OF MISSION | **REQ - tick one**: Adjust fire, Fire for effect, Suppress, Immediate suppression |
| TARGET DESCRIPTION | Optional, repeated in the WILCO |
| TARGET SHAPE | Optional. Empty = point. Point, Area, Linear, Creeping + size in metres |
| LINEAR / CREEPING - FAR END OR ATTITUDE | Optional. A far end (grid or marker), or an attitude in degrees |
| METHOD OF ENGAGEMENT | HE, Smoke, Illumination, Cluster, Laser-guided, Airburst + rounds per gun. None: the battery's first shell |
| DANGER CLOSE - UNDER 600 M | Tick to acknowledge |
| METHOD OF FIRE | Optional. Empty = one volley. INT interval (s), VOL volleys, or CONT continuous for (min) |
| METHOD OF FIRE CONTROL | Fire when ready, At my command, Time on target, Cannot observe |
| TIME ON TARGET - HHMM, HHMMSS OR +MIN | With Time on target. `1430`, `143015`, or `+5` (5 min from now). Game time, at most 1 hour ahead |
| OBSERVER | Call sign (fills with yours). POLAR / SHIFT: his grid, empty = your position |
| GUNS | Empty = all |

`@FOX 1-1` opens CFF GRID. For POLAR or SHIFT, pick the card first, then @.

**Before SEND** (to a battery): the line beside SEND says what the battery would answer.

- `IN RANGE 8.4 KM (MIN 2 KM, MAX 24 KM) - TOF 32 S - AREA 150 M`. `DANGER CLOSE - FRIENDLY 420 M` when a friendly is inside 600 m and the tick is set.
- In the accent: `CANTCO - <why>`, the battery's own word (out of range, too close, danger close not acknowledged, busy, no stores...).
- On your map, while you write: the target, and the footprint - a point's scatter ellipse, an area's circle, a linear line, a creeping walk to `WALK END`, the danger-close ring when a friendly is in it. Orange: it would fire. Red: it would not.
- The battery still decides when the card arrives.

**Target shape** (each size up to the battery's Max Sheaf Length, 300 m unless the mission sets more):

| Tick | Size | Far end / attitude | Fire |
|---|---|---|---|
| Point (or none) | - | - | Every round on the point |
| Area | Radius. Empty: 100 m | - | Rounds spread inside the circle |
| Linear | Length. Empty: 200 m | Far end: the line runs from the target to it. Attitude: the line's direction, the target its middle. Neither: across the gun-target line | The guns spread along the line |
| Creeping | Length of the walk. Empty: 200 m | Far end: walks to it. Attitude: walks that way. Neither: away from the guns | Each round lands further along, guns side by side |

The battery must offer the sheaf (module Sheaf Types: AREA CONVERGED or BOX, LINEAR PARALLEL, CREEPING CREEPING). Else CANTCO `SHEAF NOT AVAILABLE`.
A line's or walk's ends are checked for range and danger close too.

**Method of fire:**

- INT: seconds added between one gun's rounds (up to the module's Max Interval).
- VOL: volleys (up to Max Repeats + 1). They follow on the guns' rhythm: each gun's first round of the next volley one reload + interval after its last - no pause, no wait for the splash; the cooldown is paid once at the end. SHOT / SPLASH read `VOLLEY 2 OF 3`.
- CONT: each gun fires a round every reload + interval for that many minutes. Keeps illumination up.
  Up to Max Continuous Fire (10 min). A battery with 0: CANTCO `CONTINUOUS FIRE NOT AVAILABLE`.
- The gap between rounds jitters a little. Guns are not metronomes.

WILCO example: `ROGER, WILCO - ETA 1:40 - FFE - 4 GUNS x 3 HE - INTERVAL 20 S - 3 VOLLEYS - LINEAR 400 M ATT 090 - TOF 52 S`.

**Adjust fire (TYPE OF MISSION: Adjust fire):**

1. **Observer:** CFF to FOX 1-1. SEND.
2. **FOX 1-1:** `ROGER, WILCO - ETA m:ss - ADJUST - 1 RD HE - TOF n S - <DESCRIPTION>`.
   `DANGER CLOSE` is added when ticked.
3. **FOX 1-1:** ON TASK.
4. **FOX 1-1:** `SHOT TOF n` as it fires. `SPLASH` 5 s before impact. A short sound on your machine with each.
5. **FOX 1-1:** `ADJUST?` [ADD] [DROP] [LEFT] [RIGHT] [FFE] [EOM]
6. **Observer:** ADD / DROP / LEFT / RIGHT, then a distance (25-400). One press.
   Two axes in one message ("RIGHT 50, ADD 100"): + TEMPLATE > ADJUST FIRE, fill both.
   The correction is along / across the observer-target line.
7. **FOX 1-1:** the next adjusting round: SHOT, SPLASH, `ADJUST?`. Repeat 6-7.
   Cannot fire there: `ADJUST? - <why>` (out of range, danger close).
8. **Observer: FFE** (rounds per gun optional, via + TEMPLATE).
9. **FOX 1-1:** SHOT, SPLASH for each salvo, then, as the last round lands, `ROUNDS COMPLETE - 12 HE, 6 SMOKE LEFT - REQUEST BDA`. [BDA] [RECORD] [REPEAT] [EOM]
10. **Observer: BDA** (RESULT and a DECISION tick required; the battery reads neither tick). **FOX 1-1:** `12 HE, 6 SMOKE LEFT - END OF MISSION?` [EOM] [RECORD] [REPEAT]
11. **Observer: EOM.** CLOSED `END OF MISSION`.

**Fire for effect / Suppress:** steps 1-4, then 9-11. **Immediate suppression:** the same, at its quickest.

**Accuracy:**

- The first salvo lands off the point by up to the battery's Aiming Error (100 m unless the mission sets it). All its rounds together.
- Each ADJUST halves it. The FFE after adjusts halves it again. Once it is under the guns' dispersion, it is gone.
- Fired for effect without adjusting, the error stays.
- Each round also scatters on its own: a long ellipse along the gun-target line.

**Airburst** (METHOD OF ENGAGEMENT: Airburst): HE that bursts 7-12 m over the ground. WILCO `4 GUNS x 3 HE AIRBURST`. Adjusting rounds burst on impact; the FFE bursts in the air.

**RECORD AS TARGET** (tile on ROUNDS COMPLETE, END OF MISSION? and CHECK FIRE - HOLDING):

- **FOX 1-1:** `RECORDED AS TARGET TH1001`, then the same question again, without RECORD.
- A red marker `TH1001` goes on the map at the last adjusted point. Your side only.
- Fire on it again: type `TH1001` in CFF GRID's TARGET - GRID, or CFF SHIFT's KNOWN POINT. Capitals, as on the map.
- The name: the battery's two letters + 1001, 1002... The letters are the module's Target Prefix, else the call sign's first two (THUNDER: TH).
- **Pre-planned targets:** an Eden marker named with the battery's letters and four figures (`TH1001`) is a target from the start. The battery numbers past it.

**What is left:** the battery's rounds left are in its end-of-mission questions, and on its row in the TO picker (`ARTY - IDLE - 12 HE, 6 SMOKE - ETA 1:20`).

**At my command:**

- WILCO reads `ROGER, WILCO - AT MY COMMAND - ...`.
- **FOX 1-1:** `READY - AT MY COMMAND`. [CONFIRM] [EOM]
- **Observer: CONFIRM** - it fires.

**Time on target:** WILCO reads `TOT 1430 - ...` (`TOT 143015` for a time to the second or `+5`). The first round lands then.
CANTCO `NO TOT` (no time given) or `CANNOT MAKE TOT`.

**Cannot observe:** an adjust is fired for effect. After it: `ROUNDS COMPLETE - <LEFT> - END OF MISSION?` [EOM] [RECORD] [REPEAT].

**CHECK FIRE** (tile, any time): rounds not yet fired are not fired; rounds in the air still land.
**FOX 1-1:** `CHECK FIRE - HOLDING`. [ADD] [DROP] [LEFT] [RIGHT] [FFE] [REPEAT] [RECORD] [EOM]

**REPEAT:** the last salvo again.
A call made while rounds are in the air waits for them to land (up to 120 s).

**Timeouts:** 3 min `NO RESPONSE - HOLDING`. 5 min CLOSED `NO RESPONSE - END OF MISSION`.

**CANTCO:** `NO TARGET LOCATION`, `NO STORES <SHELL>`, `DANGER CLOSE NOT ACKNOWLEDGED`, `TASKED`, `COOLDOWN n S`, `OUT OF RANGE n/max KM`, `TOO CLOSE n/min KM`, `NO FIRING SOLUTION`, `NO TOT`, `CANNOT MAKE TOT`, `SHEAF NOT AVAILABLE`, `CONTINUOUS FIRE NOT AVAILABLE`, `NOT AN AIR ASSET` (a REQUEST ON STATION).

**Who may correct:** the sender, the man on the OBSERVER line, anyone on the FIRES net.

- A CFF sent to the FIRES net (no battery on TO) reaches no battery: `NO ASSET ADDRESSED`.

> Code: `addons/support_fires/functions/fnc_srvThread.sqf`, `fnc_threadShape.sqf`, `fnc_threadMethod.sqf`, `fnc_threadVolley.sqf`, `fnc_threadReply.sqf`, `fnc_record.sqf`, `fnc_cardPreview.sqf`, `fnc_aimError.sqf`, `fnc_scatter.sqf`, `fnc_virtualRound.sqf`, `fnc_cue.sqf`; card reader `addons/support/functions/fnc_readOrder.sqf`; before SEND `addons/support/functions/fnc_cardPreview.sqf`, `addons/tacpad/functions/fnc_composeFire.sqf`.
> Ideas (shape, method of fire, recorded targets, stock, TOT to the second, magazine classes, the splash cue, the range check before firing): Tun Firesupport by Tuntematon / Armafinland. Airburst, aiming error, elliptical dispersion and the map footprint came out of the review of it.

### 3.4 Cruise missiles and loitering munitions

**Card: any CALL FOR FIRE** (GRID, POLAR, SHIFT) to the CRUISE or LOITER asset.

| Card says | Cruise | Loitering munition |
|---|---|---|
| Fire for effect, Suppress | One launch | One launch |
| Immediate suppression | At its quickest | The same |
| Adjust fire | `CANTCO - ADJUST NOT AVAILABLE` (with Cannot observe: fired for effect) | The same |
| Rounds number | Missiles, up to its salvo and what is left. Empty: 1 | Munitions, the same |
| Smoke, Illumination | `NO STORES SMOKE` / `NO STORES ILLUM` | The same |
| At my command | `READY - AT MY COMMAND` [CONFIRM] [EOM] | The same |
| Time on target | First missile lands at the TOT (HHMM, HHMMSS or +M) | `CANTCO - TOT NOT AVAILABLE` |
| Target shape, Method of fire | Not read. One launch at the point | The same |
| Airburst | Not read. The warhead is its own | The same |

No preview beside SEND, no SHOT / SPLASH sound: those are the batteries'.

1. **WILCO:** `ROGER, WILCO - ETA m:ss - FFE - 2 MISSILES - TOF n S - ...`
   Munitions: `... - 2 MUNITIONS - TRANSIT n S - ...`.
2. ON TASK at launch. `SHOT` as the first leaves.
   Missiles: `SPLASH` 5 s before the first lands. Munitions: no splash (it hunts).
3. When the last is gone: `ROUNDS COMPLETE - REQUEST BDA` [BDA] [REPEAT] [EOM]
4. **REPEAT** launches again, up to what is left. Nothing left: CLOSED `NO STORES - END OF MISSION`.
5. **BDA** > `END OF MISSION?`. **EOM** closes.

- ADJUST, FFE and CHECK FIRE do nothing here. No RECORD: a launcher's questions do not offer it.
- CLOSE while they are out: a missile flies on; a munition blows itself up where it is.
- Timeouts as artillery.

> Code: `addons/support_fires/functions/fnc_threadStrike.sqf`.

### 3.5 LIFT REQUEST (HLZ) - insertion

**Card: LIFT REQUEST (HLZ).**

Five parts: pickup (always safe), troop load (ALL IN), flight path, insertion, egress.

| Line | |
|---|---|
| PICKUP - ALWAYS SAFE | Empty = your position. No smoke, no circle, no clearance there |
| 6 ROUTE TO THE LZ | Up to 4 points (map click or marker), flown in order, nap of the earth. Empty = direct |
| 1 DROP-OFF LZ | **REQ** |
| 4 SECURITY AT THE DROP-OFF | GREEN / YELLOW / RED. RED = hot LZ. YELLOW / RED bring two drone escorts (when the module names a rotary escort class) |
| 5 MARKING METHOD | SMOKE, IR STROBE, PANEL, CHEMLIGHT, FLARE, NONE, OTHER + colour. What it tells you to pop at the LZ and what it looks for |
| 3 PAX / LOAD | Repeated in the WILCO |
| 7 EGRESS AFTER THE DROP | Up to 4 points, flown in order after PAX OFF, then home. Empty = home direct |
| WIND (fills itself), OBSTACLES, REMARKS | Not read by the AI |

0. **RAVEN is virtual until tasked** (2026-11-02). Row: IDLE, ETA from the module.
1. **You:** LIFT REQUEST to RAVEN (`@RAVEN`). SEND.
2. **RAVEN:** `ROGER, WILCO - ETA m:ss - <LOAD>`. ETA from the module.
   RED: `ROGER, WILCO - HOT LZ - REPLY CONFIRM TO LAUNCH - ETA m:ss - <LOAD>`.
   **You: CONFIRM** before it launches. RTB or ABORT instead: `CANTCO - HOT LZ NOT ACKNOWLEDGED`.
   Out on another task: `CANTCO - TASKED`. After a loss: `CANTCO - REPLACING`. No airframe left: `CANTCO - UNABLE - NO AIRFRAME`.
3. **RAVEN is made** over the module at once, nap of the earth, engines on, dark: `WHEELS UP INBOUND - ETA m:ss` and ON TASK. (A synced helicopter takes off from its stand.)

**Pickup (always safe)**

4. **RAVEN lands at the pickup** on a clear spot. No 1 MIN OUT, no circle, no clearance.
   `WHEELS DOWN AT PICKUP <grid>`, then `TROOP LOAD - ALL IN?`. [ALL IN] [ABORT]

**Troop load**

5. **Get in. Then ALL IN:** the tile, or ACE self-interaction > **ALL IN** inside the helicopter.
   The action shows to the request's sender and to any group leader aboard, while it loads.
   No ALL IN: it lifts when everyone of your side on foot within 150 m at touchdown is aboard, or the module's wait is up.
   This question has no 3 / 5 min timeout - the module's wait runs it.

**Flight path**

6. **RAVEN:** `WHEELS UP TO <grid of the LZ>`. It flies the ROUTE points in order (none: direct), nap of the earth.
   INBOUND every minute: `INBOUND ETA m:ss - <its grid>`.

**Insertion**

7. **1 min (or 1 km) from the LZ:** `1 MIN OUT - POP SMOKE - LZ STATUS?` (FLASH) and a popup `RAVEN 1 MIN OUT - POP SMOKE`. [COLD] [HOT]
   The word follows line 5: SMOKE, IR, FLARE or CHEMLIGHT. **Pop it.**
   It holds 1 km short, orbiting, until you answer.
   - COLD: in.
   - HOT: `HOT LZ - CONFIRM`. [CONFIRM] [RTB]. CONFIRM: in.
8. **At the LZ it circles** (200 m out, 50 m up). It does not land yet.
   - Mark seen within 150 m: `I SEE RED SMOKE` (or `IR STROBE`, `GREEN CHEMLIGHT`, `FLARE`) (FLASH). [CORRECT] [WRONG]
     WRONG: that mark is ignored, it looks again.
   - Nothing for 45 s: `CIRCLING - NO SMOKE SEEN - POP SMOKE`. [NO SMOKE] = land on the grid.
9. **RAVEN:** `READY TO LAND - CLEARED?` (FLASH). [CLEARED TO LAND] [HOLD] [ABORT]
   HOLD: asked again 30 s later. ABORT: home, CLOSED `RTB`.
10. **You: CLEARED TO LAND.** It lands on the mark (the grid after NO SMOKE).
11. **RAVEN:** `WHEELS DOWN <grid>`, then `WHEELS DOWN - PAX OFF?`. [PAX OFF] [HOLD]
    HOLD: `HOLDING - PAX OFF?` [PAX OFF] [RTB].

**Egress**

12. **You: PAX OFF.** RAVEN flies the EGRESS points in order (none: direct), then RTB. CLOSED `EGRESS - RTB`.
13. **Home:** it lands at the module, unloads and is removed (once no player is aboard). RAVEN is virtual again: the next request makes a fresh one. No respawn used.
    Shot down or disabled on the way: a respawn is used, row REPLACING for the respawn delay. None left: RAVEN leaves the SUPPORT list.

At any time: **RTB, ABORT or CLOSE** - home by the EGRESS points, CLOSED `RTB`. Home is the same RTB (step 13).

Timeouts on any question but ALL IN?: 3 min `NO RESPONSE - HOLDING`. 5 min: home, CLOSED `NO RESPONSE - RTB`.
A hot LZ never confirmed: `CANTCO - HOT LZ NOT ACKNOWLEDGED`.

Notes:

- **Next lift:** + TEMPLATE in the thread before PAX OFF: LIFT REQUEST, EXTRACTION, CASEVAC or PARADROP. Only the sender.
  The new card replaces this one and is flown from where it is. After PAX OFF the thread is closed: send a new request.
- The map pin draws the PICKUP, the ROUTE (`RTE 1`-`4`), the LZ and the EGRESS (`EGR 1`-`4`) as one line.
- **AiTR** (2026-11-02): the PICKUP (until it lifts) and the LZ (until PAX OFF) are highlighted in AiTR for your side - `LZ | PICKUP`, `LZ | INSERT`.
- A second request in a new thread while it flies one: `CANTCO - TASKED`.
- **Drone escorts:** two when line 4 is YELLOW or RED, none otherwise. See [3.12](#312-drone-escorts).

> Code: `addons/support_air/functions/fnc_transportOrder.sqf`, `fnc_transportLaunch.sqf`, `fnc_spawnAircraft.sqf`, `fnc_liftThread.sqf`, `fnc_liftJob.sqf`, `fnc_liftTick.sqf`, `fnc_liftReply.sqf`, `fnc_liftEnd.sqf`, `fnc_finish.sqf`, `fnc_replace.sqf`, `fnc_canAllIn.sqf`, `fnc_srvAllIn.sqf`; `addons/support/functions/fnc_inbound.sqf`, `fnc_lzClear.sqf`.

### 3.6 EXTRACTION (HLZ) - pickup from a hot zone

**Card: EXTRACTION (HLZ).** Pick the card first, then @ the transport.

Four parts: on station, extraction, troop load (ALL IN), egress.

| Line | |
|---|---|
| STATION | A map marker near the HLZ (marker only). It holds there until you call EXTRACT. Empty = 1 km short of the HLZ |
| PICKUP HLZ | **REQ**. The hot zone |
| LZ SECURITY | GREEN / YELLOW / RED of the HLZ. RED: CONFIRM before launch |
| MARKING METHOD | What you pop at the HLZ |
| NUMBER OF PASSENGERS | Said in the WILCO. Everyone of your side in range is loaded |
| EGRESS | Up to 4 points (map click or marker), flown in order from the HLZ. Empty = direct |
| DESTINATION | Grid or marker. Empty = home base |
| WIND (fills itself), OBSTACLES, REMARKS | Not read by the AI |

RAVEN is virtual until tasked (3.5 step 0). It is made over the module and flies to your STATION from there.

1. **You:** EXTRACTION to RAVEN. SEND.
2. **RAVEN:** `ROGER, WILCO - LAUNCHING - ON STATION IN m:ss - 4 PAX` (from the module, or a synced helicopter's stand).
   RED: `ROGER, WILCO - HOT LZ - REPLY CONFIRM TO LAUNCH - ON STATION IN m:ss - 4 PAX`. **CONFIRM.**
3. **RAVEN is made** over the module, nap of the earth, and flies to your station: ON TASK.

**On station**

4. **At the STATION it holds** - an orbit, dark, nap of the earth: `ON STATION - READY FOR EXTRACTION`. [EXTRACT] [ABORT]
   It waits for you. No 3 / 5 min timeout here.

**Extraction**

5. **You: EXTRACT.** RAVEN flies to the HLZ. INBOUND every minute.
6. **1 min (or 1 km) from the HLZ:** `1 MIN OUT - POP SMOKE - LZ STATUS?` (FLASH) + popup. [COLD] [HOT]
   It holds 1 km short until you answer. HOT: `HOT LZ - CONFIRM` [CONFIRM] [RTB].
7. **At the HLZ:** circle, `I SEE <MARK>` [CORRECT] [WRONG] / `CIRCLING - NO SMOKE SEEN - POP SMOKE` [NO SMOKE],
   `READY TO LAND - CLEARED?` [CLEARED TO LAND] [HOLD] [ABORT] - as 3.5 steps 8-10. **CLEARED TO LAND.**

**Troop load**

8. **RAVEN:** `WHEELS DOWN AT PICKUP <grid>`, then `TROOP LOAD - ALL IN?`. [ALL IN] [ABORT]
   **ALL IN** (tile or ACE action aboard), or it lifts when everyone in range is aboard or the wait is up - as 3.5 step 5.

**Egress**

9. **RAVEN** flies the EGRESS points in order (none: direct).
10. **With a destination:** `WHEELS UP TO <grid>`, INBOUND, `1 MIN OUT - POP SMOKE`, circle, CLEARED TO LAND - as 3.5 steps 8-10.
11. **RAVEN:** `WHEELS DOWN <grid>`, `WHEELS DOWN - PAX OFF?`. [PAX OFF] [HOLD]
12. **You: PAX OFF.** RAVEN RTBs, CLOSED `EGRESS - RTB` (2026-11-02: egress then RTB - no HOLD, RTB OR NEXT LIFT? any more).
    **No destination:** after the EGRESS points it flies home, lands, unloads, thread CLOSED.
13. **Home:** lands at the module, unloads, removed - as 3.5 step 13. Virtual again, no respawn used.

At any time: **RTB, ABORT or CLOSE** - home direct (the EGRESS points are flown from the HLZ only), CLOSED `RTB`.
Timeouts and CANTCO as 3.5. The map pin draws the STATION, the PICKUP, the EGRESS (`EGR 1`-`4`) and the DEST.
AiTR (2026-11-02): the HLZ (until it lifts) and the DEST are highlighted in AiTR - `LZ | EXTRACT`, `LZ | DEST`.
A module that does not fly the task it needs: `CANTCO - <CALLSIGN> does not fly LIFT` / `EXTRACT`.
Drone escorts: two when LZ SECURITY is YELLOW or RED, none otherwise. See [3.12](#312-drone-escorts).

> Code: as 3.5; `addons/support_air/functions/fnc_liftLegs.sqf`, `fnc_liftJob.sqf`.

### 3.7 CASEVAC by transport

**Card: 6-LINE CASEVAC** (2.5) to a TRANS asset. Pick the card, then @ the transport.

1. **You:** CASEVAC to RAVEN. SEND.
2. **RAVEN:** `ROGER, WILCO - ETA m:ss - <n> PATIENTS` (from the module). RED LZ: `HOT LZ - REPLY CONFIRM TO LAUNCH` first. **CONFIRM.**
3. **RAVEN is made** over the module, nap of the earth: `WHEELS UP INBOUND - ETA m:ss`, ON TASK, INBOUND every minute.
4. **1 min from the pickup:** `1 MIN OUT - POP SMOKE - LZ STATUS?` (FLASH) + popup. [COLD] [HOT]
5. **At the pickup:** circle, verify the mark, `READY TO LAND - CLEARED?`. **CLEARED TO LAND.**
6. **RAVEN:** `WHEELS DOWN <grid>`. **Load the patients.**
7. **RAVEN:** `PATIENTS ABOARD - DESTINATION?` (or `<n> ABOARD - DESTINATION?` when the wait ran out). [DEST] [MSG]
8. **You:** DEST with a grid or marker, or empty = DEFAULT.
   Or a MESSAGE with a grid, a marker name or `DEFAULT`.
   DEFAULT = the nearest ACE medical facility (the field hospital), else a hospital on the map, else its base.
9. **RAVEN:** `WHEELS UP TO FIELD HOSPITAL <grid>` (or `HOSPITAL`, `BASE`, or a grid).
10. **At the destination:** circle (no 1 MIN OUT here). Mark or `NO SMOKE`, then CLEARED TO LAND.
11. **RAVEN:** `WHEELS DOWN <grid>`, `WHEELS DOWN - PAX OFF?`. **Medics: unload. PAX OFF.**
12. **RAVEN:** `HOLD, RTB OR NEXT LIFT?` [HOLD] [RTB] [HLZ]. RTB: home to the module, removed (as 3.5 step 13).

Stop and timeouts as 3.5.
Drone escorts: two when line 4 is YELLOW or RED, none otherwise. See [3.12](#312-drone-escorts).
AiTR (2026-11-02): the pickup, then the destination, highlighted in AiTR - `LZ | CASEVAC`, `LZ | DEST`.

> Code: as 3.5; `addons/support/functions/fnc_medicalNearest.sqf`.

### 3.8 PARADROP

**Card: PARADROP** to a TRANS asset. People only. Supplies go by RESUPPLY.

| Line | |
|---|---|
| 1 DROP ZONE | **REQ** |
| LOAD | Who jumps. Repeated in the WILCO |
| MARKING | What you pop on the DZ |
| INGRESS / EGRESS | |

- It is made over the module when tasked (3.5 step 0) and flies straight to the DZ. It does not stop to pick anyone up. **Whoever is in the cabin jumps** - players too (a synced helicopter's cabin). Then it RTBs to the module and is removed (as 3.5 step 13).

1. **You:** PARADROP to RAVEN. SEND.
2. **RAVEN:** `ROGER, WILCO - ETA m:ss - <LOAD>`. Module that does not paradrop: `CANTCO - CANNOT PARADROP`.
3. **RAVEN:** `WHEELS UP INBOUND - ETA m:ss`, ON TASK, INBOUND every minute.
4. **1 min from the DZ:** `1 MIN OUT - POP SMOKE` (FLASH) + popup. **Mark the DZ.**
5. It crosses the DZ at the module's jump height. The cabin goes out one a second on static lines.
6. **RAVEN, heading home:** `PACKAGE AWAY - CONFIRM RECEIPT`. [RECEIVED] [NOT FOUND]
   RECEIVED: CLOSED `RECEIVED`. NOT FOUND: CLOSED `NOT FOUND - DROPPED AT <grid>`.

A PARADROP sent to a LOGI asset: `CANTCO - PARADROP IS A TRANSPORT CARD - SEND RESUPPLY`.
AiTR (2026-11-02): the DZ is highlighted in AiTR until the thread closes - `DZ | PARA`.
Drone escorts: none (the card has no LZ security line). See [3.12](#312-drone-escorts).

> Code: `addons/support_air/functions/fnc_liftLegs.sqf`, `fnc_liftTick.sqf`.

### 3.9 RESUPPLY

**Card: RESUPPLY REQUEST** to a LOGI asset.

| Line | |
|---|---|
| ITEM 1 | **REQ**. A drop-down of the pre-made crates of the LOGI asset on TO (or of every LOGI asset when none is on TO) + COUNT (empty = 1) |
| ITEM 2-4 | Optional, same |
| DELIVERY POINT | **REQ** |
| METHOD | AIRDROP or SLING. Empty = the asset's first |
| MARKING | SMOKE, IR STROBE, CHEMLIGHT, FLARE... + colour. Set off where the load lands |
| REMARKS | Not read by the AI |

Put the asset on TO first (`@` it), so the drop-down lists its crates.

1. **You:** RESUPPLY to the LOGI asset. SEND.
2. **Asset:** `ROGER, WILCO - ETA m:ss - 2 x HUNTER - AIRDROP`.
   CANTCO: `NO STORES <NAME>` (not in its catalog), `NO <METHOD>` (it does not fly it), a SLING load it cannot lift (`... CANNOT GO ON A HOOK`, `... IS TOO HEAVY ...`, `... TAKES n AT MOST ...`), `NO TARGET LOCATION`, `TASKED`.
3. **Asset:** made over its module at once - AIRDROP at its flight height (helicopter 30 m, plane 4000 m), SLING one helicopter per item, 60 m apart, the load on the hook (30 m plus rope and load). `WHEELS UP INBOUND - ETA m:ss`, ON TASK, INBOUND every minute.
4. **1 min out:** `1 MIN OUT - POP SMOKE` (FLASH) + popup.
5. AIRDROP: items out under chutes, one a second. SLING: each sets its item down. Then each flies home to the module and is removed.
6. **Last item down:** `PACKAGE AWAY - CONFIRM RECEIPT`. [RECEIVED] [NOT FOUND]
   - RECEIVED: CLOSED `RECEIVED - delivered ...`.
   - NOT FOUND: every item sets off its marking again, CLOSED `NOT FOUND - LANDED AT <grids>`.
7. Timeouts: 3 min `NO RESPONSE - HOLDING`, 5 min CLOSED `... - NO RESPONSE`.

- **ABORT or CLOSE** (tiles; RTB from + TEMPLATE): before launch - stood down (CANTCO). In the air - recalled, CLOSED with what was delivered.
- A lost aircraft's load is not delivered. A lost aircraft uses a respawn; a delivery does not.
- **AiTR** (2026-11-02): the DELIVERY POINT is highlighted in AiTR until the thread closes - `DROP | RESUPPLY`, `DROP | SLING`.
- Drone escorts: a plane's first aircraft always takes two; a helicopter none (the card has no LZ security line). See [3.12](#312-drone-escorts).

> Code: `addons/support_logistics/functions/fnc_srvThread.sqf`, `fnc_catalogNames.sqf`, `fnc_inbound.sqf`.

### 3.10 QRF

**Card: REACT/QRF LINK-UP** to a QRF asset.

| Line | |
|---|---|
| 2 LINK-UP LOCATION | **REQ** |
| 5 ACTION ON ARRIVAL | CORDON, BLOCK, CCP: the squad holds the point. REINFORCE: it joins you. ASSAULT: the module's default |
| RECOGNITION SIGNALS | FAR / NEAR |
| 3 SUGGESTED ROUTE, 4 SPECIAL ATTACHMENTS, 1 WHO LINKS WITH WHO, REMARKS | Write STATIC, PARA or JUMP in any of them for a static-line drop (when the module flies it). Otherwise AIR ASSAULT |

0. **The QRF aircraft is virtual until tasked** (2026-11-02). Row: IDLE, ETA from the module.
1. **You:** QRF to the asset. SEND.
2. **QRF:** `ROGER, WILCO - ETA m:ss - AIR ASSAULT - <WHO>` (or `STATIC LINE`). ETA from the module.
   Out on another task: `CANTCO - TASKED`. After a loss: `CANTCO - REPLACING`. No airframe left: `CANTCO - UNABLE - NO AIRFRAME`.
3. **QRF:** the aircraft is made over the module at once, the squad aboard - air assault nap of the earth, static line on its slope to the jump height (4000 m for a plane far out). `WHEELS UP INBOUND - ETA m:ss`, ON TASK, INBOUND every minute.
4. **1 min out:** `1 MIN OUT - POP SMOKE` (FLASH) + popup.
5. **Air assault:** circle, `I SEE <MARK>`, `READY TO LAND - CLEARED?` - as 3.5 steps 8-10. **CLEARED TO LAND.**
   Static line: a slow pass over the grid, chutes open on exit.
6. **QRF:** `WHEELS DOWN`, then `SQUAD DOWN AT <grid> - <n> MEN - HOLDING - LINKED UP?` (or `YOURS` when it joins you). [RECEIVED] [CLOSE]
7. **You: RECEIVED** when linked up. CLOSED `LINKED UP - ...`.
8. **The aircraft RTBs** after the squad is out: to the module, removed there. Virtual again: the next request makes a fresh aircraft and squad. No respawn used.
   Shot down or disabled: a respawn is used (row REPLACING for the delay). None left: the QRF leaves the SUPPORT list.

- **RTB / ABORT** (tiles) in the air before anyone is out: the insertion is off, CLOSED `RTB`.
- Air assault circling unanswered 5 min: off, home, CLOSED `NO RESPONSE - RTB`.
- No link-up answer: CLOSED `... - NO RESPONSE`.
- **AiTR** (2026-11-02): the landing point is highlighted in AiTR until the squad is down - `LZ | QRF` (static line `DZ | QRF`).
- Drone escorts: a plane always two; a helicopter none (the card has no LZ security line). See [3.12](#312-drone-escorts).

> Code: `addons/support_air/functions/fnc_qrfThread.sqf`, `fnc_qrfOrder.sqf`, `fnc_qrfLaunch.sqf`, `fnc_spawnAircraft.sqf`, `fnc_qrfTick.sqf`, `fnc_qrfLanded.sqf`, `fnc_homeTick.sqf`, `fnc_writeOff.sqf`, `fnc_replace.sqf`.

### 3.11 JUMP REQUEST

**Squad leaders and admins only.** The stick is your squad.
The aircraft: each **JMSB - Jump Aircraft** module of your side, by its call sign (several possible, one run at a time each).
No module for your side: one aircraft, SKYTRAIN. SKYTRAIN below.

| Line | |
|---|---|
| TYPE | **REQ - tick one**: HALO, HAHO, STATIC |
| PASSES | 1-4. Empty: the aircraft's default |
| EXIT | AUTO (out at the green light, one every 0.7 s) or MANUAL (each man presses JUMP). Empty: the aircraft's default |
| RED LIGHT | **REQ**. Start of the run. Map click or marker |
| GREEN LIGHT | **REQ**. Where the stick goes. At least 100 m past the red light |
| PICKUP | A strip or marker. Empty = where you stand |
| REMARKS | |

0. **A module's aircraft is virtual until tasked** (2026-11-02). Row: IDLE with its respawns. The JUMP REQUEST is its task.
1. **Every jumper:** a parachute. HALO / HAHO: an oxygen mask too. Gather within 200 m of the pickup.
2. **Leader:** JUMP REQUEST to SKYTRAIN (`@SKYTRAIN`). SEND.
3. **SKYTRAIN checks at once.** Not ready: CANTCO, the thread ends. Fix it and send again.
   `2 MEN WITHOUT A PARACHUTE`, `1 MAN WITHOUT A MASK`, `NOBODY AT THE PICKUP`, `SQUAD LEADERS ONLY`, `TASKED` (your squad already has a run, or the aircraft is flying one),
   `COOLDOWN n S`, `REPLACING IN n S`, `RTB` (the last aircraft still flying home), `UNABLE - NO AIRFRAME`, `COULD NOT LAUNCH`, `NO JUMP TYPE`, `NO RED LIGHT`, `NO GREEN LIGHT`, `RED AND GREEN LIGHT TOO CLOSE`, `NO JUMP AIRCRAFT`.
4. **SKYTRAIN:** `ROGER, WILCO - HALO 6000 M - 8 MEN - 2 PASSES - AUTO EXIT - BOARD TO RED LIGHT m:ss`.
   The time is from the module to the red light at cruise, counted from BOARD.
   The aircraft is made at the WILCO **over the module, 2000 m up**, engines on, dark, and orbits the module. A plane brings two escort drones (3.12).
   Added when true: `SHIFTED n M FOR WIND` (both lights moved upwind; the stick still lands on your green light), `n NOT AT THE PICKUP`.
5. **SKYTRAIN, 3 s later:** `ON STATION - SEND BOARD WHEN READY`. [BOARD] [ABORT]
   No 3 / 5 min timeout. Not boarded in 30 min: CLOSED `NOT BOARDED - STOOD DOWN`.
   ABORT, RTB or CLOSE here: CLOSED `NOT BOARDED - STOOD DOWN`. The aircraft flies home and is removed.
6. **Leader: BOARD** (tile; the BOARD card). SKYTRAIN checks the stick again - men within 200 m of the pickup, chutes, masks.
   - Not ready: `2 MEN WITHOUT A PARACHUTE - SEND BOARD WHEN READY`. [BOARD] [ABORT] Fix it, BOARD again.
   - Ready: every man at the pickup is moved aboard where he is (a cargo seat, or standing in the bay).
     ON TASK `STICK ABOARD - 8 MEN - RED LIGHT IN m:ss`.
7. **The run-in:** from its orbit over the module it flies to the start of the run, 3 km short of the red light,
   climbing or descending from 2000 m to the jump altitude: STATIC the module's static-line altitude (default 150 m), HALO / HAHO the module's (default 6000 m).
   At the start it turns in: `INBOUND PASS 1 OF 2 - RED LIGHT IN m:ss`.
8. **SKYTRAIN:** `RED LIGHT PASS 1 OF 2 - STAND BY` (static line: `STAND UP, HOOK UP`) (FLASH).
   JUMP appears in every man's action menu.
9. **SKYTRAIN:** `GREEN LIGHT - GO PASS 1 OF 2 - 4 OUT ON THE LIGHT` (AUTO) or `... - JUMP FROM THE ACTION MENU` (MANUAL) (FLASH).
   MANUAL: jump within 1.5 km past the light.
10. **SKYTRAIN:** `STICK OUT 4 OUT - 4 ABOARD`.
    More passes: `- CIRCLING FOR PASS 2`, then `INBOUND PASS 2 OF 2 - RED LIGHT IN m:ss`, and 8-10 again.
11. **Last pass, men still aboard:** `MEN STILL ABOARD - HOLDING OVER THE DZ`. [GO] [ABORT]
    It orbits the green light, JUMP open.
    - **GO:** the rest go out. `GREEN LIGHT - GO 2 OUT OVER THE DZ`.
    - **ABORT:** it keeps holding; each man jumps or stays.
    - 3 min: `NO RESPONSE - HOLDING`. 5 min: the rest are put out, `NO RESPONSE - 2 OUT OVER THE DZ`.
12. **SKYTRAIN leaves the DZ:** CLOSED `STICK OUT - LEAVING THE DZ`, or `CABIN EMPTY - LEAVING THE DZ` after a hold.
    Shot down: `AIRCRAFT LOST`. Run older than 30 min (from BOARD): `OUT OF TIME - n PUT OUT`.
13. **Home** to the module at 2000 m (row RTB) and **removed there** (within 600 m, nobody aboard; after 20 min wherever it is). No respawn used.
    Then REARMING for its cooldown (default 120 s), then IDLE. The next JUMP REQUEST makes a fresh aircraft.

- **ABORT or RTB** (CLOSE too) after BOARD: no more passes. It holds over the green light,
  `ABORTED - HOLDING OVER THE DZ - n ABOARD - JUMP WHEN READY` [GO], and leaves when the cabin is empty.
  Before BOARD: CLOSED `NOT BOARDED - STOOD DOWN` (step 5).
- **Respawns** (module, default 0) and **Respawn Delay** (default 300 s): only an aircraft lost (destroyed, pilot dead, cannot fly) uses one; the next JUMP REQUEST after the delay makes a new one. Going home uses none. None left: `UNABLE - NO AIRFRAME`, off the list. Sorties and Response Delay are retired.
- **Escorts:** a plane always takes two fixed-wing drones (the module's Fixed-Wing Escort Class; empty - the side's UCAV). A helicopter none (a jump has no LZ security).
- **A side with no module** keeps SKYTRAIN as before: made at the run-in the moment after the WILCO, no BOARD (everyone at the pickup is put aboard at WHEELS UP), removed when it leaves, no respawn count.
- Static line: the canopy opens 1 s after exit. HALO / HAHO: each man pulls his own. The phone shows ALT from the exit.
- The leader's map draws the run as flown (RUN-IN, RED, GREEN) while ON TASK.
- **AiTR** (2026-11-02): the GREEN LIGHT is highlighted in AiTR from the WILCO until every jumper is down - `DZ | HALO` (`HAHO`, `STATIC`); `DZ | RELEASE` too when the wind moved the run.

> Code: `addons/jumpmaster/functions/fnc_moduleJump.sqf`, `fnc_airUp.sqf`, `fnc_airTick.sqf`, `fnc_airHome.sqf`, `fnc_airLost.sqf`, `fnc_spawnAircraft.sqf`, `fnc_asset.sqf`, `fnc_srvThread.sqf`, `fnc_srvAskBoard.sqf`, `fnc_srvBoard.sqf`, `fnc_srvLaunch.sqf`, `fnc_srvTick.sqf`, `fnc_srvGo.sqf`, `fnc_srvAbort.sqf`, `fnc_srvEnd.sqf`, `fnc_srvRelease.sqf`; the BOARD card `addons/support/functions/fnc_builtinReplies.sqf`.

### 3.12 Drone escorts

Two drone wingmen with a support aircraft (2026-11-02: by LZ security for helicopters, always for fixed-wing). Built, not seen in game.

**Set up (3DEN, the module's attributes):**

- **Fixed-Wing Escort Class:** the drone a plane takes. Empty: the side's vanilla UCAV (`B_` / `O_` / `I_UAV_02_dynamicLoadout_F`).
- **Rotary Escort Class:** the drone a helicopter takes. Empty: none.
- On the CAS, QRF Insertion, Transport, Logistics and Jump Aircraft modules. Transport has the rotary class only.
- A class not in the mission or the wrong kind: no escort (one RPT warning).
- The old **Drone Escorts** on / off is retired. A mission that set it still loads.

**When they come:**

| Lead | Escorts |
|---|---|
| Plane (CAS jet, QRF plane, logistics plane, jump plane) | 2, always |
| Helicopter, LZ security YELLOW or RED | 2. Read 5 s after launch |
| Helicopter, GREEN, or a card with no LZ security line (CAS REQUEST, QRF, PARADROP, RESUPPLY, JUMP REQUEST), or none ticked | none |
| Logistics, several aircraft | with the first aircraft only |
| CAS drones | none |

**What they do:**

- Made with the lead, beside it, over its module. Removed with it.
- Fly a wing slot each side of the lead, dark like it: nap of the earth (helicopter) or 4000 m (plane), stacked - the first escort 40 m / 150 m above that, the second twice that. Never at the lead's height or each other's (2026-11-05).
- Slots: 150 m out, 100 m back (helicopter). The left slot goes to the escort already on the left: they never cross over the lead.
- Orbit it when it is slow or landed: 300 m out, each one going on round from where it is, all the same way. Never through the middle.
- Engage the missile shooter first, else the nearest enemy near the lead, the task point or its next waypoint.
  Range: helicopter 1.5 km, plane 5 km. Never more than 2 km / 8 km from the lead.
- A missile at the lead or at them: every escort, and an AI lead, puts out flares (3 bursts).
- **ALL ATTACK** (fixed-wing CAS, 3.2): they break off and attack the target area, then rejoin.
- Go home with the lead and are removed with it.
- Lead lost: they fly back to where they were made and are removed (within 1 km, or after 10 min).
- A lost escort is not replaced.

**In the thread:** nothing, except ALL ATTACK's `DRONES DESTROYED <n>` in the OFF.

> Code: `addons/support_air/functions/fnc_escortLaunch.sqf`, `fnc_allAttack.sqf`; `addons/support/functions/fnc_escort.sqf`, `fnc_escortTick.sqf`, `fnc_escortMissile.sqf`, `fnc_escortEnd.sqf`, `fnc_escortAttack.sqf`, `fnc_escortStrike.sqf`.

---

## 4. Quick reference

| Card | Send to | Required lines | First reply |
|---|---|---|---|
| TROOPS IN CONTACT | TIC key: first shared net (C2) | LOCATION (key fills it) | Side alert + map marker. ROGER from C2 |
| SITREP | The TIC thread (SEND SITREP), or C2 | None | ROGER |
| SALUTE | C2 / C2.reports / leader | S SIZE, L LOCATION | ROGER |
| MIST | MEDICAL.mist / medic | M MECHANISM | ROGER |
| 6-LINE CASEVAC | TRANS asset, or MEDICAL.medevac / crew | 1 PICK-UP SITE | AI: `ROGER, WILCO - ETA m:ss - n PATIENTS` |
| DEFREP | Leader / C2 | None | ROGER |
| AIRFRAME CHECK-IN | JTAC (player pilot) | None | ROGER |
| METT-TC | OPORD thread (leaders only) | None | ROGER |
| CAS REQUEST | CAS asset (helicopter, drone, on-station jet) | 1 TARGET, 5 DESCRIPTION | `ROGER, WILCO - ETA m:ss - <DESCRIPTION>` |
| REQUEST ON STATION | CAS asset | 2 AREA (map marker) | `ROGER, WILCO - LAUNCHING - ON STATION IN m:ss` - made over its module then |
| ALL ATTACK | Fixed-wing CAS strike thread (tile beside CLEARED HOT) | None | `ON TASK - ALL ATTACK - FLIGHT IN HOT`; no escorts: `NO ESCORTS - USE CLEARED HOT` |
| BDA | In the strike / fire thread | RESULT, DECISION (RE-ATTACK or EGRESS) | RE-ATTACK - AWAITING CLEARED HOT / EGRESS - RTB / END OF MISSION? |
| CFF GRID | ARTY / CRUISE / LOITER | TARGET - GRID (a grid, a marker, a recorded target `TH1001`), TYPE OF MISSION | `ROGER, WILCO - ETA m:ss - <MISSION> - <ROUNDS> - <METHOD> - <SHAPE> - TOF n S` |
| CFF POLAR | ARTY / CRUISE / LOITER | Direction, distance, TYPE OF MISSION | as CFF GRID |
| CFF SHIFT | ARTY / CRUISE / LOITER | KNOWN POINT (a recorded target too), TYPE OF MISSION | as CFF GRID |
| RECORD AS TARGET | In the fire thread (tile on ROUNDS COMPLETE, END OF MISSION?, CHECK FIRE - HOLDING) | None | `RECORDED AS TARGET TH1001` + a marker for your side |
| LIFT REQUEST (HLZ) | TRANS | 1 DROP-OFF LZ | `ROGER, WILCO - ETA m:ss - <LOAD>` |
| EXTRACTION (HLZ) | TRANS | PICKUP HLZ | `ROGER, WILCO - LAUNCHING - ON STATION IN m:ss - n PAX` |
| PARADROP | TRANS | 1 DROP ZONE | `ROGER, WILCO - ETA m:ss - <LOAD>` |
| RESUPPLY REQUEST | LOGI | ITEM 1, DELIVERY POINT | `ROGER, WILCO - ETA m:ss - n x <ITEM> - <METHOD>` |
| REACT/QRF LINK-UP | QRF | 2 LINK-UP LOCATION | `ROGER, WILCO - ETA m:ss - AIR ASSAULT - <WHO>` |
| JUMP REQUEST | SKYTRAIN (leaders, admins) | TYPE, RED LIGHT, GREEN LIGHT | `ROGER, WILCO - <TYPE> <ALT> M - n MEN - ...`, then `ON STATION - SEND BOARD WHEN READY` |
| BOARD | In the jump thread (tile) | None | `STICK ABOARD - n MEN - RED LIGHT IN m:ss` |

**Timers**

| What | Time |
|---|---|
| ROGER folded into WILCO | 2 s |
| Between TICs | 30 s |
| AWAITING CLEARED HOT | 60 s after WILCO |
| INBOUND updates | every 60 s |
| 1 MIN OUT | 60 s out (LZ STATUS? also at 1 km) |
| No mark seen while circling | 45 s, then `CIRCLING - NO SMOKE SEEN` |
| HOLD at READY TO LAND | asked again after 30 s |
| No answer to a question | 3 min `NO RESPONSE - HOLDING`, 5 min the asset ends the job |
| CONTACT OVER? SEND SITREP | 180 s quiet after a TIC |
| BINGO warning | 2 min before it leaves |
| Support aircraft made | at the WILCO, over its module (virtual until tasked) |
| Support aircraft removed | over its module when home; 20-30 min home leg cap |
| ALL ATTACK drones | rejoin when the area is clear, Winchester, 5 min, or the jet egresses; the OFF waits up to 2 min |
| Idle thread closes | 60 min (mission setting) |

> Cards as the mod carries them - the mod's own card always wins over the deck's (2026-11-02): `addons/messaging/functions/fnc_builtinCards.sqf` (reports, common replies), `addons/support/functions/fnc_builtinCards.sqf` (support requests; `fnc_builtinFires.sqf`, `fnc_builtinReplies.sqf`). Decisions: `docs/REVIEW_REPORT_CARDS_2026-11-02.md` section 7.
