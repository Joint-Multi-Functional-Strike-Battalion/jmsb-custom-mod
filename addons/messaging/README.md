# Messaging

`jmfsb_messaging`

Threaded reports and tasking, without cTab. The store is on the server and the
clients hold a disposable cache; a task is a thread whose root template moves it
into a state, so there is no second object that can disagree about what is open.

Everything is a mailbox. A player, a group and a shared filing box differ only in
how their membership is worked out, and membership is derived every time rather
than stored — a player who changes squad mid-mission stops getting their old
squad's traffic immediately.

The UI is `jmfsb_tacpad`'s — TAC//MSG on the map screen. This is the engine
under it, and it is usable from script on its own.

## The chain, and where it stops

Four links, and **every one of them is designed to fail quietly**, which is what
makes a broken send so hard to read from the outside: a refusal is told to the
sender alone, and a delivery to a mailbox nobody is standing in is a legitimate
no-op rather than an error.

| | |
|---|---|
| 1. client `submit` | validates the payload locally, then sends it to the server by `remoteExecCall` of `srvSubmit`. Refuses with a reason and never leaves the machine if a required field is empty, if there is no addressee, or if messaging is off |
| 2. server `srvSubmit` | checks the unit named is the sending machine's own and a live player, drops a repeated nonce, validates *again*, opens or finds the thread (`srvThreadFor`), files the message |
| 3. server `srvDeliver` | works out the mailboxes — always `P:<sender>`, plus the addressees, plus the command group if a ROUTING line is ticked — files the thread in each, and pushes one `cltReceive` per PLAYER, never one per box they happen to share |
| 4. client `cltReceive` | replaces that thread's row in `jmfsb_messaging_index` and runs the `onReceive` hooks. The reader draws off that index and nothing else |

A shared box has no members — a named box is readable by everyone rather than
subscribed to — so a thread filed only in one is pushed to every player as a
*quiet* row: an index entry with no message body and no notification.

Anything the server refuses comes back to the sender and nobody else
(`cltReject`), which runs the hooks screens register with `onReject` (TAC//MSG's
composer puts the card back). It now also prints to system chat, because the
notification stack is an `RscTitles` layer and every screen it would be about is
a dialog — in front of it.

## Who sent it (review S7)

Nothing that needs trust travels on a CBA event: an event carries no sender, so
the server could only believe the unit it was handed. A client reaches the
server by `remoteExecCall` of five functions, and each checks at its top that
the unit it names is the sending machine's own (`jmfsb_common_fnc_senderIs`):

| function | the client's request |
|---|---|
| `srvSubmit` | file a message. A call sign override is dropped unless the sender is an admin by the server's records (the `msg.*` test commands) or the server itself. Argument 10 (2026-11-01) files it under another priority than the template's (`high` / `normal`) - the server's own call only: a support asset's `prompt` is FLASH while it waits to release or is about to leave |
| `srvRequestIndex` | his own index. The rows are built by `srvIndexPush`, which the server also calls on its own account (a claim, `msg.clear`) |
| `srvRequestThread` | one thread's bodies, when he may read it |
| `srvMarkRead` | mark a thread read for himself |
| `srvClaim` | claim or release a task thread for himself |

The server answers by `remoteExecCall` of `cltReceive`, `cltIndex`, `cltThread`,
`cltMarker`, `cltReject` and `cltCacheClear`, and each takes the call only from
the server (`jmfsb_common_fnc_fromServer`). A mission with a `CfgRemoteExec`
whitelist must list all eleven. Server-side callers (the counter-battery radar,
the test commands) call `srvSubmit` directly and pass as the server.

The other way round holds too: nothing the server says to a client goes on a
CBA event, because any client can raise any of them on every machine (review
S7). A refusal reaches a screen through an `onReject` hook, which only
`cltReject` runs; `msg.clear` empties the caches by `cltCacheClear`. The old
`threadUpdated`, `taskStateChanged` and `tic` global events had no listener and
went to every machine on every claim, sweep and contact report (P8); they are
gone. A screen hears a change through the index push (`cltReceive`, `cltIndex`).
Traffic arriving for the player runs the hooks screens register with
`onReceive` (the reader redraws, TAC//MSG raises a FLASH banner) - it used to
be the `received` CBA event, which any client could raise to put a fake FLASH
banner on every screen. A quiet row still raises the local `indexRefreshed`
event, which only redraws from the player's own index.

## Answering traffic on the server (`onFiled`, 2026-11-01)

```sqf
[{params ["_thread", "_message", "_boxIds"]; ...}] call jmfsb_messaging_fnc_onFiled;
```

Server only, local calls only; the hooks live in `localNamespace`. Every
message `srvSubmit` accepts runs every hook with the thread and message
records and a copy of the thread's box ids, **in the next frame, each hook on
its own** (`CBA_fnc_execNextFrame`): the message is already stored, boxed and
pushed, a hook that errors cannot stop the filing or the next hook, and a hook
runs outside the client's `remoteExecCall`, so a reply it files by calling
`srvSubmit` passes as the server (call sign override included). A hook sees
every message, replies included (the root has `seq` 0). This addon names no
system that listens: the support core answers threads filed to
`B:SUPPORT:<assetId>` from here (support README, "Threads").

## A card filed into an open thread (`onThreadCard`, 2026-11-02)

```sqf
[{params ["_thread", "_template", "_unit"]; ""}] call jmfsb_messaging_fnc_onThreadCard;
```

Server only, local calls only. `srvThreadFor` asks every hook, **in the
call**, about a player's card filed into a thread that is already open - never
about the server's own filings (an asset's states through the call sign
override). The first hook with an answer decides: `""` no opinion, `"take"`
(`THREAD_CARD_TAKE`) a ROOT card goes into the thread, anything else is the
refusal. **A root card (kind `root`) no hook takes is refused** -
`<SHORT> opens its own thread`; until 2026-11-02 any root card went into any
thread a client named. The sender checks that follow (addressed or a
participant, `allowedFrom`, `senderMustBe`) still run on a card a hook took.
The support core rules on its assets' threads (support README, "A card filed
into an asset's thread"): a new CAS REQUEST or NEXT LIFT from the issuer is
taken; ROGER, WILCO, ON TASK and CANTCO from a player are refused. Built, not
seen in game.

## Template classes, short form, FRAGO (2026-11-09)

From `docs/DESIGN_MESSAGE_TEMPLATES.md`. Built, not seen in game.

Every card is a starter, a follow-up, a command or what the asset says.
`registerTemplate` takes options that say who is offered a card; the reader
and the support core read them:

| option | meaning |
|---|---|
| `assetOnly` | the asset's side; never in the requester's menu |
| `answerOnly` | offered only when the asset asks for it |
| `assetThread` | offered only in a thread an asset answers |
| `roots` | offered only where the thread's current order is one of these cards |
| `shortLines` / `shortFields` | the short form: the lines (and, inside one, the fields) it keeps. Built into the card's `shortKeys`. A required field is always kept |
| `openFields` | `validate` keeps keys the card does not have (FRAGO) |

**Short form.** One card, two views, the same id and keys. The composer has a
STD / SHORT switch; the reader shows only filled lines, so both read alike.

**Current order.** `currentOrder` gives a thread's last tasking card (a root
or `both` card with a transition: the root, or a starter filed into the
thread since) with every FRAGO after it laid over. Server and client use it.

**FRAGO.** The `frago` card carries the order's card id in `Card.A`, a reason,
each changed key and its old value under the key + `#was`. `srvSubmit`
refuses one that names another card, changes nothing, or leaves the merged
order failing that card's own checks, and rewrites the `#was` values from its
own store. `render` and `fragoLines` show only the changed lines, old and new.

**A starter in an open thread.** A root card a thread hook takes
(`onThreadCard`) goes into the thread as before; it now also makes the thread
a task thread. The support core takes a starter in an asset's thread (the
next tasking) and a support request in a TIC, SALUTE or MIST thread (it
pulls the asset in).

**CASEVAC** is the 9-line (ATP 4-02.2): line 3 precedence A-D, line 6
security N / P / E / X, line 7 marking method only. **MIST** is a report and a
follow-up (`both`), so it is filed inside the CASEVAC's thread.

## The map pin

A thread the sender pinned (the composer's position beside the payload) marks
the map once, for the people the message was pushed to, with a local marker
(`cltMarker`, from `srvDeliver`); `srvSweep` removes it with the thread. A
template's own `anchor` only anchors. **A support thread's pin draws more**
(2026-11-01, `docs/DESIGN_SUPPORT_MESSAGING.md` 6.3; built, not seen in
game): the card's target / LZ, its legs, danger close and, while the asset
works, its overlay and route - local markers too, worked out on the client by
the support core from the bodies this addon already hands its `onReceive`
hooks and its cache (support README, "The thread's map pin"). This addon
still names no support system.

## Seeing where it stopped

Admin chat commands, gated on the jmfsb admin flag like the rest of `#jmfsb`:

| | |
|---|---|
| `#jmfsb msg.state` | is it enabled, how much is in the store, which mailboxes you can see |
| `#jmfsb msg.boxes` | every mailbox, its kind, its thread count and how many players are in it *now* |
| `#jmfsb msg.threads` | every thread: id, priority, status, subject, message count, boxes |
| `#jmfsb msg.send` | file a free-text message to yourself through the real server path |
| `#jmfsb msg.mine` | what your own client has in its index — the far end, which a server dump cannot see |

`msg.send` then `msg.mine` isolates it in two presses: a thread that exists on
the server but not in your index is a delivery problem, and one that appears in
both but not on screen is the reader.

**A send refused before it left** (user, 2026-11-02: "arty never replied";
built, not seen in game). `submit` validates on the sender's machine first; a
refusal there never reaches the server, so the server's RPT has nothing. Every
local refusal - a required field empty, a number out of range, no addressee,
the link jammed, messaging off - is now a `NOT SENT` popup upper right with the
reason, and one RPT line on the sender's machine:
`(messaging) INFO: not sent '<template>' - <reason>`. A send that left is one
line too, `sent '<template>' to [<addressees>] (thread '<id>')`, so the RPT
says which box a card was filed in.

## Testing it on your own

A threaded system needs two people to prove and there is rarely a second one on
a dev box, so these file traffic **from somebody else** — through the real
server path, so it arrives unread, raises a notification and lands on the thread
spine exactly as another player's would. Only the call sign is a lie: `srvSubmit`
takes an optional override and, when one is given, does *not* mark the message
read by the sender. The override is honoured only for the server and for an
admin by the server's records.

| | |
|---|---|
| `#jmfsb msg.inbound [text]` | HQ SIGNALS sends you a message — unread, with the alert |
| `#jmfsb msg.flash` | DOC RILEY files a FLASH CASEVAC on your grid — the accent row, the chip, the card and the alert all come off this one. It files the 6-LINE CASEVAC's keys (user, 2026-11-02: "the 6-line only") - the mod's built-in `casevac`, whatever the deck holds |
| `#jmfsb msg.reply <threadId> [text]` | ROTARY 1-1 answers a thread, so the spine and the unread count have something in them |
| `#jmfsb msg.clear` | empties the store and refreshes every index — start the run again |

A full pass on your own, from a cold mission:

1. `#jmfsb msg.flash` — a FLASH thread arrives. Check the notification, the
   accent row in the list, the unread count on its net tab.
2. Open it. The card should read as the filled 6-line in one column: each
   filled line's label, its value right after it, a long answer under its
   label across the card; no empty lines, not prose.
3. `#jmfsb msg.threads`, take the id, then `#jmfsb msg.reply T0001` — the reply
   appears on the spine and the thread comes back unread.
4. Answer it from the reader: a quick reply, then + GRID, then + MARKER, then
   + TEMPLATE for one that needs a card.
5. `#jmfsb msg.mine` — the index should show one row per thread per mailbox.
6. `#jmfsb msg.clear` and start again.

The one thing this cannot prove is a second machine: locality, `groupOwner`
routing and JIP index requests all need a real client.

```sqf
// send
["tic", [
    ["Location.A", getPosATL player],
    ["Enemy.A", "Two technicals, north edge of the town"],
    ["Intentions.A", "Holding the compound"]
], ["B:HQ", "G:Alpha 1-1"]] call jmfsb_messaging_fnc_submit;

// read
["T0001"] call jmfsb_messaging_fnc_open;

// reply into a thread
["wilco", [], [], "T0001"] call jmfsb_messaging_fnc_submit;
```

Addressees are mailbox ids: `P:<uid>` for one player, `G:<groupId>` for a group,
`B:<name>` for a shared box. A bare name is taken as a shared box, so `"HQ"` and
`"B:HQ"` reach the same place.

## Templates

All thirteen cTab reports are here, one for one, in `templates.inc.sqf` — the
JMSB smart-card deck plus SITREP and CALL FOR FIRE. Six reply templates were
added, because a threaded system that cannot answer a report is a noticeboard.

Two things in that file are contracts, not presentation:

- **Line titles are field keys.** `registerTemplate` builds each field key from
  its line title, which is what lets the ALiVE forwarder find a CONTACTREP's
  `S`/`A`/`L`/`U`/`T`/`E`/`R` and a SITREP's `Callsign`/`Location`/`Enemy`/
  `Friendly`/`Civ`/`Status`/`Remarks` without counting lines. Rename a line title
  and you have renamed a field. Rename a field's label and nothing breaks.
  The SITREP has no `Callsign` line since the report-card review (2026-11-02):
  the forwarder sends the sender's group id instead, or the line where an
  older deck still has it.
- **The ROUTING line.** DEFREP carries a tick that also mails the command
  group. The template names that field in its `routing` option rather than the
  code searching for it, so it can be moved.

**The mod's own card always wins** (user, 2026-11-02: card changes reach the
game with the mod - nobody runs a script against the database; built, not
seen in game). Every card the mod defines is built in and is the one used.
`registerBuiltins` `[cards, who]` registers them with the option
`["builtin", true]` (the template carries `builtin`, BOOL): messaging's own
in its preInit (`builtinCards` - the reports and the replies every thread
takes, below), the support core's in its preInit (support README, "The
cards the mod carries"), PAC's OPORD and METT-TC in its postInit. A
mission's own deck (`JMFSBFR_Templates`), registered first, is replaced
where it stands for every id the mod carries - one RPT line, the next frame,
names the cards replaced. The TAC//PAC deck arrives later: pac
`templatesApply` skips every id the mod carries and every retired id
(`CARDS_RETIRED`: `accepted`, `ontask`, `nineline` - `jmfsb_messaging_retiredCards`)
and adds only the cards the mod does not have - a unit's own. One RPT line
names the deck cards skipped, when that list changes. A deck card registered
over a built-in one some other way is refused like any id registered twice.

**Messaging's built-in cards** (`builtinCards`; they work without the support
core): SALUTE (`contactrep`, the original full card), MIST (the original full
card), TROOPS IN CONTACT (`tic`), SITREP (kind `both`), the 6-LINE CASEVAC
(`casevac`), VEHICLE REPORT (DEFREP) (`defrep`), MESSAGE (`freetext`), and
the replies ROGER, WILCO, ON TASK (both with the asset's DETAIL line),
CANTCO and CLOSE THREAD. METT-TC and OPORD are PAC's (pac
`registerTemplates`).

**The report-card review** (`docs/REVIEW_REPORT_CARDS_2026-11-02.md`, user
decisions 2026-11-02; built, not seen in game) is in the built-in cards: the
6-LINE CASEVAC on `casevac`, required only where the receiver cannot act
without it, ROGER from an OPEN thread (a report: TIC, SALUTE, SITREP, MIST,
DEFREP, CHECK-IN, METT-TC), renamed titles with the same keys, no CUR LOC on
a target grid, picks where a reader looks for a word, and the composer's
autofills (tacpad README). No line title a reader uses was renamed.

**A typed grid anchors the thread** (2026-11-02, the review's rule 9).
`srvThreadFor` reads the template's anchor field with `fieldPos`
`[value]` (Public): a position, a marker's name, or a 6 / 8 / 10 figure
grid typed by hand, read on this terrain by `jmfsb_maptools_fnc_gridToPos`
when the map tools are loaded (messaging does not require them - they
require tacpad - so the function is asked only where it exists). A grid it
cannot read leaves the anchor on the sender, as before. A subject whose
optional field was left empty loses the dangling ` - ` (`FUNC(subject)`).

`dangerClose` (metres, a number; 0 or unset = none) is a card's own
danger-close threshold, read as `_template get "dangerClose"` (D8, 2026-11-01:
the built-in calls for fire carry 600, `jmfsb_support_fnc_builtinFires`).

**Two field options** (user, 2026-11-02; built, not seen in game), kept on
every field `registerTemplate` builds:

| Option | Default | Means |
|---|---|---|
| `markerOnly` | `false` | a grid only a map marker answers ("REQUEST ON STATION should require a map marker"). `validate` refuses a value that is not a position - typed text - and, when the field is required, none, with `PICK A MAP MARKER FOR THE <line label>` (`MARKER_ONLY_WHY`): REQUEST ON STATION's AREA says `PICK A MAP MARKER FOR THE AREA`. The composer offers the marker list alone (tacpad README). Any grid picked from a marker carries the marker's name in the payload as `<key>#marker` (`MARKER_NAME_SUFFIX`, 2026-11-05); `render`, `subject` and `srvForward` print `041117 (LZ RAVEN)` |
| `choicesFrom` | `""` | a choice whose picks the composer fills at runtime ("we have pre made crates so the requested items should be a drop down of them") - `logiCatalog` on RESUPPLY's items. The card's own `choices` stay empty, so `validate` passes any answer; the reader matches it (support_logistics) |

**A required exclusive tick group means "tick one"** (2026-11-02): ticks
sharing an `exclusive` group with `required` on them need one of them ticked,
not each - `validate` says `<line label> is required - tick one`. CALL FOR
FIRE's TYPE OF MISSION is the deck's. The composer marks the line once (tacpad
README).

## Carried over from cTab

- **TIC.** A CONTACT REPORT was never really a message — it was an alarm typed
  into a message form, and it is the one report that reaches people it was not
  addressed to. cTab hardcoded that against the template's uid; here it is a
  template flag, so a mission can put it on another report without touching
  code. It goes out on `jmfsb_common`'s alert bus, side-filtered, and draws a
  **local** marker on the sending side's map — a global one would be on the
  enemy's map too.
- **ALiVE reports.** CONTACTREP posts as a spotrep and SITREP as a sitrep, each
  with a companion marker. This addon never names an ALiVE symbol: it flattens
  the payload into named fields and hands them to
  `jmfsb_adapter_alive_fnc_postReport`, which is new. Exactly one addon may know
  ALiVE exists and `tools/check_invariants.py` fails the build over it.

## Record shapes

Every record is a HashMap and every one of them lives on the server only, because
a message has thirteen fields and nobody reads `_msg select 11` correctly at two
in the morning. They are flattened with `toArray` at the network boundary and
rebuilt with `createHashMapFromArray` on the far side, since a HashMap is not
guaranteed to survive a `remoteExec`.

| record | keys |
|---|---|
| message | id seq threadId parentId fromUid fromCallsign templateId payload sentTime gameTime priority transition readBy |
| thread | id kind subject rootTemplateId status issuerUid claimedBy participants boxes anchorPos anchorLabel parentThreadId lastActivity closed messages |
| box | id kind displayName roles uids retention forwardToAlive threads |
| index | threadId boxId subject status priority templateId replies claimedBy lastActivity anchorPos unread |

A template is a HashMap too, but it is built from `templates.inc.sqf` in preInit
on every machine and never crosses the wire at all.

## Deliberate deviations from `work/mess.json`

- **`gfa_atak` became `jmfsb_messaging`**, using the standard `GVAR`/`QGVAR`
  macros like every other addon.

## Not built yet

`composeMinDevice`, EW link-state degradation, and FRAGO sub-threads. The
compose and inbox UI is tacpad's TAC//MSG, and so are the autofills a field's
`autoFill` names (tacpad README).

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_notify`
- `cba_xeh` _(external)_

## Ships

61 functions.

## CBA settings

| Setting | Type | Name |
|---|---|---|
| `jmfsb_messaging_enabled` | CHECKBOX | Enable messaging |
| `jmfsb_messaging_namedBoxes` | EDITBOX | Shared mailboxes |
| `jmfsb_messaging_commandGroup` | EDITBOX | Command group |
| `jmfsb_messaging_idleClose` | SLIDER | Idle close (min) |
| `jmfsb_messaging_ewLink` | CHECKBOX | EW link state |
| `jmfsb_messaging_ticBroadcast` | CHECKBOX | TIC alerts the side |
| `jmfsb_messaging_ticMarker` | CHECKBOX | TIC drops a map marker |
| `jmfsb_messaging_ticMarkerType` | EDITBOX | TIC marker type |
| `jmfsb_messaging_ticMarkerColor` | EDITBOX | TIC marker colour |
| `jmfsb_messaging_aliveReports` | CHECKBOX | Post reports to ALiVE |
| `jmfsb_messaging_aliveLocality` | LIST | ALiVE report locality |
| `jmfsb_messaging_sitrepMarkerType` | EDITBOX | SITREP marker type |
| `jmfsb_messaging_seedTest` | CHECKBOX | Seed test traffic |

## Functions

<details><summary>61</summary>

- `jmfsb_messaging_fnc_builtinCards`
- `jmfsb_messaging_fnc_cltCacheClear`
- `jmfsb_messaging_fnc_cltIndex`
- `jmfsb_messaging_fnc_cltMarker`
- `jmfsb_messaging_fnc_cltReceive`
- `jmfsb_messaging_fnc_cltReject`
- `jmfsb_messaging_fnc_cltThread`
- `jmfsb_messaging_fnc_currentOrder`
- `jmfsb_messaging_fnc_fieldKeys`
- `jmfsb_messaging_fnc_fieldPos`
- `jmfsb_messaging_fnc_fieldText`
- `jmfsb_messaging_fnc_follow`
- `jmfsb_messaging_fnc_fragoLines`
- `jmfsb_messaging_fnc_linkState`
- `jmfsb_messaging_fnc_loadTemplates`
- `jmfsb_messaging_fnc_netLevel`
- `jmfsb_messaging_fnc_netNames`
- `jmfsb_messaging_fnc_netStream`
- `jmfsb_messaging_fnc_netsApply`
- `jmfsb_messaging_fnc_notify`
- `jmfsb_messaging_fnc_onFiled`
- `jmfsb_messaging_fnc_onReceive`
- `jmfsb_messaging_fnc_onReject`
- `jmfsb_messaging_fnc_onThreadCard`
- `jmfsb_messaging_fnc_open`
- `jmfsb_messaging_fnc_platoonTags`
- `jmfsb_messaging_fnc_railNets`
- `jmfsb_messaging_fnc_registerBuiltins`
- `jmfsb_messaging_fnc_registerTemplate`
- `jmfsb_messaging_fnc_render`
- `jmfsb_messaging_fnc_request`
- `jmfsb_messaging_fnc_roleNets`
- `jmfsb_messaging_fnc_roleTag`
- `jmfsb_messaging_fnc_seedTest`
- `jmfsb_messaging_fnc_setNetLevel`
- `jmfsb_messaging_fnc_squadNets`
- `jmfsb_messaging_fnc_srvBox`
- `jmfsb_messaging_fnc_srvBoxesFor`
- `jmfsb_messaging_fnc_srvClaim`
- `jmfsb_messaging_fnc_srvDeliver`
- `jmfsb_messaging_fnc_srvForward`
- `jmfsb_messaging_fnc_srvIndexFor`
- `jmfsb_messaging_fnc_srvIndexPush`
- `jmfsb_messaging_fnc_srvMarkRead`
- `jmfsb_messaging_fnc_srvMembers`
- `jmfsb_messaging_fnc_srvNextId`
- `jmfsb_messaging_fnc_srvRequestIndex`
- `jmfsb_messaging_fnc_srvRequestThread`
- `jmfsb_messaging_fnc_srvSubmit`
- `jmfsb_messaging_fnc_srvSweep`
- `jmfsb_messaging_fnc_srvTagged`
- `jmfsb_messaging_fnc_srvThreadFor`
- `jmfsb_messaging_fnc_srvTic`
- `jmfsb_messaging_fnc_subject`
- `jmfsb_messaging_fnc_submit`
- `jmfsb_messaging_fnc_tagCallout`
- `jmfsb_messaging_fnc_tagMatch`
- `jmfsb_messaging_fnc_tagSet`
- `jmfsb_messaging_fnc_template`
- `jmfsb_messaging_fnc_templateIds`
- `jmfsb_messaging_fnc_validate`

</details>
