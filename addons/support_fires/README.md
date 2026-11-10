# Support Fires

`jmfsb_support_fires`

Fires for TAC//SUPPORT: artillery, cruise missiles and loitering munitions.
A provider of the support core (`jmfsb_support`, kind `fires`, asset ids
`fires:<n>`) - see `addons/support/README.md` for the contract and
`docs/DESIGN_SUPPORT.md` for the brief (phase 2).

**The modules act like Simplex, except that artillery is virtual** (user,
2026-10-20). Simplex Support Services is a behaviour reference only: no code
of it is used and nothing depends on it.

**No module, no asset.** Each placed module is one row on the support page and
nothing else is: a mission without a **JMSB - Cruise Missiles** module has no
cruise missiles. Many modules of each kind may be placed. No module carries a
side (D59): every asset belongs to the players' side, and a loitering
munition's prey is the enemy side worked out from the mission's side relations.

| Module | Asset type | What fires |
|---|---|---|
| JMSB - Virtual Artillery | `arty` (ARTILLERY) | nothing on the map: each round is the shell class, spawned on its descent over the target after the time of flight from the module |
| JMSB - Artillery Battery *(retired, hidden)* | `arty` (ARTILLERY) | the same virtual rounds; synced guns are read, never fired - see below |
| JMSB - Cruise Missiles | `cruise` (CRUISE MISSILES) | a real missile projectile launched at the module and flown the whole route |
| JMSB - Loitering Munitions | `loiter` (LOITERING MUNITIONS) | a real air vehicle (Switchblade 600 with the mod, else a Darter) that hunts the area |

**Artillery is virtual.** No gun anywhere aims or fires for this addon. Both
artillery modules list under the shared ARTILLERY tab, beside any other
provider's batteries.

## On the support page

Every task needs a TARGET point. The steppers write parameter slots 12-19 and
32-35 (36 is the adjust call, 37-39 are kept for this addon; 20-31 and 40-48 are support_air's):

| Slot | Stepper | Used by |
|---|---|---|
| 12 | ORDNANCE - the battery's own round types, with rounds left | artillery |
| 13 | ROUNDS PER GUN - up to the module's Max Rounds Per Gun | artillery |
| 19 | SHEAF TYPE - CONVERGED, PARALLEL, BOX, CREEPING (those the module offers) | artillery |
| 14 | SHEAF (m) - the half-width of the square the page draws round the target, up to the module's Max Sheaf Length (300 m by default, 2026-11-02) | artillery |
| 15 | GUNS - ALL, or 1..n | artillery |
| 33 | INTERVAL - seconds added between one gun's rounds (hidden when Max Interval is 0) | artillery |
| 32 | DELAY - seconds before the first round or missile (hidden when Max Delay is 0) | artillery, cruise missiles |
| 34 | REPEAT - extra volleys (hidden when Max Repeats is 0) | artillery |
| 35 | COORDINATE - ALONE, or WITH NEARBY batteries (only offered when one is in reach) | artillery |
| 36 | ADJUST - no stepper: the ARTY screen's adjust call (see Adjust fire) | artillery |
| 16 | MISSILES - up to the salvo size | cruise missiles |
| 17 | MUNITIONS - up to the launch size | loitering munitions |
| 18 | SEARCH RADIUS (m) | loitering munitions |

**Before CONFIRM** (the core's `preview` hook) the board's VERDICT line reads
the order exactly as CONFIRM would send it: `ETA 70 S - 4 GUNS x 3 HE` (a range
when the module has a response time; volleys, `+ NEARBY` and `ONLY n LEFT`
when they apply), `TIME TO TARGET 95 S - 2 MISSILES`, `ON STATION IN 120 S -
2 MUNITIONS, SEARCH 300 M`. It holds CONFIRM only for what the order would be
refused for: busy or cooling down, nothing left, `OUT OF RANGE - 14.2 KM, MAX
12 KM`, `TOO CLOSE - 300 M, MIN 420 M`. **On the map** (the `overlay` hook) the
picked asset shows its position and its range rings, `MIN` and `MAX`: a
battery both, a cruise missile launcher its 1 km minimum and its reach, a
loitering munition site its reach.

A request is refused on the requester's own machine, with the reason, when it
cannot be fired: no target, inside the minimum or beyond the maximum range,
nothing of that type left, busy or cooling down. RTB is CHECK FIRE for a
battery (virtual rounds not yet fired are not fired; those in the air land;
every battery that joined checks fire too), and self-destruct for loitering
munitions. A cruise missile in flight cannot be recalled.

The server checks every order and recall again for whoever sent it (review
S6). They go by `remoteExecCall` to `fnc_request` and `fnc_abort`, never by a
CBA event. The requester is the sending machine's own player, who must pass
the Support tasking tag gate and own the asset's side. The server reruns the
same `fnc_check` the client ran: target, range, what is left, busy or cooling
down. It reads the rounds, sheaf and guns from the parameter array itself, so
a client cannot fire more than the module allows. No client can fire or
recall another side's asset.

The server acknowledges every order with what will happen and when
(`jmfsb_support_ack`), and the asset talks on the notify rail of its side:
fire mission received (with the wait), SHOT with the impact grid and time of
flight, SPLASH, rounds complete, check fire, missile away, on station, target
acquired, impact, and **rearmed, ready for tasking** when its cooldown runs
out. While a mission runs its target is **marked on the map** for the side
(an icon, and the sheaf or search area as an outline), and the marker goes
when the mission ends. The words and the marker go from the server by
`remoteExec` (`fnc_sayLocal` to the side, `fnc_markLocal` with JIP,
`fnc_unmarkLocal`), and a client takes them only from the server (review S7).

### Adjust fire (2026-11-01)

The TAC//SUPPORT ARTY screen's adjust pad (tacpad_apps README, "The ARTY
screen") calls a battery again on the same mission. The call rides in
parameter slot **36** (support README): 0 an ordinary mission, as before;
1 an **adjusting round**; 2 **fire for effect**; 3 **end of mission**. It
goes the usual way - the core's `request`, `fnc_task`, then
`remoteExecCall` to `fnc_request` - with the same sender checks.

- An order with 1 or 2 opens the mission as ever, and the battery **holds**
  for the player who sent it once its salvo is down (`fnc_adjustHold`):
  status `adjusting`, the mission's token, marker and thread kept, the
  player's Steam id public on the module (`holdBy`). An adjusting round is one
  round from one gun on the point, no sheaf, no repeat, no other battery.
- While it holds, that player's next call (`fnc_adjustFor`, run by
  `fnc_check` on his machine and again on the server, and by the core's
  `available` ask) goes on the held mission (`fnc_adjustNext`): an adjusting
  round or the whole order at the corrected point he sends, at the module's
  least response time, the marker moved there. Refused: another player's
  call (`adjusting for another observer`), and any call but END while a
  salvo is still in the air (`wait for the splash`). END stands the battery
  down (`end of mission, over`); END with nothing held is refused.
- CHECK FIRE is the RTB recall, as for any mission. With no call for
  300 seconds after a salvo is down the battery ends the mission itself.
- **The rounds** of a held mission are published on the module as they are
  fired (`rounds`: salvo, number, where it lands, when, the newest 32) and
  handed to the board by the `overlay` hook as `round` shapes - the ARTY
  screen's round log and splashes. An ordinary mission publishes none.

### Call for fire by message (2026-11-01)

`docs/DESIGN_SUPPORT_MESSAGING.md` step 6 (user, 2026-11-01: "per the doc i
want to use the messaging system to call ai support"). A **CALL FOR FIRE**
card filed in TAC//MSG to a battery's box (`B:SUPPORT:fires:<n>`) is a fire
mission; the battery answers in the thread as itself. A cruise missile or
loitering munition launcher takes the same card since 2026-11-01 (below,
"Cruise missiles and loitering munitions by message"). Built, not seen in
game.

**The card -> the fire** (`srvThread`, the core's `thread` hook; the card is
read by the support core's `readOrder`):

| Card | Fire |
|---|---|
| Warno 1 A ADJUST | one adjusting round from one gun, then the battery holds for the observer (`ADJ_ROUND`, `adjustHold`). TYPE OF MISSION is "tick one" (required, 2026-11-02): a card with none ticked is not sent (messaging `validate`). An older deck's card with none ticked still reads as an adjust |
| Warno 1 B FFE, C SUPPRESS | the whole order, then it holds (`ADJ_FFE`) |
| Warno 1 D IMMEDIATE SUPPRESSION | the whole order at the battery's least response time |
| Warno 2 | its first number is how many guns, else all |
| the target - CFF GRID, CFF POLAR, CFF SHIFT (user, 2026-11-02: "break arty in to 3 reports grid polar and shift fire") | CFF GRID (`callforfire`): the Warno 3A grid. CFF POLAR (`cffpolar`): the Polar line's direction and distance from the observer - the Observer line's grid, else the sender. CFF SHIFT (`cffshift`): LEFT / RIGHT and ADD / DROP metres from its known point (a grid or a map marker), on the observer-target line; UP / DOWN: the guns are laid for the known point's height plus it (`layHeight`) - a target at another height is missed along the line of fire by the difference over the tangent of the descent, long when laid high, short when laid low; give UP / DOWN whenever the target is 35 m or more above or below the known point. All three are answered alike - the same fire, the same follow-ups. An older CFF GRID's polar / shift lines are still read. None: CANTCO `NO TARGET LOCATION` |
| Engagement A-F + rounds | the shell - HE, SMOKE, ILLUM, CLUSTER, GUIDED (laser-guided); AIRBURST fires HE that bursts 7-12 m over the ground (2026-11-02, below), WILCO `4 GUNS x 3 HE AIRBURST`; not carried: `NO STORES <shell>`; none ticked: the battery's first. The number is rounds per gun, up to Max Rounds Per Gun |
| Danger Close tick / distance | the card's `dangerClose` option (600 m, D5): a friendly inside it, or the card's distance under it, without the tick - `DANGER CLOSE NOT ACKNOWLEDGED`. Checked again on every correction |
| Shape A-D + size, End (2026-11-02) | TARGET SHAPE, optional (`threadShape`): POINT or none - every round on the point; AREA - CONVERGED round it, the size its radius (none: 100 m); LINEAR - the guns along a line, each over its own stretch: from the point to End.A's far end (aimed at the middle), or the size long (none: 200 m) at End.B's attitude round the point (none: square to the line of fire); CREEPING - a walk from the point to the far end, or the size along the attitude (none: away from the guns), every round of the mission one step further, the guns side by side 30 m apart. Each size up to Max Sheaf Length. The module's Sheaf Types allow them - AREA CONVERGED or BOX, LINEAR PARALLEL, CREEPING CREEPING - else `SHEAF NOT AVAILABLE`. A line's or a walk's ends are checked for range and danger close as the point is |
| Method A-C (2026-11-02) | METHOD OF FIRE, optional (`threadMethod`): INTERVAL n s between one gun's rounds (up to Max Interval), n VOLLEYS (up to Max Repeats + 1; they follow on the guns' own rhythm - each gun's next round one reload plus the interval after its last - with no pause between volleys, Simplex's loops; 2026-11-05), or CONTINUOUS FOR n MIN - each gun a round every reload plus the interval for that long, the rounds per gun worked out from it, up to Max Continuous Fire (0: `CONTINUOUS FIRE NOT AVAILABLE`). Illumination kept over a target is CONTINUOUS |
| Control B AT MY COMMAND | laid (status `laid`, busy), WILCO, prompt `READY - AT MY COMMAND`; fires on the observer's `confirm` |
| Control C + TOT | the first round lands at the TOT line's time, game time, no more than an hour ahead: HHMM (HH:MM), HHMMSS (HH:MM:SS) or +M - M game minutes from now (2026-11-02); `NO TOT` / `CANNOT MAKE TOT`. WILCO says the time it fires for, `TOT 1430`, to the second (`TOT 143015`) for a time given so or from now |
| Control D CANNOT OBSERVE | an adjust is fired for effect; after it `ROUNDS COMPLETE - <left> - END OF MISSION?` |
| Control A, E, F | fire when ready |

Busy, rearming, spent or out of reach is the reach card's word: `TASKED`,
`COOLDOWN n S`, `NO STORES`, `OUT OF RANGE n/max KM`, `TOO CLOSE n/min KM`,
`NO FIRING SOLUTION`. No delay, never coordinated with another battery. The
shape and the method go through the board's own parameter slots (14, 19, 33,
34 - `readOpts` holds them to the module's limits); the linear sheaf, the
attitude, the length and a continuous fire's rounds per gun are set on the
options after it.

A REQUEST ON STATION to a battery or a launcher is CANTCO `NOT AN AIR ASSET`
(user, 2026-11-02: "on station is not a fire mission its just an order to get
in the air"), never read as a fire mission. Built, not seen in game.

**A call for fire that never reaches a battery** (user, 2026-11-02: "arty
never replied"). Only the battery's own box makes it answer: `@FOX 1-1` on the
CC line (it moves to TO), or FOX 1-1 picked in the TO picker's SUPPORT group.
A CFF sent on a net (FIRES, a squad) is filed there and no battery hears it -
the composer now says `NO ASSET ADDRESSED` upper right and the RPT has the
line. A CFF refused on the sender's machine (the target lines and TYPE OF
MISSION - "tick one" - are required; TARGET DESCRIPTION is optional; the
Observer fills itself) is a `NOT SENT - <reason>` popup, the reason beside SEND and an RPT line (messaging README,
"Seeing where it stopped").

**The thread, in order** (the core files RECEIPT; the rest is the battery's):

1. `wilco` - `ETA m:ss` (or `AT MY COMMAND`, `TOT hhmm`) - the mission -
   `1 RD HE` or `4 GUNS x 3 HE` - the method (`INTERVAL 20 S`, `3 VOLLEYS`,
   `CONTINUOUS 5 MIN`) - the shape (`AREA 150 M`, `LINEAR 400 M ATT 090`,
   `CREEPING 300 M DIR 045`) - `TOF n S` - `DANGER CLOSE` when ticked -
   the target description. ACCEPTED. Said at the filing, inside the core's
   receipt hold, so the battery's first answer is the one `ROGER, WILCO - ETA
   ...` message, as every asset's is.
2. `inprogress` when the first salvo is ordered (`fireMission`). IN_PROGRESS.
3. `shot` with `TOF n` as each volley leaves, `splash` `SPLASH_LEAD` (5) s
   before it lands (`threadVolley`, called by `fireVirtual`), each with a
   short sound on the caller's machine (2026-11-02, below). A mission of
   several volleys numbers them - `VOLLEY 2 OF 3 - TOF 32`, `VOLLEY 2 OF 3`
   (2026-11-05): the volleys follow on the guns' rhythm, so a volley's SHOT
   can be filed before the one before has splashed.
4. As the volley's last round lands, a `prompt` (doc 5.4; `Text` what it
   asks, `Answers` the reply ids offered): an adjusting round - `ADJUST?`
   (adjust, ffe, close); fire for effect - `ROUNDS COMPLETE - 12 HE, 6 SMOKE
   LEFT - REQUEST BDA` (bda, record, repeat, close); unobserved - `ROUNDS
   COMPLETE - <left> - END OF MISSION?` (close, record, repeat). What is left
   (`stockWords`, 2026-11-02) is every round type the battery still holds, UNL
   for unlimited, `NO ROUNDS LEFT` for none.
5. The observer's call (`threadReply`, the core's `reply` hook):

| Reply | The battery |
|---|---|
| `adjust` ADD / DROP / LEFT / RIGHT n, and the other axis when the card gives it (2026-11-02: "RIGHT 50, ADD 100" in one message) | moves the point n m along / across the observer-target line - the observer the card names where he is now (else where he was, else the issuer; no position at all: the gun-target line) - and fires the next adjusting round there (`adjustNext`). Out of range or danger close: asks `ADJUST? - <why>` instead |
| `ffe` (ROUNDS optional) | fire for effect on the point, ROUNDS per gun when given |
| `repeat` | the last salvo again |
| `confirm` | AT MY COMMAND: the first salvo |
| `checkfire` | rounds not yet fired are not fired (those in the air land), its SHOT / SPLASH / prompt for them are not filed; it holds - `CHECK FIRE - HOLDING` (adjust, ffe, repeat, record, close) |
| `bda` | `12 HE, 6 SMOKE LEFT - END OF MISSION?` (close, record, repeat) |
| `record` (2026-11-02) | RECORD AS TARGET (`record`): the mission's point - where the last correction put it - becomes a named target with a map marker (below); `RECORDED AS TARGET AB1001`, and the question it had asked again, less RECORD. The same point again: the same name |
| `close` (EOM), `abort`, `rtb` | stands down (`threadEnd`, `finish`): CLOSED `END OF MISSION` |

   A call that fires while rounds are in the air waits for them to land, at
   most 120 s; still in the air then (a continuous fire), it is dropped and
   the battery says `ROUNDS IN THE AIR - CALL AGAIN AFTER SPLASH` (checkfire,
   close - a prompt with no D9 waits, the mission still firing; 2026-11-05).
   CHECK FIRE is taken at once.
6. **D9** (user, 2026-11-01): a prompt unanswered for 3 min is asked again,
   `NO RESPONSE - HOLDING`; at 5 min the battery stands down itself, CLOSED
   `NO RESPONSE - END OF MISSION`. A battery laid AT MY COMMAND that never
   fired takes no cooldown.

The acceptance run (doc section 11): CFF adjust -> ROGER, WILCO, ON TASK,
SHOT, SPLASH, ADJUST? -> ADD 50 -> SHOT, SPLASH, ADJUST? -> FFE -> SHOT,
SPLASH, ROUNDS COMPLETE - REQUEST BDA -> EOM: one thread, in order.

**Who may call it** is the support core's (D6): the issuer, the card's
Observer, anyone on the FIRES net, of the battery's side (this addon's `side`
hook), through the tasking gate. **The board** still works as before: its
ADJUST pad drives the same hold, and a thread mission's rounds are published
for the round log like a board adjust mission's (the issuer is `holdBy`).
Not built here: the reader drawing a prompt's `Answers` as quick replies, and
the thread map pin (doc 6.2, 6.3).

**The battery's stock in the TO picker** (2026-11-02): the support core's
`mailboxes` puts a battery's rounds left on its row (`ARTY - IDLE - 12 HE, 6
SMOKE, 24 ILLUM - ETA 1:20`, the first three types).

#### Recorded targets (2026-11-02)

User, 2026-11-02 (RECORD AS TARGET, from the Tun Firesupport review). Built,
not seen in game.

- **The name** is a doctrinal target number: the battery's two letters and
  four figures from 1001 - `TH1001`, `TH1002` ... (`record`). The letters are
  the module's **Target Prefix** when it gives two; blank, the callsign's
  first two letters (THUNDER: `TH`), stepped on past any another battery
  already has (`TI`, `TJ` ...) so no two batteries share a name
  (`targetPrefix`). A callsign short of letters is made up with A.
- **The marker**, made on the server: the name on the point, `mil_destroy`,
  red. It is global so the server's card reader finds it - support `gridPos`
  reads a marker name before a grid - and hidden on every machine of another
  side (`targetLocal`, remoteExec with JIP, taken only from the server). It
  stays to the end of the mission.
- **Firing on it again**: type the name in CFF GRID's TARGET - GRID or CFF
  SHIFT's KNOWN POINT (or pick it from the marker list). Type it in capitals,
  as the marker shows it.
- **Pre-planned targets**: an Eden marker whose name (its Variable Name) is
  the battery's two letters and four figures - `TH1001` - is a target
  before the mission starts: any card fires on it by name, the battery
  numbers past it (a number that is already a marker is skipped), and the
  RPT lists them at start (`Artillery 'THUNDER': targets TH, pre-planned
  TH1001 TH1002`). Give the module a Target Prefix to know the letters in
  advance.

#### The second artillery build (2026-11-02)

User, 2026-11-02 (the rest of the Tun Firesupport review). Built, not seen in
game.

- **The composer's preview before SEND** (`cardPreview`, the support core's
  `cardPreview` hook; tacpad `composeFire`). While a CFF GRID, CFF POLAR or
  CFF SHIFT is written to a battery's box, the line beside SEND reads what the
  battery would answer, and the footprint is on the player's map (local
  markers - the game map and the tablet's map alike):
  - `IN RANGE 8.4 KM (MIN 2 KM, MAX 24 KM) - TOF 32 S - AREA 150 M`, and
    `DANGER CLOSE - FRIENDLY 420 M` while a friendly is inside the card's
    danger-close distance (600 m) and the card ticks it; or, in the accent,
    `CANTCO - <the server's word>`: `NO TARGET LOCATION`, `TASKED`, `COOLDOWN
    n S`, `OUT OF RANGE 14.2/12 KM`, `TOO CLOSE`, `NO STORES SMOKE`, `SHEAF NOT
    AVAILABLE`, `DANGER CLOSE NOT ACKNOWLEDGED - FRIENDLY 420 M`,
    `CONTINUOUS FIRE NOT AVAILABLE`, `NO TOT`, `CANNOT MAKE TOT`.
  - The footprint: the target with the battery's call sign and its TOF; a
    point's scatter - the first salvo's aiming error and the dispersion, an
    ellipse along the line of fire; an area's circle; a linear target's line;
    a creeping walk from the point to `WALK END`; the danger-close ring while
    a friendly is in it. Orange when it would fire, red when not.
  - Worked out on the player's machine from what the server published on the
    module, through the server's own reads (`reach`, `threadShape`, `inRange`,
    support `dangerClose`, `threadMethod`, `ballistics`, `threadTot`) - on a
    change of the card, never per frame. The server still reads the card when
    it is filed and still answers CANTCO. The range is the battery's: one
    muzzle velocity serves every round type, so the minimum and maximum are
    the same for each.
- **Airburst** (Engagement F). The fire for effect's HE bursts a random 7 to
  12 m over the ground on its own charge (`virtualRound`: put at that height
  on the frame it would pass it, then `triggerAmmo`). An adjusting round bursts
  on impact, as an FDC adjusts with a quick fuze; a flare or a submunition
  round keeps its own fuze. Only for a card asking for it.
- **Aiming error, removed by adjusting** (the module's new *Aiming Error (m)*,
  100 by default). A mission's first salvo lands off the point as one - an
  offset drawn once per salvo inside an ellipse of that size along the line of
  fire, 0.4 of it across (`aimError`, `scatter`). Each ADJUST halves it, and
  so does the fire for effect after them (a REPEAT does not); under the
  module's Dispersion it is gone and only the dispersion is left. Per mission:
  a new mission starts with the whole error. CANNOT OBSERVE fires with it.
- **Elliptical dispersion.** A round's own scatter round its aim point is an
  ellipse along the gun-target line: the module's *Dispersion* in range, 0.4
  of it in deflection (`scatter`) - every round, every shape.
- **Magazine classes.** A Virtual Artillery round class (HE, Smoke,
  Illumination, Cluster, Guided) may be a magazine class: the battery fires
  the magazine's `ammo`, and the RPT says so at start (`Artillery 'THUNDER': HE
  magazine '32Rnd_155mm_Mo_shells' fires 'Sh_155mm_AMOS'`). A class that is
  neither is not carried, with an RPT warning. The card's Engagement line is
  ticks, not free text, so there is nothing to resolve on it.
- **SHOT / SPLASH cues.** As the battery files SHOT and SPLASH (5 s before
  impact) in its thread, the issuer and the card's observer hear a short
  sound on their own machine (`cue` on the server, `cueLocal` by remoteExec,
  taken only from the server): vanilla Arma 3 `Beep_Target` for SHOT,
  `FD_Start_F` for SPLASH. The mod has no radio cue of its own; Tun
  Firesupport's voice clips are not used (the brief was ideas, not assets -
  their APL-SA would allow them with credit).

**Credits.** The fire control is modelled on **Simplex Support Services'**
artillery (Cory "Sceptre" Armstrong, GPL-2): the queued mission with its
response delay, the readiness and ammunition checks, the per-gun firing
rhythm with SHOT at the first round and SPLASH 5 s before it lands, the
loops with no pause between them, the cooldown paid once at the end with a
share per round, the sheaf types, the arc solved through the target's
height, the abort that lets rounds in the air land. Read for its method on
2026-10-20 and again on 2026-11-05; no code of it is used, and the battery
here is virtual and called only by message. **Tun Firesupport by Tuntematon
/ Armafinland** (APL-SA, as this mod). Their own ideas, taken from their code: target shape (linear and
creeping barrages), method of fire with a jitter on the gap, points recorded
for re-fire as map markers, the stock in the replies, a TOT to the second, a
module that takes the gun's magazine classes, a splash cue, and the range
check before a mission is fired. The jitter's formula is theirs (`fnc_fire.sqf`:
plus or minus a tenth of the gap and 1.1 s over it, never under 0.3 of it).
Prompted by the review of it but not in it: the airburst fuze, the aiming
error taken down by adjusting, the elliptical dispersion, and the composer's
footprint on the map. No code or asset of it is used.

#### Cruise missiles and loitering munitions by message (2026-11-01)

The @ mention and the TO picker give a launcher's box the `callforfire` card
(support `MAILBOX_TYPES`); since the TAC//SUPPORT app went, that card is the
only way a player calls them. `srvThread` hands their card to `threadStrike`;
the launch is the board's own (`launchCruise`, `launchLoiter`) on the mission
it opens. Built, not seen in game.

| Card | Cruise missiles | Loitering munitions |
|---|---|---|
| Warno 1 B FFE, C SUPPRESS, none ticked | one launch | one launch |
| Warno 1 D IMMEDIATE SUPPRESSION | at the least response time | the same (it has none) |
| Warno 1 A ADJUST | CANTCO `ADJUST NOT AVAILABLE` (with Control D CANNOT OBSERVE: fired for effect) | the same |
| Warno 3A / 3B / 3C | the target, as for a battery; none: `NO TARGET LOCATION` | the point it hunts round, at the board's least SEARCH RADIUS (100 m) |
| Engagement number | how many missiles, up to the salvo size and what is left; none: one | how many munitions, up to the launch size and what is left; none: one |
| Engagement SMOKE, ILLUM | `NO STORES SMOKE` / `NO STORES ILLUM`; any other shell is the warhead it carries | the same |
| Danger Close | as for a battery (600 m) | the same |
| Control B AT MY COMMAND | laid, `READY - AT MY COMMAND` (confirm, close); launches on `confirm` | the same |
| Control C + TOT | the first missile lands at the TOT minute (`threadTot`, the battery's reading): `NO TOT` / `CANNOT MAKE TOT` | CANTCO `TOT NOT AVAILABLE` - it hunts |
| Control A, D, E, F | launch when ready | the same |

Busy, rearming, spent, out of reach: the reach card's word (`TASKED`,
`COOLDOWN n S`, `NO STORES`, `OUT OF RANGE n/max KM`, `TOO CLOSE n/min KM`).

**The thread**: ROGER (the core); WILCO `ETA m:ss - FFE - 2 MISSILES - TOF n
S` (a munition: `2 MUNITIONS - TRANSIT n S`, the ETA its time on station;
none when the airframe gives no speed), `DANGER CLOSE` and the description as
for a battery; ON TASK at the launch order; `shot` as the first missile or
munition of a launch leaves (`TOF n`, a munition `TRANSIT n S`); `splash` 5 s
before the first missile lands (a munition has none: when it strikes is not
known); once the last one is gone - on the target, shot down, out of time -
the launcher holds (status `holding`, busy, the target marked) and asks
`ROUNDS COMPLETE - REQUEST BDA` (bda, repeat, close; unobserved `ROUNDS
COMPLETE - END OF MISSION?`). It hears `stop` (CLOSE, ABORT, RTB), `repeat`
(the launch again at its quickest, up to what is left - nothing left closes
it `NO STORES - END OF MISSION`), `confirm` and `bda` (`END OF MISSION?`);
`adjust`, `ffe` and `checkfire` are artillery's and do nothing here. A call
that launches while missiles or munitions are out waits for them, as for a
battery. D9 as for a battery: 3 min `NO RESPONSE - HOLDING`, 5 min CLOSED
`NO RESPONSE - END OF MISSION`. CLOSE while they are out: a missile flies on
(it cannot be recalled), a munition sets itself off where it is.

**Cooldown** is Simplex's: the module's cooldown after the mission ends, plus
its cooldown per round (artillery) or per missile (cruise) for every one the
mission fired.

## How each one fires

- **Virtual Artillery.** The module is the battery, on or off the map. The
  time of flight and descent angle come from a vacuum arc (Arma flies shells
  without drag, so this is the arc a gun's round flies) from the battery to
  the target. High angle fires the lowest of six charges (shares of the
  *Muzzle Velocity*) that reaches with the tube at or under 80 degrees, as a
  real battery would; low angle fires the top charge flat. The range is the
  tighter of the module's *Minimum / Maximum Range* and what the charges
  reach.
  - **The fire mission.** After a random *Response Time* plus the DELAY asked
    for, every gun fires its rounds one *Reload* plus the INTERVAL apart, the
    guns of a salvo a moment apart. REPEAT fires more volleys, Simplex's
    loops (2026-11-05): each gun's first round of the next volley comes one
    reload plus the interval after its last of the volley before - no pause,
    no wait for the splash; the *Cooldown* is paid once, after the mission's
    last round. Fewer rounds left than asked fires what is left. The gap
    between one gun's rounds jitters (2026-11-02, Tun Firesupport's formula):
    plus or minus a tenth of it and 1.1 s over it, so a short gap jitters
    most. The arc is solved through the target's height over the battery
    (2026-11-05, as Simplex's solver does): the time of flight, the descent
    and every ETA say so when the guns stand above or below the target.
  - **The sheaf.** CONVERGED puts each round at random inside the SHEAF radius;
    PARALLEL lines the guns up across the line of fire over the sheaf's width;
    BOX spreads the rounds over the whole square; CREEPING gives each gun a
    lane and walks its rounds from the near edge to the far edge along the
    line of fire. Each round then lands within the module's *Dispersion* of
    its aim point - an ellipse along the line of fire, 0.4 of it across
    (2026-11-02) - and a salvo's aim carries what is left of the *Aiming
    Error*. A call for fire's LINEAR target (2026-11-02) spreads the
    guns along its own line at any attitude, each over its stretch; its
    CREEPING walk steps every round of the mission further from the point.
  - **Coordinated.** With COORDINATE on, every other battery of the side whose
    position is within the tasked battery's *Coordination Distance*, that has
    a Coordination Distance of its own, is free, carries the same shell class
    and reaches the target, fires the same mission with all its guns. Each
    calls its own SHOT and SPLASH and cools down on its own.
  - **The round.** Each round comes off the stock as it is fired and is
    spawned 8 seconds before impact on its descent, at a real shell's terminal
    speed. A low-angle descent masked by terrain comes in high. Submunition
    rounds (smoke, cluster, guided, mines, the 230 mm rockets) are opened by
    script at their class's `triggerDistance`; illumination is the flare class
    released over the target.
- **Artillery Battery (retired).** Hidden from Eden and Zeus; a placed one
  still loads and runs as a Virtual Artillery battery with that module's
  defaults - see below.
- **Cruise Missiles.** After a random *Response Time* plus the DELAY asked
  for, the missile ammo (default `ammo_Missile_Cruise_01`, the Mk41 VLS round)
  is created at the module, boosts straight up, then is steered every 0.05 s
  along route points every 1.5 km to the target, terrain-following at the
  *Cruise Altitude*, pops up inside 1.8 km and dives inside 700 m. It is a
  MissileCore in the world, so active protection sees it, and it is reported
  to the air defence intercept (`adsite`) once its time to impact is under
  200 s so AD units engage it. Its own `timeToLive` is its range; a target
  closer than 1 km is refused.
- **Loitering Munitions.** Each munition is created in the air at the module,
  crewed on the players' side, and flown to the point. On station it orbits,
  looks every 3 s for the best visible target its *Strike Rules* allow (enemy
  side only; dearest vehicle, or the man in the biggest group), then dives
  under script control and sets off its warhead. Out of loiter time it
  self-destructs. A target further than the airframe flies in 900 s at its
  transit speed is refused. The Switchblade's warhead is the mod's own; the
  Darter fallback carries `M_Titan_AP`.

## Picking shell classes

The **Virtual Artillery** module takes a **CfgAmmo** class for each round type
(HE, Smoke, Illumination, Cluster, Guided) - or, since 2026-11-02, the gun's
**magazine** class, which fires the magazine's `ammo`. The shell class decides what lands;
the module's *Muzzle Velocity* decides how long it flies. Every class below
was checked against the vanilla config.

| Round | 155 mm (M4 Scorcher / 2S9 Sochor) | 82 mm (Mk6 mortar) | 230 mm (M5 Sandstorm) |
|---|---|---|---|
| HE | `Sh_155mm_AMOS` | `Sh_82mm_AMOS` | `R_230mm_HE` |
| Smoke | `Smoke_120mm_AMOS_White` | `Smoke_82mm_AMOS_White` | - |
| Illumination | `Flare_82mm_AMOS_White` | `Flare_82mm_AMOS_White` | - |
| Cluster | `Cluster_155mm_AMOS` | - | `R_230mm_Cluster` |
| Guided (seeks armour) | `Sh_155mm_AMOS_guided` | `Sh_82mm_AMOS_guided` | - |
| Guided (laser) | `Sh_155mm_AMOS_LG` | `Sh_82mm_AMOS_LG` | - |
| Mines (in the Cluster or Guided slot) | `Mine_155mm_AMOS_range`, `AT_Mine_155mm_AMOS_range` | - | - |

- **Illumination** is any flare class; the module default
  `F_40mm_White_Illumination` is a long-burning white flare.
  `Flare_82mm_AMOS_White` is the mortar's own, `Flare_82mm_AMOS_White_Illumination`
  a brighter, longer one.
- **Muzzle Velocity** to match the gun: 810 for 155 mm (the magazines'
  `initSpeed`), 200 for the 82 mm mortar, 850 for the 230 mm rockets.
- **Modded shells** (CUP, RHS, ...) are their own CfgAmmo classes - the `ammo`
  of the gun's magazine in the config viewer.

### Retired Artillery Battery: Ammunition Per Gun

Missions that placed **JMSB - Artillery Battery** keep it: it runs as a
virtual battery and **no gun is loaded, ordered or fired**. Its battery stands
at the centre of the synced artillery (the module when none is synced), has as
many guns as are synced (4 when none), and its *Ammunition Per Gun* field takes
`class:rounds` pairs separated by commas - **magazine classes** (as before) or
CfgAmmo shell classes. Each pair is that many rounds **per gun**, multiplied
by the gun count; a magazine gives its `ammo` as the shell and its `initSpeed`
(times the synced guns' top charge) as the muzzle velocity. Blank reads the
rounds already in the synced guns' artillery magazines; blank with no guns
carries the Virtual Artillery defaults (HE 96, smoke 24, illumination 12).
Its range is whatever that muzzle velocity's charges reach (no module
minimum or maximum); every other value is the Virtual Artillery default.

| Gun | Ammunition Per Gun |
|---|---|
| M4 Scorcher | `32Rnd_155mm_Mo_shells:24, 6Rnd_155mm_Mo_smoke:6, 2Rnd_155mm_Mo_Cluster:2, 4Rnd_155mm_Mo_guided:4, 4Rnd_155mm_Mo_LG:4` |
| 2S9 Sochor | `32Rnd_155mm_Mo_shells_O:24, 6Rnd_155mm_Mo_smoke_O:6, 2Rnd_155mm_Mo_Cluster_O:2, 4Rnd_155mm_Mo_guided_O:4, 4Rnd_155mm_Mo_LG_O:4` |
| Mk6 mortar | `8Rnd_82mm_Mo_shells:24, 8Rnd_82mm_Mo_Smoke_white:8, 8Rnd_82mm_Mo_Flare_white:8` |
| M5 Sandstorm | `12Rnd_230mm_rockets:12, 12Rnd_230mm_rockets_cluster:6` |

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_support`

## Ships

4 unit classes, 84 functions.

## Eden modules

### JMSB - Artillery Battery (retired)

`jmfsb_moduleFiresArtillery`, category jmfsb_modules

RETIRED - place JMSB - Virtual Artillery instead. Kept so missions that placed it still load.<br>Runs as a virtual battery: no gun aims or fires. Synced artillery, if any, gives only the battery's position, its gun count and (with Ammunition Per Gun blank) the rounds its magazines carry.<br>Callsign - What the support page calls it Ammunition Per Gun - class:rounds per gun; blank reads the synced guns Cooldown (sec) - Time after a mission before it can be tasked again

<details><summary>3 attributes</summary>

- `ammunition`
- `callsign`
- `cooldown`

</details>

### JMSB - Virtual Artillery

`jmfsb_moduleFiresVirtual`, category jmfsb_modules

THE artillery module. A battery on the support page, on or off the map: no guns exist, the module IS the battery's position. Each round is the shell class itself, spawned high over the target on its descending arc after the time of flight from here, so it is heard coming in. Counter-battery has nothing to find.<br>A Simplex fire mission: ordnance, rounds per gun, sheaf type and size, guns, interval, delay, repeat volleys, and coordination with nearby batteries. The target is marked on the map until the mission ends. Rounds are counted per type and run out.<br>Callsign - What the support page calls it Guns - Tubes in the battery HE, Smoke, Illumination, Cluster, Guided - Shell or magazine class and rounds of each; 0 none, -1 unlimited Minimum / Maximum Range (m) - From this module Dispersion (m) - Each round's own error, an ellipse along the line of fire Aiming Error (m) - A mission's first salvo off the point; each adjust halves it Muzzle Velocity (m/s) - Top charge; time-of-flight model Trajectory - High or low angle Reload (sec) - Between one gun's rounds Cooldown (sec) - After the mission, and between repeats Cooldown Per Round (sec) - Added per round fired Response Time Min / Max (sec) - Random wait before the first round Sheaf Types - Which the support page offers Max Rounds Per Gun, Max Interval, Max Delay, Max Repeats - Stepper limits; 0 hides a stepper Coordination Distance (m) - Batteries this close may fire together; 0 never Max Sheaf Length (m) - Longest sheaf, area radius, linear target or creeping walk Max Continuous Fire (min) - Longest CONTINUOUS FOR n MIN; 0 none Target Prefix - Two letters for recorded targets (AB1001); blank from the callsign

<details><summary>32 attributes</summary>

- `aimError`
- `callsign`
- `clusterClass`
- `clusterRounds`
- `cooldown`
- `coordination`
- `dispersion`
- `guidedClass`
- `guidedRounds`
- `guns`
- `heClass`
- `heRounds`
- `illumClass`
- `illumRounds`
- `maxContinuous`
- `maxDelay`
- `maxInterval`
- `maxRange`
- `maxRepeat`
- `maxRounds`
- `minRange`
- `muzzleVelocity`
- `reload`
- `responseMax`
- `responseMin`
- `roundCooldown`
- `sheafMax`
- `sheafTypes`
- `smokeClass`
- `smokeRounds`
- `targetPrefix`
- `trajectory`

</details>

### JMSB - Cruise Missiles

`jmfsb_moduleFiresCruise`, category jmfsb_modules

A cruise missile launcher on the support page, at this module's position - a ship or ground site, off the map edge is fine.<br>Each missile is a real projectile that flies the whole route: up off the rail, terrain-following at cruise altitude to the target, then a terminal dive. Air defence and active protection can shoot it down. The target is marked on the map until the salvo is gone.<br>Callsign - What the support page calls it Missiles - How many for the whole mission Missile Class - The CfgAmmo flown; blank for ammo_Missile_Cruise_01 Warhead - CfgAmmo set off at the target; blank for the missile's own Salvo Size - Most per request Cruise Speed (m/s) / Cruise Altitude (m) - The route Cooldown (sec) - After a salvo Cooldown Per Missile (sec) - Added per missile launched Response Time Min / Max (sec) - Random wait before the first launch Max Delay (sec) - Top of the DELAY stepper; 0 hides it

<details><summary>12 attributes</summary>

- `altitude`
- `callsign`
- `cooldown`
- `maxDelay`
- `missileClass`
- `missileCooldown`
- `missiles`
- `responseMax`
- `responseMin`
- `salvo`
- `speed`
- `warhead`

</details>

### JMSB - Loitering Munitions

`jmfsb_moduleFiresLoiter`, category jmfsb_modules

A loitering munition launch site on the support page, at this module's position.<br>Each munition is a real air vehicle: it flies to the target area, orbits it for the loiter time hunting, dives on the best target its strike rules allow, and self-destructs when time runs out. It can be shot down. The hunt area is marked on the map until the last munition is gone; a target further than the munition can fly in its transit time is refused.<br>Callsign - What the support page calls it Munition Class - Blank for the Switchblade 600 (Switchblade mod) or the side's Darter Munitions - How many for the whole mission Launch Size - Most per request Loiter Time (sec) - Time on station Strike Rules - Vehicles, infantry or both, enemy side only Loiter Altitude (m) - Height above the ground Warhead - CfgAmmo set off on the target; blank for the munition's own Cooldown (sec) - After the last munition is gone

<details><summary>9 attributes</summary>

- `altitude`
- `callsign`
- `cooldown`
- `launchSize`
- `loiterTime`
- `munitionClass`
- `munitions`
- `strikeRules`
- `warhead`

</details>

## Functions

<details><summary>84</summary>

- `jmfsb_support_fires_fnc_abort`
- `jmfsb_support_fires_fnc_adjustFor`
- `jmfsb_support_fires_fnc_adjustHold`
- `jmfsb_support_fires_fnc_adjustNext`
- `jmfsb_support_fires_fnc_aimError`
- `jmfsb_support_fires_fnc_aimPoint`
- `jmfsb_support_fires_fnc_ammoKind`
- `jmfsb_support_fires_fnc_assetAvailable`
- `jmfsb_support_fires_fnc_assets`
- `jmfsb_support_fires_fnc_available`
- `jmfsb_support_fires_fnc_ballistics`
- `jmfsb_support_fires_fnc_cardPreview`
- `jmfsb_support_fires_fnc_check`
- `jmfsb_support_fires_fnc_cue`
- `jmfsb_support_fires_fnc_cueLocal`
- `jmfsb_support_fires_fnc_detonate`
- `jmfsb_support_fires_fnc_entityRow`
- `jmfsb_support_fires_fnc_finish`
- `jmfsb_support_fires_fnc_fireMission`
- `jmfsb_support_fires_fnc_fireVirtual`
- `jmfsb_support_fires_fnc_flyCruise`
- `jmfsb_support_fires_fnc_fmtDist`
- `jmfsb_support_fires_fnc_gunRanges`
- `jmfsb_support_fires_fnc_impactSet`
- `jmfsb_support_fires_fnc_inRange`
- `jmfsb_support_fires_fnc_launchCruise`
- `jmfsb_support_fires_fnc_launchLoiter`
- `jmfsb_support_fires_fnc_layHeight`
- `jmfsb_support_fires_fnc_logicOf`
- `jmfsb_support_fires_fnc_loiterOne`
- `jmfsb_support_fires_fnc_loiterTick`
- `jmfsb_support_fires_fnc_mark`
- `jmfsb_support_fires_fnc_markLocal`
- `jmfsb_support_fires_fnc_moduleArtillery`
- `jmfsb_support_fires_fnc_moduleCruise`
- `jmfsb_support_fires_fnc_moduleLoiter`
- `jmfsb_support_fires_fnc_moduleVirtual`
- `jmfsb_support_fires_fnc_openMission`
- `jmfsb_support_fires_fnc_ordnance`
- `jmfsb_support_fires_fnc_overlay`
- `jmfsb_support_fires_fnc_partners`
- `jmfsb_support_fires_fnc_pickTarget`
- `jmfsb_support_fires_fnc_preview`
- `jmfsb_support_fires_fnc_reach`
- `jmfsb_support_fires_fnc_readOpts`
- `jmfsb_support_fires_fnc_record`
- `jmfsb_support_fires_fnc_register`
- `jmfsb_support_fires_fnc_request`
- `jmfsb_support_fires_fnc_requester`
- `jmfsb_support_fires_fnc_say`
- `jmfsb_support_fires_fnc_sayLater`
- `jmfsb_support_fires_fnc_sayLocal`
- `jmfsb_support_fires_fnc_scatter`
- `jmfsb_support_fires_fnc_setupBattery`
- `jmfsb_support_fires_fnc_side`
- `jmfsb_support_fires_fnc_sitrep`
- `jmfsb_support_fires_fnc_sortieDone`
- `jmfsb_support_fires_fnc_srvThread`
- `jmfsb_support_fires_fnc_status`
- `jmfsb_support_fires_fnc_stockFromTable`
- `jmfsb_support_fires_fnc_stockWords`
- `jmfsb_support_fires_fnc_targetLocal`
- `jmfsb_support_fires_fnc_targetPrefix`
- `jmfsb_support_fires_fnc_task`
- `jmfsb_support_fires_fnc_taskDecls`
- `jmfsb_support_fires_fnc_tasks`
- `jmfsb_support_fires_fnc_threadCard`
- `jmfsb_support_fires_fnc_threadEnd`
- `jmfsb_support_fires_fnc_threadFire`
- `jmfsb_support_fires_fnc_threadLaunch`
- `jmfsb_support_fires_fnc_threadMethod`
- `jmfsb_support_fires_fnc_threadPrompt`
- `jmfsb_support_fires_fnc_threadReply`
- `jmfsb_support_fires_fnc_threadRetask`
- `jmfsb_support_fires_fnc_threadShape`
- `jmfsb_support_fires_fnc_threadStrike`
- `jmfsb_support_fires_fnc_threadTot`
- `jmfsb_support_fires_fnc_threadVolley`
- `jmfsb_support_fires_fnc_threat`
- `jmfsb_support_fires_fnc_typeList`
- `jmfsb_support_fires_fnc_unmark`
- `jmfsb_support_fires_fnc_unmarkLocal`
- `jmfsb_support_fires_fnc_virtualRound`
- `jmfsb_support_fires_fnc_virtualShot`

</details>
