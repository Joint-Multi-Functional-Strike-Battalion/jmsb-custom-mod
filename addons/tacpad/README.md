# Tacpad

`jmfsb_tacpad`

The map screen is the shell. Panels are controls groups drawn on the vanilla map
display, so the map stays a map — the player keeps panning, clicking and marking
it, and a panel is something laid on top rather than something that replaced it.

Every panel is dragged by its header, the way ACE's map tools are. Release and
the position is saved as **safe-zone fractions**, not pixels, so the same profile
still makes sense on a different resolution. Right-click a header to put that
panel back where the design put it.

## Input

**Controls on the map display take input.** BCE declares a whole toolbar into
`RscDisplayMainMap` and drives it with `onButtonClick`; this does the same thing
at runtime. Anything pressable is an `RscButton` — the `hit` class — laid over
the text, carrying its own `ButtonClick` handler. That is the whole mechanism.

It is written down because the opposite was believed for six builds. The theory
was that display 12 gives every click to the map control at IDC 51, so the suite
registered *rectangles* and hit-tested them from a dispatcher hung off the map.
That could not work: the transparent button over each row consumed the click —
which is what a button is — so neither the map nor the display ever saw the
event, and the dispatcher never ran. **Nothing in the suite could be pressed.**
The narrower thing that is true, and the reason the hit class exists at all, is
that `RscText` and `RscStructuredText` raise no `ButtonClick`.

**A structured text label takes the press away from the button under it.** That
is the other half of the story and the one that made the suite feel broken: a
structured text control receives mouse input — it has to, it can carry links —
and it raises no `ButtonClick`, so wherever a label covered a cell the cell
answered only in the margins around it. The settings strip, whose label runs from
the gear to the far edge, answered *only on the gear*. `drawHit` now hands the
press on: every label drawn into the same group this frame and lying inside the
button's rectangle gets a press handler that fires that button's own handler.
Nothing double-fires — one control receives a press, and the first hit to cover a
label owns it.

Dragging is the one thing that needs more, because a drag outruns the header it
started on: `dragStart` creates a full-screen transparent **catcher** for the
duration of the drag and deletes it on release.

**A live app must know it is still the app on screen.** Three screens refresh by
reopening themselves on a timer, and they decided whether to keep going by asking
whether an app group existed — which is true of *any* app, including the one that
just replaced them. So opening SETTINGS after HACK left the hack's loop running:
it tore the settings screen down and rebuilt its own every second, under the
cursor, and **a control deleted between the press and the release never raises a
click**. That is the whole of "the window would not click and would not close",
and it applied to whichever screen was opened second. `openApp` writes down which
app is open and every refresh loop compares that against its own id.

**A reopen is refused once the window that queued it is gone.** Every redraw
reopens the app — a live app reopens itself on a timer, a press inside the app
queues a reopen for next frame — and the only thing that says a reopen is still
wanted is the window it came from still being the open one. CLOSE fires on the
press, so "press a row, then close the window" had its reopen land *after* the
close and the window came straight back: the same stuck window wearing the coat
of "I closed it and it opened again". `openApp` refuses any reopen whose app is
no longer the one on screen; only a panel or a tile is trusted to open one.

**A draw that throws must not take the layer with it.** A handler dying halfway —
bad data, a race, a config gone missing — used to abort `openApp` before the
panels hid or the escape hatch drew, leaving `appCurrent` set to a screen nobody
could see and no way out of it. It is caught and logged, and the bookkeeping
carries on: a broken window still has to close.

**A page closes the way every other window in the game closes: ESC, or a click
on the map.** Both are hung on the map display once, and both run the same
teardown as the frame's own CLOSE — `appClose`. There is no panic button: one
was built and removed, because a page that always closes needs no rescuing.
`appClose` also sweeps the display for groups the suite owns but no longer
tracks, which is what let a page get stuck in the first place — an orphan is
deleted by nothing and replaced by nothing.

**A drag handle cannot be a button.** It was one, and that is why no panel could
ever be moved: a button raises `ButtonDown` and `ButtonClick` and does **not**
raise `MouseButtonDown`, so the handler hung on it was never called once. The
grab is a plain fill now — statics do raise it, and it carries the cursor
position a drag needs.

Four regions are reserved and a panel is slid clear of them on drop: the map's
own top bar (full width — the design's three zones miss it, and the tiles and the
reader were both drawn over it), the vanilla game menu (top-left), the chat
overlay (bottom-left, 8 grid cells × 2.5) and the scale and contour legend
(bottom-right). Covering the chat overlay costs a
player the only text channel they have, so it is not left to chance — though
`respectZones` turns it off for anyone who disagrees.

**Growing is checked against them too.** `place` pushes a panel clear of the
chat overlay when it is dropped, and `fit` then grew it straight back down over
the chat: the squad rail reserved sixteen rows whatever the group held, which
from its default position ended below the top of the chat zone. `fit` clamps to
the nearest reserved edge underneath the panel, and the rail is the size of the
section actually in it.

## TAC//MSG inside the tablet

In tablet mode, with a device open, TAC//MSG never opens a window over it
(user, 2026-10-20: "tac//msg needs to be inside the tablet"). `openReader`
creates the reader's root on the device dialog in the tablet's map area and
adopts it as the tablet's open app (`appHost`, id `reader`): the panels hide
under it, the device bar, notification line, tiles and net row stay round it,
**ESC**, CLOSE (`readerClose`) or a press on the map close it and leave the
tablet up, and a tile or soft key replaces it like any other app. Everything
TAC//MSG draws - the rail, the list and its filter, the thread and net views,
the composer, the template and recipient pickers, the report card, the quick
replies, the FLASH banner - is drawn into that root or onto the device, and
its edit boxes are created into the device dialog, which takes keyboard
focus. The comms app's COMPOSE, NEW, OPEN FULL on the docked reader and the
keybind all arrive here. On the vanilla map, and in tablet mode with no device
open, the reader is the dialog it always was.

`appHost` is public: any screen that draws its own group on the host can be
the open app that way (TAC//PAC does). Every way an app stops being open -
`appClose`, another app replacing it, the host going - raises
`jmfsb_tacpad_appClosed` with its id.

**A filed card reads in one column** (user, 2026-11-02: "the 2 column view in
the message history is hard to read"; built, not seen in game). The thread's
card (`readerCard`) and every card filed as a reply on the spine
(`readerReplies`) are one key/value row per filled line (`readerKvRows`,
`readerKv`): the label in the muted ink, in a column as wide as the longest
label (at most 40% of the card), the value right after it at the tile detail
size, untracked. A value too long for one line beside its label - REMARKS,
MIST - is drawn under the label across the full width. Empty optional lines
are left out; a ticked box reads as its word (`SECURITY  RED`); a grid is bold
in the accent, at the player's grid digits (`jmfsb_devices_fnc_overlayGrid`,
the engine's square without devices). The root card numbers a line whose label
carries no number of its own. A thin rule follows a filed reply card. It is
`jmfsb_tacpad_apps_fnc_kvRow`'s layout in a helper of this addon's own:
tacpad_apps requires tacpad, so the reader cannot call it. A typed reply and
the asset's question (`prompt`) read as before; the docked reader's thread
view is a list of rows and is not changed.

## Composing

**There is no compose window.** Composing is a state of the reader's right pane:
NEW and + TEMPLATE switch what the right third of the screen is showing, and the
nets, the traffic list and the thread being answered all stay on screen while the
answer is written. It was a second dialog over the top of the reader, which put
the thread behind the reply to it.

**The message is the default.** The pane opens on a box you can type into, and a
report is *inserted* from there with the TEMPLATE button — the design's
+ TEMPLATE. Sending with nothing inserted goes as the `freetext` template, so the
thread it opens is the same kind of thing as every other thread.

| | |
|---|---|
| `composeOpen` | put the pane into compose — thread, template, whether to open on the picker, addressees, answers to start with |
| `composePane` | header, addressing, the message box or the card, SEND |
| `composePicker` | the deck as cards, two up, with what each one will ask for |
| `composeCard` | the inserted template's lines, two columns, a control per field type |
| `composeHarvest` | everything typed, into the answer map — **before every redraw** |
| `composeSend` | the answers, converted and submitted |

The harvest is the load-bearing piece. The pane is thrown away and rebuilt on
every press, so without it, ticking a box halfway down a 9-line wiped the eight
lines above it — which the old compose form did on every single press.

**Support assets are addressees** (user, 2026-11-01: "make the cas units
selectable as message receivers"; `docs/DESIGN_SUPPORT_MESSAGING.md` 6.1). The
TO picker (CHANGE) has a SUPPORT group under the nets, squads and men, for a
man the Support tasking tag lets task support (`jmfsb_support_fnc_canTask`,
asked once per opening). One row per asset his side has, of every type since
2026-11-01 (CAS, ARTY, CRUISE, LOITER, TRANS, LOGI, QRF - the support
README's `MAILBOX_TYPES`): call sign, then `TYPE - state - ETA m:ss`.
The state is IDLE, TASKED, ON STATION, RTB, REARMING or LOST; a row that cannot take a
task is dim and says why (`CAS - REARMING - COOLDOWN 40 S`); the ETA is to
where his GPS says he is, none when unknown. Pressing a row addresses
`B:SUPPORT:<assetId>`, the box the server answers as the asset (support
README, "Threads"). With a support card in (`cas`, `callforfire`, `hlz`, ...),
the group comes first, narrowed to that card's types.

**@ mentions a support asset** (user, 2026-11-01: "I saw no way to message
the support units; want to use an @[unit] to enable ai support units"). The
CC line's @ list offers the same assets as the SUPPORT group, every type,
first, before the nets, squads and men - call sign, then `TYPE - state -
ETA`. Picking one, or typing its call sign in full (`@HOG,` - or `@HOG` when
nothing else on either list begins with HOG; a net, squad or man of the same
name stays a CC):

1. takes it off the CC line and puts its box on the TO line beside what is
   there - the TO line reads its call sign;
2. opens the card for its type (user: "need to have the proper template also
   for the type of unit"): CAS `cas`, artillery / cruise / loitering
   `callforfire`, transport `hlz`, logistics `resupply`, QRF `qrf`. A
   fixed-wing CAS aircraft the AI flies opens `onstation` until its row reads
   ON STATION (support README, row field 9); a helicopter, a drone and a
   player-flown aircraft open `cas`. A card the deck does not carry: the card
   being written stays and the line beside SEND says `THE DECK HAS NO QRF
   CARD - CARD KEPT`. **A card the asset takes stays** (user, 2026-11-02: "on
   station is not a fire mission its just an order to get in the air"): a
   REQUEST ON STATION being written is not swapped for the drone's `cas`
   card on @HAWK (support README, row field 10); nor a CFF POLAR or SHIFT for
   a battery's CFF GRID, nor an EXTRACTION for a transport's LIFT REQUEST
   (2026-11-02). It was - and
   went as a strike, refused DANGER CLOSE. Built, not seen in game.
3. keeps what was typed. A filled line the new card has too, of the same
   type, stays; the first text with no line on the new card (the plain
   message's sentence) moves into its empty REMARKS line; anything else is
   asked about under the CC line - `HOG TAKES THE ON STATION CARD - 2 TYPED
   FIELDS ARE NOT ON IT` with SWITCH and KEEP. The asset stays addressed
   either way.

| | |
|---|---|
| `composeMentionTyped` | the assets named in full on the CC line, and the line without them |
| `composeMention` | TO, the card, the note or the question; redraws and gives the keyboard back to the CC line |
| `composeMentionSwitch` | the card switch that keeps typed text, or says how many values it would drop |
| `composeMentionAsk` | the SWITCH / KEEP row |

The plain message's box is harvested like a card's box since 2026-11-01: it
was passed over, so the sentence never reached the answer map that a redraw
and SEND read from.

| | |
|---|---|
| `composeToSupport` | the rows, from `jmfsb_support_fnc_mailboxes` - asked when the picker opens, on its poll and by the @ list (every type), never per frame |
| `composeToSupportDraw` | the group: heading, rows, the press |
| `composeToSupportLine` | how one row reads, for the draw and the poll alike |
| `composeToSupportTick` | the poll, every 2 s while the picker is up on either host: state and ETA rewritten in place (`liveApply`); a row added or gone redraws |

SEND tells the server each picked asset's call sign first
(`jmfsb_support_fnc_mailboxFiled`), so its ROGER comes from HOG, not `CAS:0`.
Wherever the reader shows a box - the TO line (`netLabel`), the rail, a
thread's header, the FLASH banner, the list's filter - an asset's box reads
as its call sign (`jmfsb_support_fnc_boxName`). Built, not seen in game.

**A support card's verdict before SEND** (user, 2026-11-02; built, not seen in
game). While a card is written to an asset's box, the line beside SEND reads
what the asset would answer - first for a call for fire to a battery: `IN
RANGE 8.4 KM (MIN 2 KM, MAX 24 KM) - TOF 32 S`, or `CANTCO - <why>` in the
accent - and its footprint is drawn on the player's map (support_fires README,
"The second artillery build"). `composeFire` asks the support core
(`jmfsb_support_fnc_cardPreview`) on every draw of the pane and every
keystroke in a card's box, but only again when the address, the card or a
value changed; a keystroke rewrites the line in place (`retext`). A link
state, an @ note or a refused SEND still outranks it. `composeFireTick`, every
1 s while a footprint stands, takes it off the map once the composer is gone.

**Player crews are in the SUPPORT group too** (decision D8, user 2026-11-01;
built, not seen in game). A man of your side in a crew seat of a gun or an
aircraft is listed after the assets, in the picker and on the @ list, under
the type his vehicle is (ARTY, TRANS, CAS - support README, "Assets as
mailboxes"): his name, then `CAS - PLAYER - AH-64D APACHE` - no state or ETA,
nobody but him answers. Pressing or picking him addresses his own player box
(`P:<uid>`) and opens his type's card; no AI acts on that thread. Typing his
name in full after @ stays a CC to the man, as any name on both lists does.

**Quick replies under a support thread** (`docs/DESIGN_SUPPORT_MESSAGING.md`
6.2 and 7, user 2026-11-01: "per the doc i want to use the messaging system
to call ai support"; built, not seen in game). The tiles are
`readerQuickTiles`, in this order:

1. **What the asset just asked.** While the newest message on the thread is
   its `prompt` card, the prompt's Answers (reply card ids) are the row -
   ADJUST? offers ADD, DROP, LEFT, RIGHT, FFE, EOM. The prompt reads on the
   spine as its question alone, at the title size on the accent; its answer
   ids are not printed. Answers the thread takes none of fall through.
   **An answer that is a root card the asset takes in its thread** (2026-11-02,
   built, not seen in game) - `cas` on FURTHER TASKING?, `hlz` on HOLD, RTB OR
   NEXT LIFT? - is a tile that opens that card in the composer, filed into the
   thread (`taskInThread`; the line beside SEND reads `IN THREAD <id> - A NEW
   TASK FOR <CALLSIGN>`). The asset answers it there with a fresh WILCO.
2. **The support card's own row, to its sender:**

   | Thread card | Tiles |
   |---|---|
   | `cas` | CLEARED HOT, ALL ATTACK (2026-11-02: a fixed-wing flight with escorts; others answer NO ESCORTS - USE CLEARED HOT), ABORT, RTB, CLOSE |
   | `onstation` (2026-11-02) | ABORT, RTB, CLOSE |
   | `callforfire`, `cffpolar`, `cffshift` | ADD, DROP, LEFT, RIGHT, FFE, REPEAT, CHECK FIRE, EOM (the `close` card) |
   | `hlz` | CONFIRM, ALL IN, ABORT, RTB, CLOSE (ALL IN 2026-11-02: the troop load done) |
   | `extract` | CONFIRM, EXTRACT, ALL IN, ABORT, RTB, CLOSE (2026-11-02: EXTRACT calls it in from its station) |
   | `casevac`, `airdrop` | CONFIRM, ABORT, RTB, CLOSE |
   | `resupply` (2026-11-02) | ABORT, CLOSE; RECEIVED / NOT FOUND come with its prompt |
   | `qrf` (2026-11-02) | ABORT, RTB, CLOSE |
   | `jump` (2026-11-02) | ABORT, RTB, CLOSE; GO comes with the jump aircraft's hold prompt |

   (`QUICK_SUPPORT`). Every support card has its row since 2026-11-02:
   REQUEST ON STATION, RESUPPLY and QRF had none, so their sender got the
   general row and its ON TASK, which moved his own request to IN_PROGRESS.
   **The sender of a support card is never offered the asset's words** -
   ROGER, WILCO, ON TASK, CANTCO (`jmfsb_support_fnc_assetCard`; FFE stays
   the observer's) - on any row, nor is anyone in a thread an AI asset
   answers (`threadLegal`); the server refuses them there (support README,
   "A card filed into an asset's thread"). Anyone else on the thread - the
   player crew it went to - gets the rule below.
3. **Every other thread:** the one-tap replies (no fields) its card answers
   with (`replyableWith`, where the card names any), then the player's Quick
   replies setting - as before.

Only what the server would take is drawn: a card the deck lacks, one the
thread's state refuses (`allowedFrom`), or one only the issuer, the
assignee or a leader may send is not on the row. A card with no required
line is filed in one press (CLOSE with no outcome, FFE as called); one with
a required line (BDA) opens in the composer on this thread. ADD, DROP, LEFT
and RIGHT each open the distance pick in the row - 25, 50, 100, 200, 400 and
BACK in the VOICE MSG slot - and a distance files `adjust` with the
direction and the metres in that one press. A support row runs onto a
second row of tiles when it is longer than five (`READER_TILE_ROWS`).

**One rule for what a thread takes** (`threadLegal`, 2026-11-02): ACK, the
quick-reply row, + TEMPLATE, the FLASH banner's reply, the net view's composer
and the Comms app all ask it. The thread's state gives the replies (none once
it is over); in a thread an AI asset answers, its issuer is also offered the
root cards that asset takes there (`jmfsb_support_fnc_threadCards`) - + TEMPLATE
in a CAS strike thread offers CAS REQUEST, in a lift thread LIFT REQUEST,
EXTRACTION, CASEVAC and PARADROP; the asset's words are taken out as above.

**A support thread's map pin draws the request** (`docs/DESIGN_SUPPORT_MESSAGING.md`
6.3, 2026-11-01; built, not seen in game). On the tablet's map and the game
map alike - local markers, as the thread's pin and PIN TO MAP are, so nothing
here draws them: the card's TARGET / LZ / PICKUP / DZ, its IN and OUT legs,
a red danger-close ring while a friendly is inside it, and while the thread
is IN_PROGRESS the asset's overlay - a salvo in the air as a red ring,
`SPLASH m:ss` - and its route. Gone when the thread closes. The support
core's (support README, "The thread's map pin"); you see it on a thread sent
to you, or once you open it.

**A refusal is drawn beside SEND**, not only sent to the notification stack. The
stack is an `RscTitles` layer and this screen is a dialog, so a dialog is always
in front of it: the one message telling you why nothing happened was behind the
screen it was about. Since 2026-11-02 (user: "arty never replied") it reads
`NOT SENT - <REASON>` there, and messaging's `submit` also says `NOT SENT` upper
right and writes the card and the reason to the RPT - the server never sees a
send refused here.

**A support card sent to no asset** (2026-11-02). A `callforfire`, `cas`,
`onstation`, `hlz` ... sent with no asset's box (and no player crew's) on TO is
filed on the net and no AI answers it. It still goes - men on the net may
answer - and `NO ASSET ADDRESSED - CFF sent - no support asset on TO, no AI
answers it. @ the asset.` shows upper right, with an RPT line. Built, not seen
in game.

**Nothing is auto-filled.** A grid that fills itself in with where you are
standing is a grid nobody reads before sending, and a CASEVAC pick-up that is
quietly your own position is how a bird goes to the wrong field. A location field
is asked for, and there are three honest ways to answer it: **CURRENT LOC**,
**MAP MARKER** (the marker list, nearest first, off `markerGrids`), or type it.
Either button stores a real position and shows it as a grid, so the thread
anchors somewhere the map can pin and the text can still be typed over.

**"Where I am" is where the GPS says** (`jmfsb_ew_fnc_gpsHere`, when EW is
loaded) - CUR LOC on a card, CURRENT LOC on the compose pin and + GRID in a
reply all take it: the false position when the set is spoofed (it does not
know), the held fix with a warning on the rail when it is SUSPECT, and
nothing - with "NO GPS FIX" on the rail - when it is denied. Type the grid.

The one exception is FILE CASEVAC FOR *name* in the squad app, which fills the
pick-up site with that man's position — because the button names the man it is
filling it in for. It writes the template's own `anchor` field, so nothing has to
know which line that is.

A field that *names* a marker rather than holding a position — an LZ name, a DZ
mark — carries `source = "marker"` in the deck and gets the same list, taking the
marker's **name** from it. A call sign and a time still prefill: neither is a
place, both are facts the game already knows about the sender, and both sit in a
box that can be typed over.

**A grid only a map marker answers** (`markerOnly`, user 2026-11-02: "REQUEST ON
STATION should require a map marker"; built, not seen in game). The field has
the MARKER cell alone - no CUR LOC - and reads MARKER in its meta. Picking a
marker stores its position; typing over it is text, and messaging's `validate`
refuses text or nothing with `PICK A MAP MARKER FOR THE AREA` (the line's
label). SEND frames the field in the accent while it holds typing. REQUEST ON
STATION's AREA is the one such field in the deck.

**A grid picked from the marker list keeps the marker's name** (user,
2026-11-05: "if a marker was used keep the name of the marker in the message
along with the grid"). The position stays the field's value; the name goes
into the payload beside it as `<field key>#marker` (`MARKER_NAME_SUFFIX`,
`composeSend`), and the message text, the subject, the reader's rows and a
card forwarded to a net print `041117 (LZ RAVEN)`. CUR LOC or typing over the
grid drops the name (`composeHarvest`).

**A choice filled at runtime** (`choicesFrom`, user 2026-11-02: "we have pre
made crates so the requested items should be a drop down of them"; built, not
seen in game). A choice whose deck entry names a source (`CHOICE_SOURCES`:
`logiCatalog` - `jmfsb_support_logistics_fnc_catalogNames`) is asked for its
picks on every draw (`composeChoices`) with the TO line's addressees: RESUPPLY's
items list the pre-made crates of the logistics asset on TO, or of every
logistics asset of the side with none there. It is drawn as a drop-down
(`composeDrop`): one cell reading the pick or PICK ONE, REQ in it when required,
and a press opens the list under it (NONE first on an optional item), pushing
the column down as the marker list does. No picks (no logistics asset, the
addon not loaded): the typed box it was. The card's own `choices` stay empty, so
any name passes the engine, and the server matches it to the catalog as before.

**A required exclusive tick group is "tick one"** (2026-11-02; messaging
`validate`). CALL FOR FIRE's TYPE OF MISSION is the deck's: the line head reads
`REQ - TICK ONE` once, on the right; after a SEND that found none ticked the
group's ticks get one accent frame (`composeSend` lists the group once, by its
first tick's key) until one is ticked. No tick carries a mark of its own.

**The autofills** (report-card review, user 2026-11-02, decision 5; built, not
seen in game). A field's `autoFill` names a source, and `composeAutoFill` fills
it before every draw of the card - so a field follows its source as it
changes. Each source is a small client function:

| `autoFill` | Fills | Function |
|---|---|---|
| `vehicle` | DEFREP VEHICLE: the crew's call sign and the type of the vehicle the sender is in | `autoVehicle` |
| `vehicleDamage` | DEFREP DAMAGE ticks: GREEN under 10 % and it moves, YELLOW under 50 %, RED worse or it cannot move, BLACK destroyed | `autoDamage` |
| `vehicleFuel` | DEFREP FUEL ticks: GREEN half or more, YELLOW a quarter, RED any, BLACK empty | `autoFuel` |
| `wind` | HLZ WIND: `FROM 270 - 5 M/S`, or CALM | `autoWind` |
| `squadAce:A`, `squadAce:C` | SITREP STATUS AMMO and CAS: the worst of the squad's ACE letter (the Squad app's; a man down C RED, dead BLACK; YELLOW reads AMBER on the pick) | `autoSquadAce` |
| `threadAnchor` | BDA TARGET filed in a thread: the thread's own point, off this machine's index. SEND SITREP takes the TIC's grid from the same function. SALUTE was kept as it was - no autofill | `autoAnchor` |

The CAS 9-line's `elevation`, `bearing` and `distance` sources (`autoElevation`,
`autoLeg`) went with the card (user, 2026-11-02: "CAS REQUEST and CAS 9-line do
not need both").

**The player's answer stands.** A field still holding what it was last given
follows its source; one he typed over, ticked or picked otherwise is his. A
field is written only when its source's answer changes, so a tick he moved is
not put back on the next press. What was given is kept in the answer map
itself (`#autofill`), so a new card - or one a refusal puts back - starts its
own. No autofill is the sender's own position: the only place one fills is the
thread's point or one worked out from the card's own grids. Grids are read as
the server reads them (`jmfsb_messaging_fnc_fieldPos`): a map click, a marker's
name, or a typed grid.

**One-tap replies** under a thread are the reply cards with nothing required
(2026-11-02): the deck's WILCO and ON TASK carry an optional DETAIL line since
the review, and the old "no fields" rule dropped them. A report that can also
be filed as a reply (SITREP) is not a tap. MIST is a root card only - its own
thread.

**After contact, a SITREP** (user, 2026-11-02: "after contact a sitrep
should be sent"; built, not seen in game). An open TIC thread - its root card
carries the `broadcast` flag `tic` - has **SEND SITREP** first on its quick
row, for the TIC's sender and his squad leader (`readerQuickTiles`). One press
(`sitrepAfterTic`) opens the deck's SITREP in the composer, filed into the TIC
thread: LOCATION is the thread's point (the TIC's grid; his GPS position where
the thread has none), STATUS AMMO and CAS the card's own `squadAce`
autofills. The mod's built-in SITREP is `both` and always wins; a SITREP
that is still a root card cannot take it in a thread: a new
SITREP thread goes to the TIC's net, REMARKS reads `SITREP AFTER TIC <grid> -
THREAD <id>`, and the line beside SEND says so.

The sender's machine watches for the contact ending (`contactArm`,
`contactAgain`, `contactCheck`, `contactDrop`, `contactTraffic`). His own TIC
coming back filed - key, map panel or a card by hand - starts it: one handler
each for `FiredMan`, `FiredNear`, `Hit` and `Suppressed` on his group's units
stamps the time (Hit and Suppressed only fire for a local unit), and so does a
new TIC from his group (by its sender's group, or for a TIC on a net, its point
within 300 m of one of his men). One check is queued 180 s out
(`CONTACT_QUIET_S`) and queues itself to the last stamp; nothing polls. Quiet
that long: `CONTACT OVER? SEND SITREP` upper right, and as the accent label
over SEND SITREP on the TIC thread's row. Once per TIC; contact again takes it
back and arms it again; his SITREP (in the thread or its own) or the thread
closing ends the watch. A newer TIC of his replaces it.

**+ MARKER is a quick reply that sends a place.** Beside + TEMPLATE under an open
thread, it drops down the same `markerGrids` list and posts the marker's name
*and* its grid as a free-text reply, in one press. Half of what gets typed into a
thread is somebody reading a grid off the map and typing it back in, which is
where a digit gets dropped; the marker already knows both. The name alone would
not do — a call sign nobody else has on their map is not a location.

## Colour

Nothing in `gui.hpp` carries a colour. Every control is painted at runtime from
four tokens — **ground, ink, accent, line** — which is what makes a scheme change
a repaint of what is already on screen rather than a rebuild.

| scheme | |
|---|---|
| `jmsb` | **JMSB Day** — the unit's paper, `#e9e4d3`, ink `#20261c`, accent `#8a7550` (a darker tan; the logo's `#c2a878` is too pale on a light ground) |
| `light` | **Field Grey** — the design's own ground, `#f3f2f2`, ink `#201e1d`, accent `#ec3013` |
| `olive` | `#e8e7e2`, ink `#16281d`, accent `#b5cc4a` |
| `sand` | `#efece4`, ink `#2b2119`, accent `#d99427` |
| `nightJmsb` *(default)* | **JMSB Night** — the unit's own look (the G logo, ranger green and tan): `#20261c`, ink `#e9e4d3`, accent `#c2a878` |
| `dark` | **Night / Red** — `#141514`, ink `#e6e5e2`, accent `#ff563c` |
| `nightOlive` | **Night Olive** — `#101411`, ink `#d9e0d4`, accent `#9cb43c` |
| `nightSand` | **Night Sand** — `#161310`, ink `#e5e0d6`, accent `#c78221` |
| `custom` | three settings, each `#RRGGBB` or the older `r,g,b`; anything empty falls back to the Field Grey answer |

Four day grounds and four night ones, in **matching pairs** — JMSB Day with JMSB Night, Field Grey with
Night / Red, Olive with Night Olive, Sand with Night Sand — so a unit that runs
olive by day is not forced onto red the moment the sun goes down. A night scheme
is the dark ground under its day scheme's own accent, held down to what does not
blow your eyes out at 0200.

The dark one was called *Night / NVG*, which claimed something it never did: no
scheme here knows or cares whether the player is wearing tubes. It is the red
night ground, and it is named that.

All eight are switchable in game from the settings app, which shows them as the
three tokens they are made of rather than as eight words. The website offers
the same eight (DIVINER_Web `src/schemes.php`).

**A mission can add its own row.** `JMFSB_TacpadSchemes` in the mission's
`config\config_tacpad.hpp` — one class per preset, `name` plus `ground`, `ink`
and `accent` — is drawn under the shipped eight as MISSION PRESETS. Each one is
the `custom` scheme with its three tokens filled in, so a unit palette costs the
mission one file and this addon nothing: there is no extra scheme name here,
and there is nothing for a mission that does not define any to fall over.
See `jmfsb_tacpad_apps_fnc_missionSchemes`.

Reading the player's Arma interface colours was tried and **dropped**. It made
the tacpad a different mod on every machine, and the near-white ink most people
run turned every divider and tile border into a white cage over the map. The
suite is set in one palette so it reads as one thing.

Light and dark are switchable in game from the gear under the message reader,
not just in Addon Options.

## Size

Two levers, deliberately separate:

| | |
|---|---|
| `textScale` | a **legibility** choice — bigger type, taller rows, fewer of them |
| `uiScale` | a **scale** — the same layout, smaller or larger: panels, rows and type together |

A player who wants big text on a small suite can have both. The settings screen's
**UI SIZE** section steps `uiScale` by 1, 5 or 10 percent in either direction with
a RESET TO 100%, because "a bit smaller" is a press rather than a number to look
up; the slider behind it is still in Addon Options.

`uiScale` multiplies a panel's placed **width and height**, not its position — a
suite taken down ten percent keeps every panel where its corner was and gives the
screen back from the other two edges. Dragging the whole layout towards the top
left is not what "make it smaller" means to anyone looking at it.

A size change **rebuilds** rather than repaints, since panel geometry comes out of
`place` — and a rebuild makes every panel the newest control on the display, so
`open` puts the open app back in front afterwards. Arma has no way to raise a
control; reopening the app is a redraw either way.

## Drawing

Panels do not call `ctrlCreate`. Five functions are the whole vocabulary, so a
kicker is the same kicker and a 2px rule is the same 2px rule wherever it lands:

| | |
|---|---|
| `drawFill` | a flat rectangle of colour |
| `drawFrame` | an outline of four edges, drawn *around* what is inside rather than behind it — the only version that composes over a wash |
| `drawText` | one line in a type role, optionally letter-tracked (Arma has no letter-spacing, so a tracked label is drawn with a space between each glyph) |
| `drawIcon` | an image, tinted and squared through the pixel scales |
| `drawHit` | the transparent button and its handler, as one call |
| `textH` | how tall one line is at a given size, so a cell can be sized from the label it holds rather than from a guess at the player's UI scale |
| `headerMeta` | a panel's right-aligned header readout — `13 / 16`, `3 NETS` |
| `appFrame` | the chrome a full-size app opens in, and the body to fill — one copy, where there used to be one per app; its ground is solid whatever the panel opacity (review 2026-11-01): panels may be see-through, apps may not |
| `appClose` | the one teardown every exit runs — CLOSE, ESC, a click on the map — including the orphan sweep |

`drawText` centres its line vertically in the box it is given, because structured
text renders against the top edge and every label in the suite was sitting high
in its own row with all the air underneath it.

**Live screens build once and change words in place** (code review R8). A screen
that ticks — a live app, the tile band, the devices' rows — must not delete and
recreate its controls on the tick: a control deleted between a press and its
release never raises a click, and a render-to-texture picture made again flickers.
Five helpers carry the rule:

| | |
|---|---|
| `retext` | sets the words and colour of a line `drawText` made, in its same type role; `drawText` writes through it, so a line updated on a tick reads exactly as it was drawn |
| `liveStore` / `liveApply` | a screen stores its *shape* (everything that decides which controls exist and where) and its live lines and fills after a full draw; its tick hands the new shape and values to `liveApply`, which writes them in place, or answers false and the screen is built again as before |
| `changed` | the change key the tablet rows use, as one helper: a value's text kept on a holder under a name, true only when it differs |
| `nextFrameOnce` | one redraw next frame however many times it is asked for this frame |

`composeTargets` is worked out once a frame; a reader draw asks for it from the TO
line, the CC line and the picker. The rail's net press and squad fold ask for the
reader's redraw through `nextFrameOnce`.

Rule weights are `RULE_THIN` and `RULE_THICK` **in real screen pixels**. The
design separates a 1px row boundary from a 2px region boundary and that
difference is the grid being visible; they were multiplied by the UI grid once,
which drew both at about 4px and made them the same rule.

## Adding a panel

```sqf
["squad", "SQUAD", DEFAULT_SQUAD, FUNC(panelSquad), FUNC(panelSquad), 2] call jmfsb_tacpad_fnc_register;
```

Register in preInit. The shell owns the frame, the dragging, the theming and the
saved position; a panel is handed a body control and fills it. Whether it is
drawn at all is read from `jmfsb_tacpad_apps_show_<id>`, so a new panel needs a
CBA setting with a matching name and nothing else.

The last flag is the **inverted title bar** — ink fill, ground text. An app takes
it, a rail does not; the reader is the only panel that does.

`shared.inc.hpp` carries the geometry and the idc scheme and is deliberately free
of `script_mod.hpp` — an addon that included this one's whole
`script_component.hpp` would have its own `COMPONENT` redefined out from under
it, and every `PREP` in it would then look for its functions in this folder.

## Quick answers off the tablet

`askTraffic` reads each arriving message for a `prompt` card with answers, and
for what settles it: an answer in the thread, a newer question, or the thread
over (user, 2026-11-06). The walking view puts the first waiting question on
numpad 6-9 (`askView`, `askKey`), FLASH first, then the newest. The answers
work as the quick tiles do. A line to fill opens the composer, and ADJUST
opens the distance pick. A player crew a support card was addressed to gets
that type's questions to ask instead (`ASK_CREW_QUESTIONS`). `askChoice`
(Public) puts a local choice on the same keys. The ECOTI building mark uses
it for its colour.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `cba_xeh` _(external)_

## Ships

123 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_tacpad_enabled` | CHECKBOX | Enable tacpad |
| `jmfsb_tacpad_displayMode` | LIST | Display mode |
| `jmfsb_tacpad_scheme` | LIST | Colour scheme |
| `jmfsb_tacpad_opacity` | SLIDER | Panel opacity |
| `jmfsb_tacpad_respectZones` | CHECKBOX | Keep clear of reserved areas |
| `jmfsb_tacpad_customGround` | EDITBOX | Custom: ground |
| `jmfsb_tacpad_customInk` | EDITBOX | Custom: text |
| `jmfsb_tacpad_customAccent` | EDITBOX | Custom: accent |
| `jmfsb_tacpad_quickReplies` | EDITBOX | Quick replies |
| `jmfsb_tacpad_uiScale` | SLIDER | UI size |
| `jmfsb_tacpad_textScale` | SLIDER | Text size |

## Functions

<details><summary>123</summary>

- `jmfsb_tacpad_fnc_appAlive`
- `jmfsb_tacpad_fnc_appClose`
- `jmfsb_tacpad_fnc_appExits`
- `jmfsb_tacpad_fnc_appFrame`
- `jmfsb_tacpad_fnc_appHost`
- `jmfsb_tacpad_fnc_appIdle`
- `jmfsb_tacpad_fnc_askChanged`
- `jmfsb_tacpad_fnc_askChoice`
- `jmfsb_tacpad_fnc_askCurrent`
- `jmfsb_tacpad_fnc_askItems`
- `jmfsb_tacpad_fnc_askKey`
- `jmfsb_tacpad_fnc_askList`
- `jmfsb_tacpad_fnc_askLocal`
- `jmfsb_tacpad_fnc_askTraffic`
- `jmfsb_tacpad_fnc_askView`
- `jmfsb_tacpad_fnc_autoAnchor`
- `jmfsb_tacpad_fnc_autoCas`
- `jmfsb_tacpad_fnc_autoDamage`
- `jmfsb_tacpad_fnc_autoFuel`
- `jmfsb_tacpad_fnc_autoSquadAce`
- `jmfsb_tacpad_fnc_autoValue`
- `jmfsb_tacpad_fnc_autoVehicle`
- `jmfsb_tacpad_fnc_autoWind`
- `jmfsb_tacpad_fnc_build`
- `jmfsb_tacpad_fnc_changed`
- `jmfsb_tacpad_fnc_chipWidth`
- `jmfsb_tacpad_fnc_clock`
- `jmfsb_tacpad_fnc_close`
- `jmfsb_tacpad_fnc_composeAutoFill`
- `jmfsb_tacpad_fnc_composeCard`
- `jmfsb_tacpad_fnc_composeCardHead`
- `jmfsb_tacpad_fnc_composeCcDrop`
- `jmfsb_tacpad_fnc_composeCcIds`
- `jmfsb_tacpad_fnc_composeChoices`
- `jmfsb_tacpad_fnc_composeDrop`
- `jmfsb_tacpad_fnc_composeFire`
- `jmfsb_tacpad_fnc_composeFireTick`
- `jmfsb_tacpad_fnc_composeFrago`
- `jmfsb_tacpad_fnc_composeFragoPayload`
- `jmfsb_tacpad_fnc_composeHarvest`
- `jmfsb_tacpad_fnc_composeMention`
- `jmfsb_tacpad_fnc_composeMentionAsk`
- `jmfsb_tacpad_fnc_composeMentionSwitch`
- `jmfsb_tacpad_fnc_composeMentionTyped`
- `jmfsb_tacpad_fnc_composeOpen`
- `jmfsb_tacpad_fnc_composePane`
- `jmfsb_tacpad_fnc_composePicker`
- `jmfsb_tacpad_fnc_composePreviewText`
- `jmfsb_tacpad_fnc_composeSend`
- `jmfsb_tacpad_fnc_composeShortDefault`
- `jmfsb_tacpad_fnc_composeTargets`
- `jmfsb_tacpad_fnc_composeTiles`
- `jmfsb_tacpad_fnc_composeToPicker`
- `jmfsb_tacpad_fnc_composeToSupport`
- `jmfsb_tacpad_fnc_composeToSupportDraw`
- `jmfsb_tacpad_fnc_composeToSupportLine`
- `jmfsb_tacpad_fnc_composeToSupportTick`
- `jmfsb_tacpad_fnc_contactAgain`
- `jmfsb_tacpad_fnc_contactArm`
- `jmfsb_tacpad_fnc_contactCheck`
- `jmfsb_tacpad_fnc_contactDrop`
- `jmfsb_tacpad_fnc_contactTraffic`
- `jmfsb_tacpad_fnc_diaryWatch`
- `jmfsb_tacpad_fnc_drawChip`
- `jmfsb_tacpad_fnc_drawFill`
- `jmfsb_tacpad_fnc_drawFrame`
- `jmfsb_tacpad_fnc_drawHit`
- `jmfsb_tacpad_fnc_drawIcon`
- `jmfsb_tacpad_fnc_drawText`
- `jmfsb_tacpad_fnc_fit`
- `jmfsb_tacpad_fnc_fragoSame`
- `jmfsb_tacpad_fnc_headerMeta`
- `jmfsb_tacpad_fnc_hexOf`
- `jmfsb_tacpad_fnc_hostDisplay`
- `jmfsb_tacpad_fnc_hotspot`
- `jmfsb_tacpad_fnc_liveApply`
- `jmfsb_tacpad_fnc_liveStore`
- `jmfsb_tacpad_fnc_markerGrids`
- `jmfsb_tacpad_fnc_netBox`
- `jmfsb_tacpad_fnc_netLabel`
- `jmfsb_tacpad_fnc_nextFrameOnce`
- `jmfsb_tacpad_fnc_open`
- `jmfsb_tacpad_fnc_openApp`
- `jmfsb_tacpad_fnc_openReader`
- `jmfsb_tacpad_fnc_place`
- `jmfsb_tacpad_fnc_rankShort`
- `jmfsb_tacpad_fnc_readerCallUnits`
- `jmfsb_tacpad_fnc_readerCard`
- `jmfsb_tacpad_fnc_readerChip`
- `jmfsb_tacpad_fnc_readerClose`
- `jmfsb_tacpad_fnc_readerComposer`
- `jmfsb_tacpad_fnc_readerDraw`
- `jmfsb_tacpad_fnc_readerFlash`
- `jmfsb_tacpad_fnc_readerInput`
- `jmfsb_tacpad_fnc_readerKv`
- `jmfsb_tacpad_fnc_readerKvRows`
- `jmfsb_tacpad_fnc_readerList`
- `jmfsb_tacpad_fnc_readerMarkers`
- `jmfsb_tacpad_fnc_readerNetView`
- `jmfsb_tacpad_fnc_readerPreview`
- `jmfsb_tacpad_fnc_readerQuick`
- `jmfsb_tacpad_fnc_readerQuickTiles`
- `jmfsb_tacpad_fnc_readerRail`
- `jmfsb_tacpad_fnc_readerReplies`
- `jmfsb_tacpad_fnc_readerRow`
- `jmfsb_tacpad_fnc_readerThreadView`
- `jmfsb_tacpad_fnc_rebuild`
- `jmfsb_tacpad_fnc_register`
- `jmfsb_tacpad_fnc_registerApp`
- `jmfsb_tacpad_fnc_repaint`
- `jmfsb_tacpad_fnc_retext`
- `jmfsb_tacpad_fnc_rgbOf`
- `jmfsb_tacpad_fnc_roleShort`
- `jmfsb_tacpad_fnc_setHost`
- `jmfsb_tacpad_fnc_sitrepAfterTic`
- `jmfsb_tacpad_fnc_starterInReport`
- `jmfsb_tacpad_fnc_taskInThread`
- `jmfsb_tacpad_fnc_textH`
- `jmfsb_tacpad_fnc_textPx`
- `jmfsb_tacpad_fnc_textSize`
- `jmfsb_tacpad_fnc_theme`
- `jmfsb_tacpad_fnc_threadLegal`
- `jmfsb_tacpad_fnc_xmlSafe`

</details>
