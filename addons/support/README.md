# Support

`jmfsb_support`

The support core: one registry of support assets, one request flow, one
acknowledgement hook (`onAck`). Support is called by message: TAC//MSG
reaches the assets through their mailboxes ("Assets as mailboxes", "Threads").
The TAC//SUPPORT app that used to read this addon was removed on 2026-11-01
(docs/DESIGN_SUPPORT_MESSAGING.md step 9); where the contract below says "the
screen" or "the board", that was the app. `request`, `preview`, `overlay`,
`types`, `tasks`, `sitrep` and `reach` stay as the core's public API - the
message path and mission scripts call them. Every asset source - the CAS drone modules and
the `support_fires` / `support_air` / `support_logistics` / `jumpmaster` addons - is a **provider** registered here.
There is no Simplex dependency (user, 2026-10-20): these addons are our own
replacement for it. The core knows no asset kind.

**Support is our own providers only** (user, 2026-11-02: "we should not be
relying on alive support" - "if alive is present we integrate - but not the
support"). ALiVE's NEO combat support and its ATO are no longer support assets;
support works the same with or without ALiVE.

Design brief: `docs/DESIGN_SUPPORT.md` (phase 1).

Providers depend on this addon, never the reverse. The CAS drone provider lives
in `cas`, the fires, air and logistics providers in `support_fires`,
`support_air` and `support_logistics`, and the jump aircraft in `jumpmaster`.

## Provider contract

### Registering

```sqf
[_kind, createHashMapFromArray [
    ["assets",    {...}],   // CODE, required
    ["task",      {...}],   // CODE, required
    ["sitrep",    {...}],   // CODE, optional
    ["available", {...}],   // CODE, optional
    ["tasks",     {...}],   // CODE, optional
    ["preview",   {...}],   // CODE, optional (2026-10-20)
    ["overlay",   {...}],   // CODE, optional (2026-10-20)
    ["reach",     {...}],   // CODE, optional (2026-11-01)
    ["side",      {...}],   // CODE, optional (2026-11-01) - server
    ["thread",    {...}],   // CODE, optional (2026-11-01) - server
    ["reply",     {...}],   // CODE, optional (2026-11-01) - server
    ["cardPreview", {...}], // CODE, optional (2026-11-02) - client
    ["types",     [...]]    // ARRAY, optional
]] call jmfsb_support_fnc_registerProvider;   // -> BOOL
```

- **kind** `<STRING>`: non-empty, no `:`. It is the prefix of every asset id the
  provider hands out, and how a request is routed back to it. Kinds in use:
  `cas`, `air` (support_air), `fires` (support_fires), `logi`
  (support_logistics), `jump` (jumpmaster - the jump aircraft, 2026-11-02).
- Call it in **postInit on every machine** (not only the server): the screen is
  drawn on the client and calls the provider's code locally. Registering a kind
  again replaces the earlier declaration.
- A declaration missing `assets` or `task` (or with a non-code value there) is
  refused; an optional key of the wrong type is dropped with an RPT warning.

### Asset id

`"<kind>:<anything>"`, a STRING. Everything after the first `:` is the
provider's own (`cas:3`, `fires:0`, `air:2`). Rows whose
id does not start with `<kind>:` are dropped from the merged list (one RPT
warning per kind). Ids must be stable between polls for the same asset - the
screen keeps the picked id across redraws.

### `assets` - the rows

`[] call assets` -> `ARRAY` of rows. Called on the viewer's machine every two
seconds while the screen is open, so it must be cheap and must answer for the
viewer (`side group player`). A row is:

| # | Field | Type | Meaning |
|---|---|---|---|
| 0 | id | STRING | `"<kind>:..."`, see above |
| 1 | type | STRING | the asset type the row is listed under - a `types` key (`"cas"`, `"transport"`, `"arty"`, ...) |
| 2 | callsign | STRING | the row's name, read back in verdicts ("REAPER 1 ACCEPTED - ...") |
| 3 | platform | STRING | what it is, shown as the row's meta (vehicle display name) |
| 4 | status | STRING | `"idle"` = can be tasked; anything else is shown upper-cased and makes the unit read as busy (arms RTB). The core shows `"cooldown"` over an `"idle"` row whose core cooldown is still running |
| 5 | ordnance | ARRAY | type-specific list the screen steps through: arty `[[name, roundsLeft], ...]`; CAS drones `["AUTO", storeName, ...]`; `[]` (or `""`) for none |
| 6 | guns | NUMBER | artillery tube count for the GUNS stepper, `0` otherwise |
| 7 | vehicle | OBJECT | optional - the airframe for the map marker and the PASSENGERS list; `objNull` or absent for none |
| 8 | plan | ARRAY | optional (2026-10-20) - the task the asset is flying, as `[[pos, label], ...]` in the order it flies them (`[[via, "VIA"], [lz, "LAND"], ...]`). The board's map draws it for every row as Simplex-style task markers joined by a line from the airframe; `[]` or absent for none |
| 9 | stationFirst | BOOL | optional (2026-11-01) - the asset must be asked on station before it strikes (doc 1.1): a message to it opens REQUEST ON STATION (`mailboxes` field 8) until its status reads on station. `support_air` sets it for a fixed-wing CAS aircraft the AI flies; false or absent for any other |

### `task` - executing an order

`[assetId, task, pos, params] call task` -> `[ok, why, cooldown]`

| Arg | Type | Meaning |
|---|---|---|
| assetId | STRING | one of this provider's ids |
| task | STRING | a task token this provider declared, or `"rtb"` (recall) |
| pos | ARRAY | the TARGET point `[x, y, 0]` ATL, `[]` when none was picked (the provider decides what none means - artillery refuses) |
| params | ARRAY | the screen's parameter array, see below |

| Return | Type | Meaning |
|---|---|---|
| ok | BOOL | the order was accepted (sent) |
| why | STRING | refusal reason shown to the player; ignored on accept except by callers other than the screen |
| cooldown | NUMBER | optional - seconds the core holds the asset after an accepted order (`0`/absent: none). Not applied to `"rtb"` |

The call is made **on the requesting machine** by `jmfsb_support_fnc_request`
after the gate, validation, cooldown and `available` checks. A provider whose
work must happen on the server sends it there itself - the core does not move
the call. It sends it by `remoteExecCall` to a function of its own, never by a
CBA event, and that server function takes the requester from the sending
machine (`jmfsb_common_fnc_sender`), re-runs `jmfsb_support_fnc_canTask` for
him, checks the asset is his side's and re-runs the provider's own checks
(review S6). `cas`, `support_fires`, `support_air` and `support_logistics` all do this. Anything other than an array
return is treated as a refusal ("the provider gave no answer").

**`"rtb"`** is always passed through: never blocked by a cooldown or by
`available`, because an asset you want home is by definition busy. A provider
that cannot recall returns `[false, "why"]`.

### The parameter array (`params`)

One array shared by every asset type, written by whoever calls `request` -
the card reader (`readOrder`) on the message path, or a mission script.
Nothing keeps it between orders since TAC//SUPPORT went (2026-11-01). Slots in use - **a new
provider must not reuse them with a different meaning**:

| Slot | Meaning | Written for |
|---|---|---|
| 0-7 | retired 2026-11-02 (were the ALiVE provider's radius, height, ROE, speed, ordnance, rounds, dispersion and guns), left empty | |
| 8 | INGRESS point, `[]` = auto | CAS drones (always written by SEND) |
| 9 | EGRESS point, `[]` = auto | CAS drones (always written by SEND) |
| 10 | store index into row field 5 | CAS drones |
| 11 | retired 2026-11-02 (was the ALiVE provider's ordnance NAME), left empty | |
| 12-19 | support_fires' steppers | support_fires |
| 20-31 | support_air's steppers (28 and 29 retired, left empty; 23 ALTITUDE and 24 HEIGHT retired 2026-11-01, left empty), but 27 | support_air |
| 27 | DROP HEIGHT index (moved with the Logistics Drop, 2026-11-01) | support_logistics |
| 32-35 | DELAY, INTERVAL, REPEAT, COORDINATE | support_fires |
| 36 | ADJUST - the observer's call on an adjust mission (2026-11-01, the ARTY screen's adjust pad): 0 none, 1 adjusting round, 2 fire for effect, 3 end of mission | support_fires |
| 37-39 | free - kept for support_fires | |
| 40-48 | support_air: 40 DANGER CLOSE, 41 retired 2026-11-01 (was LIGHTS), 42 APPROACH, 43 LZ SIGNAL, 44 VIA (a list of points), 45 LZ / SET DOWN (a point), 48 JUMP HEIGHT | support_air |
| 46 | retired (was CONTENTS; a PAC load is a catalog item now), left empty | |
| 47 | MARKING index (was CRATE SIGNAL, same values) | support_logistics |
| 49 | CART - the order as `[[catalog index, count], ...]`; read before 50/51 when it holds a pair (the v2 board's cart) | support_logistics |
| 50 | ITEM - a catalog index (list stepper) | support_logistics |
| 51 | COUNT - how many of ITEM | support_logistics |
| 52+ | free | |

Slots 8 and 9 are also read by support_air's CAS: INGRESS and EGRESS mean the
same on both CAS providers. A point slot (8, 9, 44, 45) holds `[x, y, 0]` or
`[]`; a slot of a point declaration that takes several (`many` > 1) holds an
array of those.

### `sitrep` - the SITREP button

`[assetId] call sitrep` -> `[ok, line]`. One readable line for the IN FLIGHT
card and the notify rail. Optional; without it the core answers `[false, "no report"]`.
The board offers SITREP for every type, artillery included (2026-10-20).

### `preview` - the verdict before SEND (2026-10-20)

`[assetId, task, pos, params] call preview` -> `[ok, line]`. Optional. Asked
through `jmfsb_support_fnc_preview` (same arguments, answers `[]` when the
provider has no preview or gives no line) on the requesting machine **every
time the board redraws** an order whose asset, task, point and required points
are all set, with exactly the `params` SEND would send. Cheap, and it must
change nothing. `line` is shown on the order bar's status line - an ETA,
a time of flight, `OUT OF RANGE` - the way Simplex shows its ETA and verdict
beside its confirm. `ok` false is a verdict against the request: the line reads
as missing and SEND waits until it changes.

### `overlay` - what the picked asset draws on the map (2026-10-20)

`[assetId, row] call overlay` -> ARRAY of shapes. Optional. Asked through
`jmfsb_support_fnc_overlay` (same arguments, answers `[]` without the hook) when
the board draws with that asset picked, in both hosts, in ink under the
request. Shapes of an unknown kind or the wrong shape are dropped by the core:

| Shape | Meaning |
|---|---|
| `["ring", centre, radius, label]` | a circle of `radius` m round `centre` (`[x, y]` or `[x, y, z]`), `label` over its top edge - a battery's min / max range |
| `["line", from, to, label]` | a line, `label` at `to` |
| `["point", at, label]` | a small square with `label` |
| `["round", at, number, landsAt, salvo]` | one round of a fire mission (2026-11-01): where it lands, its number in the mission, when it lands (`CBA_missionTime`), and its salvo - the observer's call it answers, from 1. The ARTY screen's round log and map read it; the board's map draws it for an open thread (2026-11-01, step 8): a salvo in the air as a filled ring with `NAME · SPLASH m:ss`, one down as numbered dots |

### `reach` - who can reach a map point (2026-11-01)

`[assetId, pos] call reach` -> `[can, eta, why, effect, tasks]`. Every
provider gives one; without it the asset is `NOT AVAILABLE`. Asked through **`jmfsb_support_fnc_reach`** `[pos, typesFilter]` (Public), which
answers for every asset the viewer's `assets` lists (`typesFilter` a list of
type keys, `[]` for all) as `[[assetId, can, eta, why, effect, tasks], ...]` -
the map-first board's reach card (docs/DESIGN_SUPPORT_V2.md section 6). Asked on
the viewer's machine **once per target click**, not per frame; cheap anyway,
and it must change nothing. `pos` is the clicked point, `[x, y, z]` ATL.

| Field | Type | Meaning |
|---|---|---|
| can | BOOL | the asset can service the point now |
| eta | NUMBER | seconds until it does, `-1` unknown. The quickest the order can be: no DELAY the player has not set |
| why | STRING | a short reason when `can` is false (`OUT OF RANGE 14/12 KM`, `NO STORES`, `TASKED`), `""` otherwise |
| effect | STRING | one line for the card, plain ASCII (`4 GUNS - HE 24 RDS - SMOKE 12 RDS`) |
| tasks | ARRAY | task tokens (`types` / `tasks` declarations) valid at this point, `[]` when it cannot |

An answer that is not an array of at least five fields counts as none. The core
holds an asset whose core cooldown is running (`COOLDOWN n S`) whatever the
provider answers, and clears `why` and `tasks` to match `can`.

**Without the hook** the asset cannot (`NOT AVAILABLE`). The core's own reading
from `available` and `preview` served only the ALiVE provider and went with it
(user, 2026-11-02).

**Ranking, ETA only** (user, 2026-11-01, D5): `can` first, then the shortest
ETA, an unknown ETA after every known one, then the order `assets` lists them.
Matching the effect to the target comes after `reach` is measured.

Hooks in use: `fires` (range from `gunRanges`, time of flight, rounds left),
`air` (`flightTime` from base or from where the airframe is), `cas` (the
module's run-in), `logi` (delay and the leg in; methods, capacity, catalog
size), `jump` (the jump aircraft).

### `cardPreview` - a card's verdict before SEND (2026-11-02)

`[assetId, order] call cardPreview` -> `[ok, line, specs]`, `[]` for a card it
does not preview. Optional, client. Asked through
**`jmfsb_support_fnc_cardPreview`** `[toLine, cardId, values]` (Public), which
TAC//MSG's composer calls on a change of the card being written to an asset's
box (tacpad `composeFire`), never per frame. The core reads the card's values
the server's way (`readOrder`, on a thread of the player's own) and hands the
order to the provider of the first support box on the TO line. `line` is
shown beside SEND, `ok` false in the accent; `specs` are drawn as local
markers on the player's map by `pinMarker` (`icon`, `ring`, `line` - see "The
thread's map pin"), named `jmfsb_support_pin_cff_<n>`, the last ones removed
each call. Cheap, and it must change nothing: the server reads the card again
when it is filed and answers as it will. Called with no box or no card, or a
provider without the hook, it only clears what it drew.

Hooks in use: `fires` - a call for fire (CFF GRID, POLAR, SHIFT) to a battery:
in range or not, danger close, time of flight, CANTCO and the server's word,
the shape's footprint (support_fires README, "The second artillery build").

### `side`, `thread`, `reply` - acting on a thread (2026-11-01)

Server-side hooks; the asset acts on the thread filed to its box (section
"Acting on the thread" below). They run on the server, where `assets` cannot
(it answers for `player`): each finds its asset by id itself.

| Hook | Arguments -> return | Meaning |
|---|---|---|
| `side` | `[assetId]` -> SIDE | whose asset it is; `sideUnknown` for none. Without it the core cannot check the issuer's side, and a follow-up from anyone but the issuer is held to the issuer's side |
| `thread` | `[assetId, thread, root message, issuer]` -> `[ok, why]` | a TASK card filed to the box. `[true, ""]`: taken - the provider says WILCO and the rest itself, naming the thread (`state` argument 5). `[false, why]`: the core files the CANTCO with `why` and gives the asset back its previous open thread. `[]` (or anything shorter): not this provider's card, the thread stays at RECEIPT |
| `threadCards` | ARRAY, not code: `[[root card id, [card ids]], ...]` | the ROOT cards it takes as a new task inside a thread opened with that root - a re-task, a NEXT LIFT (2026-11-02; section "A card filed into an asset's thread"). Without it no root card goes into its threads |
| `reply` | `[assetId, thread, message, sender, word]` | a follow-up in a thread the asset was given, from the issuer, the card's observer or a man on the FIRES net (D6, below). `word`: `"cleared"` (CLEARED HOT), `"stop"` (CLOSE = EOM, ABORT, RTB), `"adjust"`, `"ffe"`, `"repeat"`, `"checkfire"`, `"confirm"`, `"bda"` (2026-11-01, step 6), `"cold"`, `"hot"`, `"paxoff"`, `"hold"`, `"received"`, `"notfound"`, `"no"`, `"destination"` and `"task"` (a task card filed in the thread - a NEXT LIFT) (step 7), `"go"` (the jump aircraft's hold, 2026-11-02), `"board"` (the leader's BOARD to a jump aircraft on station, 2026-11-02), `"allattack"` (ALL ATTACK, 2026-11-02), `""` anything else. **A hook acts only on the words it knows** - more may be added |

### `available` - can it be tasked now

`[assetId] call available` -> `[ok, why]`. Optional. Asked by the core before
`task` for everything except `"rtb"`; a refusal returns `why` to the player
without calling `task`. Keep it the same rule the row's status uses, so a row
that reads idle is never refused.

### `types` - asset types and their tasks

An ARRAY of type declarations, static data:

```
[type, label, one, many, order, tasks]
```

| # | Field | Type | Meaning |
|---|---|---|---|
| 0 | type | STRING | the key rows use in field 1 |
| 1 | label | STRING | the type's tab label on the screen (`"ARTILLERY"`) - one tab per type that has at least one row |
| 2 | one | STRING | counted noun, singular (`"BATTERY"`) |
| 3 | many | STRING | counted noun, plural (`"BATTERIES"`) |
| 4 | order | NUMBER | list position, ascending. In use: transport 10, CAS 20, artillery 30 |
| 5 | tasks | ARRAY | task declarations, below |

The core merges declarations by type (`jmfsb_support_fnc_types`): the
lowest-order declaration gives label, nouns and order; task lists are united by
token. A type nobody declares is not on the screen, and a row of an undeclared
type is not reachable - **declare every type you list rows under.**

A **task declaration**:

```
[token, label, meta, guidance, steppers, needsPoint, pointLabel, points]
```

| # | Field | Type | Meaning |
|---|---|---|---|
| 0 | token | STRING | what `task` receives. `"rtb"` is reserved |
| 1 | label | STRING | the task's button label on the board's reach card and order bar |
| 2 | meta | STRING | a long name, `""` for none (the old form's row text; the board does not draw it) |
| 3 | guidance | STRING | what the task does, a sentence (the transport screen reads THEN - RTB / LOITER - off it) |
| 4 | steppers | ARRAY | optional - stepper declarations, drawn on the order bar |
| 5 | needsPoint | BOOL | optional - SEND stays unavailable until the point is set |
| 6 | pointLabel | STRING | optional - what the screen calls the task's point (`"LZ"`, `"PICKUP"`, `"DROP POINT"`); `""` or absent reads `TARGET`. The name only: the point still arrives as `task`'s `pos` |
| 7 | points | ARRAY | optional (2026-10-20) - further map points the task carries, one row each after the task point; see below |

A **point declaration** (field 7), picked on the board's map (alt-click, or
right-click for the first required one leaving the target) and written by SEND
into its parameter slot:

```
[label, slot, hint, required, many, leg]
```

| # | Field | Type | Meaning |
|---|---|---|---|
| 0 | label | STRING | the point's name (`"INGRESS"`, `"VIA"`, `"LZ"`) |
| 1 | slot | NUMBER | parameter slot it is written to, 8 or more. 8 and 9 ARE the INGRESS / EGRESS points - a declaration on them shares the point with every other asset that declares them |
| 2 | hint | STRING | what an unset point means (`"AUTO - STRAIGHT THROUGH"`) |
| 3 | required | BOOL | the order bar names it while unset; SEND waits for it |
| 4 | many | NUMBER | optional, default 1 - above 1 every click adds a point (up to `many`, then the last one moves) and the slot holds a list |
| 5 | leg | STRING | optional, default `"out"` - how the map draws it: `"in"` chained into the task point in order (VIA, INGRESS), `"out"` leaving it (EGRESS, an LZ) |

A CAS drone row (kind `cas`) that declares no points still gets INGRESS and
EGRESS, as before.

A **stepper declaration** (drawn two to a line, in order):

```
[label, slot, step, min, max, display, list, bar, aid]
```

| # | Field | Type | Meaning |
|---|---|---|---|
| 0 | label | STRING | micro-label above the box |
| 1 | slot | NUMBER | parameter-array slot it writes (12+ for new providers) |
| 2 | step | NUMBER | added/subtracted per press |
| 3 | min | NUMBER | lower bound, and the value shown while the slot is unset |
| 4 | max | NUMBER | upper bound |
| 5 | display | STRING or ARRAY | `"%1 M"` formats the value; an array of words is indexed by the value (`["LOW", "HIGH"]`) |
| 6 | list | ARRAY | optional - a value list to walk in order instead of stepping (`[4, 1, 2, 3, 0]`), `[]` for a range |
| 7 | bar | BOOL | optional, default true - draw the range bar |
| 8 | aid | ARRAY | optional (2026-10-20) - what the board's map draws for the value, live: `["radius"]` the value is metres round the point (without it, a stepper labelled RADIUS / SHEAF / SEARCH RADIUS is taken as the radius); `["bearing", step]` value 0 is AUTO, value v the bearing `(v - 1) * step` the asset comes in FROM, drawn as a leg into the point; `["ring", metres]` a ring of `metres` round the point while the value is 0 (DANGER CLOSE off) |

### `tasks` - per-asset tasks

`[assetId, row] call tasks` -> task declarations. Optional. When a unit is
picked the screen asks `jmfsb_support_fnc_tasks [type, assetId, row]`: this code
answers if present and non-empty; otherwise the provider's own `types` entry
for that type; otherwise the union for the type. Use it when two assets of one
type offer different tasks (a battery with no smoke, an airframe with no
loiter).

## Requests

`[assetId, task, pos, params] call jmfsb_support_fnc_request` -> `[ok, why]`

1. **Gate** - `jmfsb_support_fnc_canTask [player]`: the *Support tasking tag*
   setting (`jmfsb_support_tag`) through `jmfsb_messaging_fnc_tagMatch`. Empty
   = everyone; a tag that names nobody in the mission fails open (RPT warning).
   Applies to every task, RTB included. The screen asks the same function
   before it opens.
2. **Validate** - asset id and task non-empty; the id's kind is registered; the
   provider's `assets` still lists the id ("that unit is gone").
3. **Cooldown and availability** (not for `"rtb"`) - the core ledger
   (`jmfsb_support_readyAt`, asset id -> mission time, owned and broadcast by the
   server), then the provider's `available`.
4. **Dispatch** - the provider's `task`.
5. **Bookkeeping** - on accept: a returned cooldown is sent to the server by
   `remoteExecCall` to `jmfsb_support_fnc_bookCooldown` and published. The
   server books it only for a sender who passes the gate, for a registered
   provider's id, on its own clock, capped at an hour, and only ever
   lengthening a running cooldown - no client can clear or fake one (review
   S6). The server's ledger is kept in `localNamespace`; the public
   `jmfsb_support_readyAt` is a copy for the screens; `jmfsb_support_tasked`
   `[assetId, task, pos, kind, requester]` is raised as a CBA LOCAL event on
   the requesting machine only (review S7/P8: as a global event any client
   could claim any requester, and nothing else listened). Anything that counts
   sorties, rounds or keeps an AAR does it at the provider's server end, which
   knows the real sender.

Runs where it is called - on the requesting client.

## Acknowledgement

A provider that learns the asset actually took the order (or did not, in
time) calls:

```sqf
[_assetId, _ok, _said, _requester] call jmfsb_support_fnc_ack;
```

which runs the hooks registered with
**`jmfsb_support_fnc_onAck`** `[code]` with `[assetId <STRING>, ok <BOOL>,
said <STRING>]` - locally when `_requester` is omitted, `objNull` or local,
otherwise the server sends it by `remoteExecCall` to `ackLocal` on the
requester's machine, which takes it only from the server. It was the CBA event
`jmfsb_support_ack`, which any client could raise to put a fake receipt on
every board (review R1); `ack` itself drops a remote-executed call, and only
the server forwards to another machine. The hooks live in `localNamespace`.
`jmfsb_tacpad_apps` shows `said` on the notify rail (`ok` false = the
warning colour).

## Threads (2026-11-01)

A support request is a messaging thread, and the thread is its status
(`docs/DESIGN_SUPPORT_V2.md`, section 9). The server answers it **as the
asset**.

**One mailbox per asset** (decision D6): `B:SUPPORT:<assetId>`, the id exactly
as the provider hands it out - `B:SUPPORT:fires:1`, `B:SUPPORT:cas:0`,
`B:SUPPORT:air:2`. File to it from TAC//MSG or a script like any shared
box; a bare `SUPPORT:fires:1` reaches the same box.

```sqf
["callforfire", _answers, ["B:SUPPORT:fires:1"]] call jmfsb_messaging_fnc_submit;
```

When the **root** of a thread is filed to such a box and a provider is
registered for the id's kind, the server (`srvFiled`, a messaging `onFiled`
hook - messaging does not know this addon) makes it the asset's open thread
and answers RECEIPT at once. A newer thread to the same asset replaces the
older one. Since 2026-11-01 the issuer is asked first: he must be on the
server, pass `canTask` and, where the provider has a `side` hook, be of the
asset's side - a thread that fails is not the asset's and is not answered.
The thread then moves:

| State | Means | Who says it |
|---|---|---|
| `RECEIPT` | the asset has the request (ROGER) | the core, `RECEIPT_HOLD` (2 s) after the thread is filed - unless the asset answered inside that (below) |
| `ACCEPTED` | it takes the order (WILCO) | the core, from a provider's `ack` with ok true; `cas` when the server takes the run |
| `IN_PROGRESS` | it is executing (ON TASK) | `support_fires` when a fire mission / strike / launch is under way; `support_air` when the sortie launches; `support_logistics` when the delivery launches; `cas` at the release, or on station for a loiter |
| `CLOSED` | it is done (CLOSE), with what it said | `support_fires` at the mission's end (rounds complete, check fire); `support_air` when the sortie is over or the aircraft is lost; `support_logistics` when every item ordered is down or lost (what was delivered and where); `cas` when the run egresses, is recalled, times out or is shot down after it released |
| `DECLINED` | it cannot (CANTCO), with the reason | the core, from an `ack` with ok false **while nobody has accepted yet**; `support_air` when the sortie never launched or the aircraft was lost before it flew; `support_logistics` when the delivery never launched; `cas` when a run ends before it released or reached station |

Providers call, on the server:

```sqf
[_assetId, "IN_PROGRESS", _said, _callsign] call jmfsb_support_fnc_state;
// a provider answering more than one thread names the one it means (2026-11-01)
[_assetId, "CLOSED", _said, _callsign, false, _threadId] call jmfsb_support_fnc_state;
```

- **Which thread**: the asset's open thread (the last one filed to it),
  unless argument 5 names one - it must be a thread filed to this asset. A
  thread that is over drops its link; the open thread only when it was that
  one.

- **Server only, and quiet** when nobody filed a thread to the asset - the
  usual case, so call it at every natural point without asking first. A
  state at or behind where the thread already is, and anything after the
  thread is CLOSED or DECLINED, is not said.
- **Queued**: the reply is filed the next frame, outside any client's
  `remoteExecCall`. A call made inside one (a provider's server function a
  client reached) moves only a thread that client's player issued, and its
  call sign is not kept.
- **The reply card is picked by its state, never by its id.** The deck is
  mission / PAC data and this addon cannot know what it calls its ROGER. The
  card is the first registered template (registration order) of kind `reply`
  or `both` whose `transitionsTo` is the state, whose `allowedFrom` holds the
  thread's status now and whose `senderMustBe` the issuer meets. No such card:
  one RPT line per state, and that state is not said. `_said` goes in the
  card's first text field when it has one (a CANTCO's reason). Since
  2026-11-01: never one of the issuer's own cards (`clearedhot`, `rtb`,
  `abort`, the `FOLLOW_UP_WORDS` cards - FFE also moves a thread to
  IN_PROGRESS), and when there is something to say, the first fitting card
  that can carry it. Since the report-card review (2026-11-02, decision 8)
  that is messaging's built-in `wilco` and `inprogress`, which carry a DETAIL
  line; `accepted` and `ontask` - the same replies twice - are retired, and a
  deck's copies are skipped (messaging `CARDS_RETIRED`). A WILCO with no text
  line would still answer, without the ETA.
- **ROGER, WILCO is one message** (user, 2026-11-01: "did get 2 messages roger
  wilco which is one message"). `srvFiled` holds the receipt `RECEIPT_HOLD`
  (2 s). An ACCEPTED inside the hold is the only answer, its text `ROGER,
  WILCO - <what it said>` (`ROGER, WILCO - ETA 2:40 - 4 PAX`); a DECLINED is
  the CANTCO alone. The thread is put at RECEIPT first, silently, so a deck
  whose WILCO or CANTCO is allowed only from RECEIPT still takes it - the
  states still only go forward. Any other state inside the hold says the
  ROGER on its own first. A slow asset: ROGER at 2 s, WILCO when it comes.
  Every asset type, one place.
- **Filed as the issuer, under the asset's call sign**: `srvSubmit` with the
  thread's issuer as the unit and the call sign override, so the answer
  arrives unread with a notification. The issuer offline or dead: not filed
  (RPT INFO).
- **The call sign** is `_callsign` when given (a provider knows it server
  side, and it is kept for the asset), else the last one a provider gave,
  else the one the requesting client sent with its accepted order or with a
  message filed to the box (`srvCallsign`, by `remoteExecCall` from `request`
  and `mailboxFiled`, trusted like `bookCooldown`: canTask, a registered kind,
  trimmed and capped at 32), else the asset id upper-cased. `assets` is never
  asked on the server: it answers for `player`, which a dedicated server has
  none of.

## Acting on the thread (2026-11-01)

The asset ACTS on the request thread a player files to its box
(`docs/DESIGN_SUPPORT_MESSAGING.md`, build steps 3 and 4, and 1.1). Built for
CAS - `cas` and `air` (support_air's CAS module) - and,
step 6 (2026-11-01), for artillery by CALL FOR FIRE - `fires` (the virtual
batteries, with adjust fire, SHOT / SPLASH and prompts); and, step 7
(2026-11-01), for TRANSPORT, CASEVAC, AIRDROP, RESUPPLY and QRF - `air`
(transport and QRF modules) and `logi`; not seen in game yet. The `alive`
provider that acted on threads too was removed (user, 2026-11-02).

**The hook.** `srvFiled`, after the RECEIPT, hands a TASK card (a root that
moves the thread into a state; a plain message is not one, a player's box is
never one) to the provider's `thread` hook on the server. The provider
re-runs its own available / range checks and answers `[ok, why]`; a refusal
is the CANTCO, filed by the core. Accepted, the provider files WILCO with
`ETA m:ss` (`etaText`) and the rest of the states itself, naming the thread.

**REQUEST ON STATION is an order to get in the air, never a fire mission**
(user, 2026-11-02: "on station is not a fire mission its just an order to get
in the air"; built, not seen in game). No provider asks it for danger close, a
target, a laser or stores: a fixed-wing launches to its off-map hold and
checks in; a CAS drone or a helicopter launches and loiters over the area (the
issuer when none is given), dark, weapons tight, until a `cas` card. Its WILCO
is `ROGER, WILCO - LAUNCHING - ON STATION IN m:ss` (`stationWilco`). A battery
or a launcher answers it CANTCO `NOT AN AIR ASSET`; the @ mention never opens
it for them (`MAILBOX_TYPES`).

**Follow-ups.** A reply in such a thread goes to `srvFollowUp`, never the
asset's own answers (filed as the issuer under its call sign - `srvFileAs`
keeps their message ids). **Who is listened to** (doc 5.5, D6 decided - user,
2026-11-01):

| Who | How it is known |
|---|---|
| the issuer | the thread's `issuerUid` |
| the observer | a player the root card's Observer line names - his group id (what the composer fills it with, autoFill `ownCallsign`) or his name, upper-case either way (`observer`, `OBSERVER_FIELDS`) |
| anyone on the FIRES net | a player who can read the `FIRES` box or a sub-net of it (`FIRES.arty` ...) by messaging's own read rule (`jmfsb_messaging_fnc_srvBoxesFor`): his role's `nets[]` where the mission gates nets by role, every player where it does not. No `FIRES` shared box in the mission (the Shared mailboxes setting): nobody |

Anyone but the issuer must be of the asset's side (its provider's `side`
hook, else the issuer's - a shared box is readable by every side); everyone
is asked the tasking gate again. The provider's `reply` hook gets the sender
and one word: `cleared` for the `clearedhot` card, `stop` for anything moving
the thread to CLOSED or ABORTED (and the `rtb` / `abort` cards by id where
the deck has them), and since step 6 `adjust`, `ffe`, `repeat`, `checkfire`,
`confirm`, `bda` by their cards (`FOLLOW_UP_WORDS`). **The aircraft releases
only after CLEARED HOT**; without it it holds (prompts are step 5). Since
step 7 also `cold`, `hot`, `paxoff`, `hold`, `received`, `notfound`, `no`,
`destination` by their cards, and `task` for a task card (a root, not a
reply, that moves a thread into a state) filed in the thread - a NEXT LIFT.
Since 2026-11-02 also `allattack` for the `allattack` card (ALL ATTACK: CLEARED
HOT for a fixed-wing flight's jet and its escort drones - support_air's
README), from the same men who may send CLEARED HOT.
Such a card moves the thread back to ISSUED (messaging's own rule for a
transition in a reply), so the asset's WILCO and ON TASK can be said again.

**The asset asks back** (doc 5.4, step 7) - `prompt` `[assetId, threadId,
text, answers, callsign, onEnd]` (Public, server): a `prompt` card (Text.A
what it asks, Answers.A the reply ids offered) in the thread, and D9 (user,
2026-11-01): silent PROMPT_HOLD (180 s) - asked again, `NO RESPONSE -
HOLDING`; silent PROMPT_END (300 s) - `[assetId, threadId] call onEnd`, the
provider's own end (home, the thread closed). Any follow-up `srvFollowUp`
passes on in the thread, a newer prompt, or the thread no longer the asset's
ends the wait. Text `""` starts only the waits (a WILCO that already asked
HOT LZ - CONFIRM). support_fires keeps its own (step 6). Argument 7 (step 5,
2026-11-01) files it FLASH: only AWAITING CLEARED HOT and BINGO are (doc 5.4);
the NO RESPONSE repeat is routine. The priority goes through `fileCard`
argument 5 to messaging's `srvSubmit` argument 10, the server's own call only.

**On the way in** (user, 2026-11-01: "need more information like after rw
inbound eta etc etc and an alert to pop smoke when its close"; built, not seen
in game) - one place for the words, so transport, casevac, airdrop, resupply
and QRF say the same. CAS and fires keep their own milestones.

| Function | Does |
|---|---|
| `inbound` `[assetId, threadId, callsign, aircraft, point, marking, ask, answers, onEnd, near]` (Public, server) | called by the provider's watch every tick of a leg in to a point of the request (support_air `liftTick` and `qrfTick`, support_logistics `inbound`). Every `TRANSPORT_ETA_UPDATE_S` (60 s): the `inbound` card, `ETA m:ss - <grid of the aircraft>`. `ONE_MIN_OUT` (60 s) out, or inside `near` m: `1 MIN OUT - POP SMOKE` - the card's marking words read IR, FLARE (PYRO), CHEMLIGHT or SMOKE, SMOKE without one - as a FLASH `prompt`, folded with `ask` into one message (`1 MIN OUT - POP SMOKE - LZ STATUS?`, its answers and the D9 waits), and the issuer's own popup `<CALLSIGN> 1 MIN OUT - POP SMOKE` (`alertLocal`, the upper-right notifications, taken only from the server). Once per leg; a new point is a new leg. Answers true on the call that said 1 MIN OUT |
| `etaTo` `[aircraft, point]` (Public) | seconds, straight over the ground, at its speed now but never under `ETA_CRUISE_SHARE` of its class's top speed (an aircraft on its stand) nor `ETA_MIN_MS`; -1 unknown. The launch's WHEELS UP `INBOUND - ETA m:ss` reads it |

**The cards the mod carries** (user, 2026-11-01: transport by message waited
for a CONFIRM the deck had no card for; built, not seen in game). **The
mod's own card always wins** (user, 2026-11-02: card changes reach the game
with the mod - nobody runs a script against the database). `builtinCards` is
the one entry point, in the `registerTemplate` shape: the requests - CAS
REQUEST `cas`, AIRFRAME CHECK-IN `checkin`, LIFT REQUEST (HLZ) `hlz`,
EXTRACTION (HLZ) `extract`, PARADROP `airdrop`, REACT/QRF LINK-UP `qrf`, the
JUMP REQUEST `jump`, `bda`, `resupply`, `onstation`; the calls for fire
(`builtinFires`: CFF GRID `callforfire`, CFF POLAR `cffpolar`, CFF SHIFT
`cffshift`); and the replies (`builtinReplies`: `adjust`, `ffe`, `repeat`,
`checkfire`, `record`, `clearedhot`, `allattack` (ALL ATTACK, 2026-11-02),
`shot`, `splash`, `prompt`, `rtb`,
`abort`, `confirm`, `wheelsup`, `wheelsdown`, `cold`, `hot`, `paxoff`,
`hold`, `received`, `notfound`, `no`, the landing's `correct`, `wrong`,
`nosmoke`, `clearedland`, the lift's `allin` and `extractnow`,
`destination`, `in`, `off`, the jump aircraft's `redlight`, `greenlight`,
`stickout`, the leader's `go` and `board`, and `inbound`). The reports and
the replies every thread takes (SALUTE, MIST, TIC, SITREP, CASEVAC, DEFREP,
MESSAGE, ROGER, WILCO, ON TASK, CANTCO, CLOSE) are messaging's built-in
cards and work without this addon; METT-TC and OPORD are PAC's. This addon's
preInit registers its cards on every machine (messaging `registerBuiltins`,
right after messaging's preInit registered the mission config's deck and its
own cards): a mission card of the same id is replaced where it stands. The
TAC//PAC deck arrives later (the server's boot, a client's takeServer): pac
`templatesApply` skips every id the mod carries and every retired one
(`accepted`, `ontask`, `nineline`), adds only the cards the mod does not
have, and one RPT line names the deck cards it skipped. Every machine ends
with the same registry. The root cards answer to the task set
(`BUILTIN_REPLIES`); CAS also CLEARED HOT, the calls for fire
`BUILTIN_CFF_REPLIES`, the lift cards CONFIRM / ABORT / RTB and their own
ALL IN / EXTRACT, the QRF ABORT / RTB, the JUMP REQUEST
`BUILTIN_JUMP_REPLIES`, CHECK-IN the open set. `tools/check_invariants.py`
fails the build when a card id a provider, a prompt's quick replies or the
card reader names (a `CARD` / `CARDS` / `ANSWERS` / `REPLIES` macro) is not
built in.

**The report-card review** (`docs/REVIEW_REPORT_CARDS_2026-11-02.md`, user
decisions 2026-11-02; built, not seen in game) is in the built-in cards: the
BDA's target from the thread (not required), its RESULT required;
RESUPPLY's counts and METHOD optional, the ground-to-air marking list
(`MARKS_GROUND`); the CAS REQUEST's target marks (`MARKS_TARGET`) and no CUR
LOC on its target; ADJUST's other axis; the asset's text line labelled
DETAIL; the CHECK-IN's CAPABILITIES and LASER CODE; the QRF's RECOGNITION
SIGNALS and ACTION ON ARRIVAL pick (`BUILTIN_QRF_ACTIONS`); the PARADROP's
MARKING.

**The decisions of the same day, later** (user, 2026-11-02; built, not seen
in game):

- **CALL FOR FIRE is three cards** ("break arty in to 3 reports grid polar and
  shift fire"). `callforfire` is CFF GRID (its keys kept; the target grid
  required; its polar and shift lines dropped - an older card's are still
  read); `cffpolar` CFF POLAR (Polar.A direction, Polar.B
  distance from the observer - the Observer line's grid, Observer.B, else the
  sender's position); `cffshift` CFF SHIFT (Known.A, a grid or a map marker;
  Lateral, Range, Vertical - a LEFT / RIGHT, ADD / DROP, UP / DOWN word and
  metres, along the observer-target line). The same lines after the target:
  TYPE OF MISSION (required, tick one), description, engagement and rounds,
  DANGER CLOSE (600 m), control and TOT, observer, guns, REMARKS. `FIRE_CARDS`
  reads the three into one kind `fire`, so every battery and launcher
  answers them alike; `OBSERVER_FIELDS`, `MAILBOX_TYPES` (a battery takes all
  three, an @ mention opens CFF GRID) and `PIN_CARDS` name all three.
- **The artillery by message, improved** (user, 2026-11-02; ideas from Tun
  Firesupport by Tuntematon / Armafinland - support_fires README, "Recorded
  targets"). The three cards carry TARGET SHAPE (`Shape`: A point, B area, C
  linear, D creeping, E the size in metres), LINEAR / CREEPING - FAR END OR
  ATTITUDE (`End`: A a grid or marker, B degrees) and METHOD OF FIRE
  (`Method`: A interval s, B volleys, C continuous minutes), all optional; the
  TOT line takes HHMM, HHMMSS or +M. The reply card `record` (RECORD AS
  TARGET, `FOLLOW_UP_WORDS` word `record`, ACCEPTED / IN_PROGRESS) is among
  their replies (`BUILTIN_CFF_REPLIES`).
- **One CAS card** ("CAS REQUEST and CAS 9-line do not need both"): the
  `nineline` card is gone from the built-ins, `STRIKE_CARDS`, `MAILBOX_TYPES`
  and `PIN_CARDS`; a deck's copy is skipped (retired). A player pilot
  is mentioned with CAS REQUEST.
- **REQUEST ON STATION's AREA is a map marker**, required: the field is
  `markerOnly` (messaging `registerTemplate`) - the composer offers the marker
  list alone, and messaging `validate` refuses a typed grid or none with `PICK A
  MAP MARKER FOR THE AREA`. The aircraft takes its station from it (a
  helicopter or a drone loiters over it, a fixed-wing holds off the map nearest
  it).
- **EXTRACTION (HLZ)**, `extract` ("need a pick up version where the pick up
  is the hot zone"): kind `extract` (`EXTRACT_CARDS`), the transport flies the
  landing procedure at the pickup and goes on to the destination or home base
  (support_air README). A transport takes `hlz`, `extract`, `casevac` and
  `airdrop`; its @ mention opens LIFT REQUEST. The pin draws PICKUP and DEST.
- **RESUPPLY's items are picks of the pre-made crates**: each item field is a
  choice with `choicesFrom` `logiCatalog` (`CHOICES_LOGI_CATALOG`) and no
  static choices, so any name passes validation; the composer fills the picks
  from the logistics asset's catalog (support_logistics `catalogNames`, tacpad
  `composeChoices` / `composeDrop`), and the server matches the name to the
  catalog as before.

**The CAS, HLZ and extraction flows** (user, 2026-11-02: "cas: 1) on station
request 2) cas call 3) bda while returning to on station 4) reattack or egress
(reattack back to 3) rinse and repeat. hlz insertion: 1) pick up site (always
safe) 2) troop load, all in ... 3) flight path 4) insertion 5) egress.
extraction: 1) on station 2) extraction 3) troop load, all in 4) egress. the
message templates need to have all the above fields in them"; built, not seen
in game). What the core carries for them:

- **The BDA decides.** The `bda` card's RE-ATTACK line is the DECISION:
  RE-ATTACK (`Reattack.A`, the key the readers had) or EGRESS (`Reattack.B`),
  exclusive, one required. `readOrder` gives `decision` - `BDA_REATTACK`,
  `BDA_EGRESS`, or `""` for an older deck's BDA - beside `reattack`. The
  artillery's BDA carries the same line; `support_fires` does not read it.
- **After the release, one message**: `casPrompt` `"off"` is `OFF - RETURNING
  TO STATION - REQUEST BDA` (answers `bda,cas`) - the `off` card is no longer
  filed by an AI asset. A RE-ATTACK is `RE-ATTACK - <n> <store> LEFT -
  AWAITING CLEARED HOT`, FLASH (`clearedhot,cas,abort`). A new CAS REQUEST in
  the thread re-tasks at either (the `cas` tile).
- **The LIFT REQUEST's flight path** (`LIFT_CARDS`): its ROUTE (Line 6) and
  EGRESS (Line 7) lines are stems whose fields A to D (`ROUTE_POINTS_MAX`) are
  points in order - `readOrder` gives `route` and `egressRoute`, and still
  `ingress` / `egress` (the first of each; an older card's single point).
- **The EXTRACTION** (`EXTRACT_CARDS`): `station` (the STATION marker, optional)
  and `egressRoute` (the EGRESS line, A to D).
- **New reply cards** (built-in): `allin` - ALL IN, the troop load done - and
  `extractnow` - EXTRACT, an extraction called in from its station (FLASH);
  both IN_PROGRESS, both in `FOLLOW_UP_WORDS` (`allin`, `extractnow`); ALL IN
  among the LIFT REQUEST's replies (`BUILTIN_HLZ_REPLIES`), both among the
  EXTRACTION's (`BUILTIN_EXTRACT_REPLIES`).
- **The pin draws the flight path** (`PIN_ROUTES`): one line from the pickup
  through the ROUTE points to the LZ and on through the EGRESS points, each a
  dot `RTE n` / `EGR n`; the EXTRACTION's EGRESS from the HLZ to the
  destination, and its STATION as a point. A kind with routes draws no IN /
  OUT legs.

**The CAS prompts and the BDA** (doc 5.4, step 5, 2026-11-01; built, not seen
in game). One place for the words, so the drones (`cas`) and support_air's CAS
aircraft say the same:

| Function | Does |
|---|---|
| `promptCleared` `[assetId, threadId, callsign, onEnd, waiting, allAttack]` (Public, server) | D9's first wait: PROMPT_CLEARED (60 s) after a strike's WILCO, if the thread is still the asset's and `[assetId, threadId] call waiting` says it still waits - `AWAITING CLEARED HOT`, FLASH, answers `clearedhot,abort` - `clearedhot,allattack,abort` when `allAttack` (a fixed-wing flight with escorts up, 2026-11-02) - then `prompt`'s own 3 / 5 min. A newer call for the thread replaces the wait |
| `casPrompt` `[assetId, threadId, what, values, callsign, onEnd]` (Public, server) | `"in"` the `in` card (the run starts); `"off"` one message, `OFF - RETURNING TO STATION - REQUEST BDA` (answers `bda,cas`; 2026-11-02) - values `[droneHits]` after an ALL ATTACK: `OFF - RETURNING TO STATION - DRONES DESTROYED <n> - REQUEST BDA`; `"reattack"` the BDA said RE-ATTACK: `RE-ATTACK - <n> <store> LEFT - AWAITING CLEARED HOT` (FLASH, `clearedhot,cas,abort`, with `allattack` when values 2 is true; values `[rounds, store, allAttack]`); `"noescorts"` ALL ATTACK with no escort up: `NO ESCORTS - USE CLEARED HOT` (FLASH, `clearedhot,abort`, 2026-11-02); `"tasking"` `<n> MIN ON STATION - FURTHER TASKING?` (`cas,rtb,close`; values `[minutes, why]` - minutes -1 leaves them out, a reason a new card could not be flown goes in front); `"bingo"` `BINGO IN 2 MIN` (`rtb,close`, FLASH) |
| `threadBda` `[threadId]` (Public, server) | the last BDA filed in the thread, kept on the thread record (`THREAD_BDA`) by `srvFollowUp` before the provider's hook hears it: `readOrder`'s kind `bda` with `from` and `at`; empty for none |

The providers' sides (who answers what, BINGO's source, where the re-attack
goes): `cas` and `support_air` READMEs. A new `cas` card filed
in the thread (the answer `cas` to FURTHER TASKING?) reaches the `reply` hook
as `task`, like a NEXT LIFT.

**Circle, verify the mark, cleared to land** (user, 2026-11-02: "support
trans needs to circle till smoke is verified, caller pops smoke helo verifies
color, either way transport needs final permission to land"; built, not seen
in game). The provider circles its landing point and calls `lzClear` once;
the core runs the wait in the thread, as the asset, and calls the provider
back when it may land. support_air's transports and QRF air assaults use it.

| Function | Does |
|---|---|
| `lzClear` `[assetId, threadId, callsign, aircraft, point, marking, onCleared, onEnd]` (Public, server) | starts the wait (a second call for the thread starts it again). Every 2 s (`lzClearTick`) it looks within 150 m of the point (`lzMarks`): smoke always, and an IR strobe, chemlight or flare when the card's marking asks for one (`popWord`, the 1 MIN OUT alert's word). Seen: `I SEE RED SMOKE` (`IR STROBE`, `GREEN CHEMLIGHT`, `FLARE`), FLASH, answers `correct,wrong`. None for 45 s: `CIRCLING - NO SMOKE SEEN - POP SMOKE` (routine, once; after a WRONG once more), answer `nosmoke`. Verified or skipped: `READY TO LAND - CLEARED?`, FLASH, answers `clearedland,hold,abort`. CLEARED TO LAND: `[assetId, threadId, point] call onCleared` - the mark, or the point after NO SMOKE. D9 on every prompt (`prompt`, `onEnd`). Over with the thread, the asset's link or the aircraft |
| `lzClearReply` `[threadId, word]` (server) | `srvFollowUp` asks it before the provider's hook: CORRECT, WRONG (that mark ignored, it looks again), NO SMOKE, CLEARED TO LAND, and a HOLD to READY TO LAND (asked again 30 s later) are taken here - the provider is not told; a stop ends the wait and goes on to the provider (ABORT: home) |
| `lzMarks` `[point, kinds, ignored]` (server) | the nearest mark: `[object, "RED SMOKE"]`, `[]` none. Each object is told apart in `MARK_KINDS` order (an IR strobe or a chemlight may be a `SmokeShell` to the engine) |
| `markColour` `[object, smoke]` | the colour word from the class or a parent's name (`SmokeShellRed` RED, `G_40mm_SmokeGreen` GREEN); a smoke with none is WHITE when its `smokeColor` is white or it has none (`SmokeShell`), else none is said |
| `popWord` `[marking]` (Public) | IR, FLARE, CHEMLIGHT or SMOKE from a card's marking words |

The cards `correct`, `wrong`, `nosmoke` (NO SMOKE - LAND ON THE GRID) and
`clearedland` (FLASH) are built in (`builtinReplies`);
`hold` and `abort` are reused.

**The card reader** every CAS provider shares, server side:

| Function | Answers |
|---|---|
| `readOrder` `[thread, message]` | the order as a HASHMAP. `cas` (the one CAS card since 2026-11-02): kind `strike`, `target` / `ingress` / `egress` (positions, `[]` none), `label`, `description`, `friendlies` (m, -1 none), `dcTick`, `dangerClose` (the card's option, else 300 m), `mark`, `code`, `munition`, `remarks`. `onstation`: kind `station`, `minutes` (0 = the aircraft's own), `area` (the AREA marker's point - required since 2026-11-02), `remarks`. `callforfire` CFF GRID, `cffpolar` CFF POLAR and `cffshift` CFF SHIFT (step 6; three cards since 2026-11-02, `FIRE_CARDS`): kind `fire`, `mission` (`adjust` / `ffe` / `suppress` / `immediate`, Warno 1), `guns` (Warno 2's first number, 0 all), `target` with `method` - `grid` (Warno 3A), `polar` (CFF POLAR's Polar line; an older CFF GRID's Warno 3B, or no grid and a Target 2 distance: the direction and distance from the observer) or `shift` (CFF SHIFT's Lateral LEFT / RIGHT and Range ADD / DROP metres from its Known point; an older CFF GRID's Target 3 filled or Warno 3C tick, from the Warno 3A grid - on the observer-target line; `known`; `vertical` - UP / DOWN m, up positive; support_fires lays the guns for the known point's height plus it), `observer` / `observerName` / `observerPos` (the card's Observer, else the issuer; where he is - the Observer line's grid when given, else the sender's position, or the named observer's when the line names another man), `description`, `shell` (Engagement A-F: `HE`, `SMOKE`, `ILLUM`, `CLUSTER`, `GUIDED`, `AIRBURST`), `rounds` (its number, -1 none), `dcTick` / `friendlies` (Danger Close), `dangerClose` (the card's option, else 600 m - D5), `control` (Control A-F: `ready`, `command`, `tot`, `cannot`, `checkfire`, `again`), `tot` (text), `remarks`; since 2026-11-02 (TARGET SHAPE, METHOD OF FIRE) `shape` (the Shape line's tick, `FIRE_SHAPES`: `point` / `area` / `linear` / `creeping`, `""` none), `size` (Shape.E, m, -1 none), `end` (End.A, a line's or a walk's far end, `[]` none), `attitude` (End.B, deg, -1 none), `interval` / `volleys` / `continuous` (Method.A-C: s, volleys, min; -1 none) - an older deck without the lines reads a point, fired once. The observer's replies: `adjust` - kind `adjust`, `direction`, `distance`, `corrections` (every `[direction, metres]` on the card, the other axis second - 2026-11-02); `ffe` - kind `ffe`, `rounds`. Step 7: `hlz` - kind `lift`, `pickup` (the Pickup line, D4), `lz` (Line 1, else Line 2 as a marker), `lzName`, `carry` (Line 3), `security` (Line 4, `lzSecurity`), `marking` (Line 5's words), `ingress` / `egress` (Lines 6 / 7), `wind`, `obstacles`, `remarks`, `insert` (the INSERTION tick, `INSERT_METHODS`: `land` / `rope` / `rappel`, none - `land`; 2026-11-08); `casevac` - the 6-LINE CASEVAC (user, 2026-11-02: "the 6-line only"), kind `casevac`, `pickup`, `patients` (Line 2, or Line 3's sum when more; Line 2 may be empty), `urgent` / `priority` / `routine`, `security`, `marking` (Line 5), `remarks`; `airdrop` - the PARADROP since the review (2026-11-02), kind `drop`, `point` (Line 1), `contents` (who or what jumps), `marking` (the Marking line), `ingress` / `egress`, `remarks`; `resupply` - kind `supply`, `items` (`[[name, count], ...]`, Item 1-9, count 1 when empty), `point`, `method`, `marking`, `colour`, `remarks`; `qrf` - kind `qrf`, `linkup` (Line 2), `who`, `route`, `attachments`, `action`, `remarks`; `extract` - EXTRACTION (HLZ), 2026-11-02, kind `extract`, `pickup` (the PICKUP HLZ; no destination since 2026-11-08 - it hovers there and goes home), `passengers` (-1 none), `security` (LZ SECURITY, `lzSecurity`), `marking`, `wind`, `obstacles`, `remarks`; `destination` / `freetext` - kind `destination`, `point`, `default` (an empty destination, or a message saying DEFAULT), `text`. Step 5: `bda` - kind `bda`, `target` (the TARGET grid, `[]` none), `targetText`, `effect` (Result, upper-cased), `count` (-1 none), `reattack` (the RE-ATTACK tick), `remarks`. Field keys are line titles (`STRIKE_CARDS`, `STATION_CARDS`, `FIRE_CARDS`, `ADJUST_CARDS`, `FFE_CARDS`, `LIFT_CARDS`, `CASEVAC_CARDS`, `DROP_CARDS`, `SUPPLY_CARDS`, `QRF_CARDS`, `EXTRACT_CARDS`, `DESTINATION_CARDS`, `BDA_CARDS` in `script_component.hpp`; a fire card's lines by their letters); on a strike card a REMARKS saying DANGER CLOSE still counts as the tick |
| `medicalNearest` `[pos]` (Public) | server, step 7: a CASEVAC's DEFAULT destination - the nearest mission object marked an ACE medical facility (`ace_medical_isMedicalFacility` on it or its class: the JMSB field hospital), else the nearest terrain HOSPITAL object; `[position, "FIELD HOSPITAL" / "HOSPITAL"]`, `[]` for none |
| `observer` `[thread, root message]` (Public) | server, step 6: `[text, players]` - the Observer line's text and the players it names (group id or name, leaders first); `["", []]` for a card without one |
| `gridPos` `[value]` (Public) | a grid field as `[x, y, 0]`: a position, a 6 / 8 / 10 figure grid typed with or without spaces (read on this terrain by `jmfsb_maptools_fnc_gridToPos`), or a marker name; `[]` otherwise |
| `dangerClose` `[order, side]` (Public) | doc 5.3: the side's units round the target under the threshold, or the card's own Line 6 range under it, without the DC tick: `[false, "DANGER CLOSE NOT ACKNOWLEDGED", nearest m]` |
| `etaText` `[seconds, word]` (Public) | `"ETA m:ss"`, `""` unknown; `word` stands for ETA (2026-11-02) |
| `stationWilco` `[seconds]` (Public) | REQUEST ON STATION's WILCO (2026-11-02): `"LAUNCHING - ON STATION IN m:ss"`, `"LAUNCHING"` unknown |
| `fileCard` `[assetId, threadId, cardId, payload, callsign, priority]` (Public) | server: files a card of the provider's own in a thread filed to its asset, as the asset, queued like `state` - the check-in (`checkIn`), Line 1 the asset's call sign. `priority` (step 5) `"high"` files it FLASH, `""` the card's own |
| `checkIn` `[assetId, threadId, aircraft, callsign, station, altitude, minutes, remarks]` (Public, server) | the AIRFRAME CHECK-IN (user, 2026-11-02: "an aircraft when it arrives on station needs to send an AIRFRAME CHECK-IN"; built, not seen in game). The provider calls it once, when its aircraft gets on station; it files the deck's `checkin` card through `fileCard`, as the asset: Line 1 the call sign; Line 2 `1x <display name>`; Line 3 the station (`[]` leaves it out) at `altitude` m (-1 its own height now); Line 4 the rounds left (`ordnanceLeft`); Line 5 `minutes` left, a number (-1 left out); Line 6 a new four-figure abort code, returned; CAPABILITIES the ticks the airframe has (`airframeCaps`), found by their prefix on the card's Capabilities line; LASER CODE with a designator aboard - ACE's `ace_laser_code` on the airframe, else 1111; Line 7 `remarks`. Only the keys the registered card has: the seeded card without Capabilities / Laser takes the rest. Callers: support_air's CAS, the CAS drones |
| `airframeCaps` `[aircraft]` | the CAPABILITIES ticks as `FMV` / `LASER` / `IR` / `NVG` -> bool: FMV a targeting pod (`pilotCamera`), a drone or a turret with optics; LASER a weapon in any seat whose magazine's ammunition is the engine's laser (`laserDesignate`); IR thermal (`Ti`) and NVG night vision in the pod's or a turret's `visionMode[]` |
| `ordnanceLeft` `[aircraft]` | Line 4: `"GBU-12 x2, 20mm x450"` - live rounds of every magazine aboard, pylons included, whose ammunition can hit the ground (`ORDNANCE_RANK`, heaviest first; air-to-air only left out), short names; `NONE` |

**CANTCO words** (doc 5.2) the providers answer with: `NO TARGET LOCATION`,
`DANGER CLOSE NOT ACKNOWLEDGED`, `NO STORES`, `CANNOT LASE <code>`, `TASKED`,
`RTB`, `NOT ON STATION`, `LOST`, and the reach card's own (`COOLDOWN n S`,
`EXPENDED`, `OUT OF RANGE n/max KM`). Artillery's (step 6): `NO STORES
<shell>`, `TOO CLOSE n/min KM`, `NO FIRING SOLUTION`, `NO TOT`, `CANNOT MAKE
TOT`, `NOT AN AIR ASSET` (a REQUEST ON STATION, 2026-11-02). Step 7: `HOT LZ NOT ACKNOWLEDGED`, `CANNOT PARADROP`,
`NO STORES <ITEM>`, `NO <METHOD>`.

Per provider: `addons/cas/README.md` (drones), `addons/support_air/README.md`
(CAS module, the on-station flow; transport and QRF by message),
`addons/support_fires/README.md` (call for fire: the field-to-fire mapping,
the thread, the prompts), `addons/support_logistics/README.md` (resupply and
airdrop by message), `addons/jumpmaster/README.md` (the jump aircraft). The guard that
took a card filed with a `request` order from the same man in the last 10 s
for the TAC//SUPPORT board's own (transport, QRF, logistics `thread` hooks)
went with the board (2026-11-02): nothing files a card and sends an order
together now.

## A card filed into an asset's thread (2026-11-02)

Built, not seen in game. `srvThreadCard` is messaging's `onThreadCard` hook
(registered in `XEH_postInit`, server): messaging asks it about a player's
card filed into a thread that is already open, before its own sender checks.

- **A new task in the thread.** A ROOT card the thread's asset takes there -
  the provider's `threadCards` for the thread's root card (`threadCards`
  function, both machines) - is taken (`"take"`) from the thread's issuer;
  from anyone else it is refused `only the issuer may send <CARD> into this
  thread`. Messaging then files it as a message in the thread (its
  `transitionsTo` moves the thread back to ISSUED), and `srvFollowUp` hands it
  to the provider as `"task"`: a new CAS REQUEST answering FURTHER TASKING?
  (support_air `casRetask`, the CAS drones), a NEXT LIFT answering
  HOLD, RTB OR NEXT LIFT? (support_air `liftReply`) - a fresh WILCO in the
  same thread. Any other root card is left to messaging, which refuses it.
- **The asset's states are the asset's.** A card moving the thread to
  RECEIPT, ACCEPTED, IN_PROGRESS or DECLINED (`THREAD_ASSET_STATES`: ROGER,
  WILCO, ON TASK, CANTCO) that is not one of the issuer's calls (`assetCard`:
  FFE also moves a fire mission to IN_PROGRESS and is the observer's;
  CLEARED HOT, the stops and the follow-up words are never the asset's) is refused from every player in a thread an asset
  answers, and from the issuer of a support card (`MAILBOX_TYPES`' cards) in
  his own thread to a player crew: `<CARD> is the asset's to send`. The
  asset files its states itself, as the issuer under its call sign
  (`srvFileAs`, the server's own call), which messaging never puts to the hook.

| Provider | `threadCards` |
|---|---|
| support_air (`air`) | `cas` -> `cas`; `hlz`, `extract`, `casevac`, `airdrop` -> any of the four |
| CAS drones (`cas`) | `cas` -> `cas` |

TAC//MSG offers the same cards to the issuer (tacpad `threadLegal`): on
+ TEMPLATE in the thread, and as the tile of an asset's question that names
one (`cas,rtb,close`; `hold,rtb,hlz`).

## The message templates (2026-11-09)

From `docs/DESIGN_MESSAGE_TEMPLATES.md` and `DESIGN_MESSAGE_TREES.html`. Built,
not seen in game.

**One thread per asset.** Each starter filed in it is the next tasking:
`srvThreadCard` takes a root card the asset flies after the thread's
*current* order (`threadOrder`), not only its first card. A support starter
filed in a TIC, SALUTE or MIST thread (`REPORT_HOSTS`) is taken from anyone
the thread reaches; `srvFiled` hands it to `srvTake`, the same path a root
filed to the asset's box takes, and the request's sender becomes the man the
asset takes orders from in that thread (`threadIssuers`).

**The words a provider hears**, besides the old ones:

| word | card | meaning |
|---|---|---|
| `abort` | ABORT | stop now; on a landing do not complete it, on a CAS run abort the pass; then ask intentions (`askIntentions`). No longer a stop: RTB is |
| `move` | MOVE | go to a point, then LOITER / LAND / HOVER / HOLD (readOrder kind `move`). Replaces DESTINATION |
| `confirm` | EXECUTE | CONFIRM is retired; EXECUTE is told as `confirm`, so a hot LZ, AT MY COMMAND and a drop are unchanged |
| `nodrop` | NO DROP | do not drop; another pass or await orders |
| `clearedengage` | CLEARED TO ENGAGE | Type 3 control |
| `continue` | CONTINUE | keep the attack run, no release |
| `escort` | ESCORT | drone escorts up now, or with the aircraft when it launches (support_air `escortCall`), any phase |
| `frago` | FRAGO | the message handed over is the current order with the FRAGO laid over it; the FRAGO itself is under `frago` |

`status` (STATUS) is answered by the core with a STATUS REPLY
(`statusReply`), from the provider's optional `status` hook. `continueapproach`
and `goaround` are the landing wait's (`lzClearReply`): CONTINUE APPROACH
asks again later, GO AROUND circles and looks for the mark again.

**Cards.** The commands carry `assetThread` and `roots` (`ROOTS_*`), the
answers `answerOnly`, the asset's calls `assetOnly` - `assetCard` refuses an
`assetOnly` card from a player. CAS REQUEST is the true 9-line (`STRIKE_CARDS`
- target line 6, IP line 1, egress line 9, plus TYPE OF CONTROL and TOT). The
BDA decision has three picks: RE-ATTACK, BACK TO STATION, RTB.

## Assets as mailboxes (2026-11-01)

The JTAC requests support by messaging the asset in TAC//MSG
(`docs/DESIGN_SUPPORT_MESSAGING.md`, build step 2). The TO picker lists the
assets in a SUPPORT group; three client calls serve it. Built for CAS (user,
2026-11-01); not seen in game yet.

| Function | Answers |
|---|---|
| `mailboxes` `[pos, cardId]` | `[forCard, rows]`: one row per asset of a type `MAILBOX_TYPES` lists, then the player crews (D8, below), as `[boxId, callsign, type, word, state, can, why, eta, card, vehicle, takes]`. `state` is the row's status through `MAILBOX_STATES` (IDLE, ON STATION, REARMING, RTB, LOST; anything else TASKED). `card` is the deck card an @ mention of the asset opens in the composer: its type's, or `onstation` for an asset whose row sets `stationFirst` (field 9) while it is not ON STATION. `takes` (2026-11-02) is the cards it answers now - its type's, `onstation` alone in that case; a card the composer already holds that is in it is kept on the mention. `can` / `why` / `eta` are `reach` at `pos`; with `pos` `[]` (no GPS fix) the row can when idle and has no ETA. `vehicle` is a player crew's vehicle, and for an asset of a `MAILBOX_STOCK_TYPES` type (a battery, 2026-11-02) its stock in brief from its row's field 5 - `12 HE, 6 SMOKE`, the first three types, UNL for unlimited - which the TO picker reads after the state. `forCard` true when `cardId` is a card `MAILBOX_TYPES` names: the rows are then its types only. Not gated: the caller asks `canTask` |
| `boxName` `[boxId]` | the call sign a `B:SUPPORT:<assetId>` box (or its bare name) reads as, from the viewer's rows, read at most every 2 s and remembered; the asset id upper-cased when no row named it; `""` for any other box |
| `mailboxFiled` `[addressees]` | before a root is filed: sends each support box's call sign to the server (`srvCallsign`), so the receipt and the states come under it. Returns how many it sent |

**Why the call sign is worked out on the client.** The box record's
`displayName` never reaches a client - an index row carries only the box id -
and the server cannot ask `assets`. Every reader resolves the box id through
`boxName` locally instead: the TO line, the rail, a thread's header, the FLASH
banner, the list's filter and the docked reader's net chips.

**Adding a type** is one entry in `MAILBOX_TYPES` (`script_component.hpp`):
`[type key, the word the row reads, the cards that open the picker on it,
the card an @ mention opens]`. Every type is listed since the @ mentions
(user, 2026-11-01). A CAS row on station reads ON STATION (2026-11-01).

| Type | Row reads | Picker opens on it for | @ mention opens |
|---|---|---|---|
| `cas` | CAS | `cas`, `onstation` (one CAS card, 2026-11-02 - the 9-line is gone) | `cas` (a player pilot too); `onstation` for a fixed-wing the AI flies that is not on station. An `onstation` already being written is kept (user, 2026-11-02: REQUEST ON STATION, then @HAWK, went as HAWK's `cas` - a strike) |
| `arty` | ARTY | `callforfire`, `cffpolar`, `cffshift` (2026-11-02) | `callforfire` (CFF GRID); a POLAR or SHIFT already being written is kept |
| `cruise` | CRUISE | `callforfire`, `cffpolar`, `cffshift` | `callforfire` |
| `loiter` | LOITER | `callforfire`, `cffpolar`, `cffshift` | `callforfire` |
| `transport` | TRANS | `pickup`, `hlz` (PICKUP and INSERTION split, 2026-11-08), `extract` (2026-11-02), `casevac`, `airdrop` (the PARADROP, 2026-11-02) | `pickup` (PICKUP); an EXTRACTION already being written is kept |
| `logistics` | LOGI | `resupply` (supplies by air are its METHOD AIRDROP, 2026-11-02) | `resupply` |
| `qrf` | QRF | `qrf` | `qrf` |
| `jump` | JUMP | `jump` (2026-11-02) | `jump` (JUMP REQUEST). jumpmaster lists the row to squad leaders and admins only |

**The jump by message** (user, 2026-11-02: "change the halo/haho/static app
in to a message based one"; built, not seen in game). The JUMPMASTER app is
gone; the jump aircraft is provider `jump` (`addons/jumpmaster`, its README
has the workflow). `readOrder` reads the JUMP REQUEST (`JUMP_CARDS`, kind
`jump`: `type`, `passes`, `exit`, `red`, `green`, `pickup`, `remarks`); the
pin draws GREEN LIGHT, RED LIGHT and PICKUP (`PIN_POINTS`); `FOLLOW_UP_WORDS`
passes the leader's GO as `go`.

**Player crews are listed too** (decision D8, user 2026-11-01; built, not
seen in game). After the assets, `mailboxes` lists every player of the
viewer's side in a crew seat - pilot, gunner, commander, a crew turret; not
a passenger or a firing-from-vehicle seat, and not a parachute - of a gun or
an aircraft, under the type his vehicle is (`MAILBOX_PLAYER_*`):

| His vehicle | Listed as |
|---|---|
| has an artillery computer (`artilleryScanner`) | ARTY |
| an aircraft with seats to carry (`transportSoldier` > 0) | TRANS |
| any other aircraft | CAS |

His row is his own player box `P:<uid>`, his name, state PLAYER, no ETA,
`can` true, the type's card, and his vehicle's name as field 9 (`CAS -
PLAYER - AH-64D APACHE`). A thread to it reaches him like any message to a
man; no provider acts on a player box. A card's narrowing applies: a `cas`
card lists the CAS assets and the CAS crews.

Every type acts on its thread since step 7 (2026-11-01; `thread` hooks:
`cas`, `air` - CAS, transport, QRF -, `fires` artillery, `logi`, `jump`).
Cruise missiles and loitering munitions
(`fires`) act on their `callforfire` card since 2026-11-01 (support_fires
README).

## The thread's map pin (2026-11-01)

A support thread's pin also draws the request
(`docs/DESIGN_SUPPORT_MESSAGING.md` 6.3, build step 8; user, 2026-11-01:
"per the doc i want to use the messaging system to call ai support"). Built,
not seen in game. A point within 25 m of a map marker already there (the one
it was picked from) is not drawn on top of it (user, 2026-11-02). Local markers, as the thread's own pin is (messaging
`cltMarker`), so the game map and the tablet's map draw them alike - no map
layer of its own. Client only.

**Which threads.** One whose card is a support card - `cas`, `onstation`,
`callforfire`, `cffpolar`, `cffshift`, `hlz`, `extract`, `casevac`,
`airdrop`, `resupply`, `qrf`, `jump` (`PIN_CARDS`, 2026-11-02) - held for a man the card was pushed to with its body (the
issuer, the box's members, a man tagged in it: the people the plain pin
marks) as it arrives (messaging `onReceive`), and for a man who opened the
thread (messaging's cache). Filed to `B:SUPPORT:<assetId>`, the asset is
known and its shapes draw while it works; to a player crew's box, the card
alone. A newer support card in the thread (a NEXT LIFT, a new strike)
replaces it. A man who joins later sees it once he opens the thread.

**What it draws** (`pinCard`, from `readOrder` - read once, on the client):

| Card | Points | Legs |
|---|---|---|
| `cas` | TARGET (the map reference line left the card in the review; an older deck's is still read as its name) | ingress / egress |
| `callforfire`, `cffpolar`, `cffshift` | TARGET (the grid, the polar or the shift point the reader worked out) | |
| `onstation` | STATION (Line 2, the AREA marker) | |
| `hlz` | LZ with its name, PICKUP | the flight path (2026-11-02, `PIN_ROUTES`): PICKUP - ROUTE points (`RTE 1`-`4`) - LZ - EGRESS points (`EGR 1`-`4`) |
| `extract` | PICKUP, STATION (2026-11-02) | PICKUP - EGRESS points (`EGR 1`-`4`) |
| `casevac` | PICKUP | |
| `airdrop` | DZ | ingress / egress |
| `resupply` | DELIVERY | |
| `qrf` | LINK-UP | |
| `jump` | GREEN LIGHT, RED LIGHT, PICKUP (2026-11-02; the run as flown is the row's plan while ON TASK) | |

Each point reads the asset's call sign, the word and its name on the card
(`HOG TARGET OBJ RAVEN`); a leg is a line from the card's point to the first
point, IN / OUT at its end. **Danger close**: a red ring of the card's
distance (its `dangerClose` option, else 300 m CAS, 600 m artillery) round
the target, only while a friendly the blue force tracker shows
(`jmfsb_bft_fnc_friendlies`; the side's players without BFT) is inside it,
read `DANGER CLOSE 300 M - FRIENDLY 120 M`.

**While IN_PROGRESS** (`pinLive`): the asset's `overlay` (rings, lines and
points in ink with their labels), its fire mission's rounds by salvo - a salvo
in the air a filled red ring round where it lands, `STEEL - SPLASH 0:12` to
its next round; one down a red dot per round, the first numbered with its
salvo - and its route, the row's plan (field 8) joined from the airframe
(field 7) while it flies.

**Colours.** Markers take `CfgMarkerColors` classes, not the tablet's RGBA
tokens: ink is `ColorBlack`, the fixed status red (danger close, impacts)
`ColorRed`.

**Cadence.** `pinTick`, every 2 s (`PIN_POLL`), never per frame: the asset
rows are asked only while a thread is IN_PROGRESS, the friendlies only while
a card has a danger-close distance, and only a marker whose spec changed is
drawn again (`pinMarker`). The countdown moves with the poll. **The end**: a
thread CLOSED, DECLINED or ABORTED, or gone from the index, loses its shapes;
the plain pin it carries (a thread the sender pinned) stays, as for every
thread.

## The active LZs and DZs (2026-11-02)

User, 2026-11-02: "in AiTR lz and drop zones need to be highlighted". Built,
not seen in game. The server keeps, per thread, the zones open on the ground
for it, and sends each side its own; every player's AiTR draws them
(`jmfsb_ecoti`, "LZs and DZs").

**The provider's call** (server): `[threadId, zones, side] call
jmfsb_support_fnc_zones`. `zones` is what is open now, replacing the last list;
`[]` is none. Each zone is `[kind, centre, call sign, radius]` (radius optional,
0 = the kind's own). `side` is the issuer's (`side group _issuer`, D59).

| Kind | Label | Radius | Set by | Open from - until |
|---|---|---|---|---|
| `pickup` | LZ PICKUP | 50 | support_air, LIFT REQUEST | WILCO - it lifts from the pickup (ALL IN) |
| `insert` | LZ INSERT | 50 | support_air, LIFT REQUEST | WILCO - PAX OFF |
| `extract` | LZ EXTRACT | 50 | support_air, EXTRACTION | WILCO - it lifts from the HLZ |
| `dest` | LZ DEST | 50 | support_air, EXTRACTION destination; CASEVAC destination | WILCO (CASEVAC: the destination given) - PAX OFF / the end |
| `casevac` | LZ CASEVAC | 50 | support_air, CASEVAC | WILCO - the destination given |
| `para` | DZ PARA | 150 | support_air, PARADROP | WILCO - the receipt (thread closed) |
| `qrf`, `qrfdrop` | LZ QRF, DZ QRF | 50, 150 | support_air, QRF (air assault, static line) | WILCO - the squad is down |
| `halo`, `haho`, `static` | DZ HALO ... | 300, 300, 150 | jumpmaster, the green light | WILCO - every jumper down |
| `release` | DZ RELEASE | 100 | jumpmaster, the green light as flown, when the wind moved it | as the DZ |
| `resupply`, `sling` | DROP RESUPPLY, DROP SLING | 100 | support_logistics, the delivery point | WILCO - the receipt (thread closed) |

**Removed** by the provider at the end of the leg, and by the core whenever the
thread ends (`srvReply`: CLOSED, DECLINED, ABORTED - also when the issuer is
gone). A thread gone from messaging or over whose zones were never cleared is
swept the next time anything is sent. **Held** (`zonesHold`): a jump's thread
closes as the aircraft leaves the DZ; its zones stay until every jumper is
alive under 3 m or dead, 15 min at most.

**Published** (`zonesPublish`): the side's whole list, only when it changed, by
`remoteExecCall` to every machine with one JIP id per side
(`jmfsb_support_zones_<SIDE>`) - the support_fires `mark` pattern. Each client
(`zonesLocal`, server only, waits for its unit) keeps only its own side's, in
`localNamespace` (`jmfsb_support_zonesSeen`, `[side, [[kind, centre ATL,
radius, call sign, thread]...]]`). The server's own copy is `localNamespace`
too; no client can write either.

## Without ALiVE

Support by message works whenever this addon is loaded, and works the same
with or without ALiVE (user, 2026-11-02: "if alive is present we integrate -
but not the support"). TAC//MSG's SUPPORT group lists what the mod's own
providers declare (CAS drones, support_fires, support_air, support_logistics,
jumpmaster); ALiVE's NEO combat support and ATO are never listed. Where ALiVE
is loaded the providers only ask the adapter to leave their aircraft and
crews unprofiled (`profileIgnore`).

## Tactical flight (2026-11-01)

Every support aircraft of every provider, on every task (user, 2026-11-01:
"with support aircraft all actions need to be tactical lights only over the
airfield that start at in the fiels no lights stealth as much as
possiable"; "nap of the earth for helos"; "loiter or on station needs to be
8k meters off map, atack alt need to be 4k m atl"; "make sure to add alt for
helos that have a sling load"). The rule lives here; the core still knows no
asset kind - it is handed a vehicle and a point.

**Lights** - `[vehicle, airfield] call jmfsb_support_fnc_tactical` (server),
once per aircraft, from its spawn until it is deleted or lost. The airfield
is where it started on the ground (module, base, stand); `[]` for one made
in the air at a distance. One watch for every provider
(`tacticalTick`, every 3 s) runs `tacticalLights` per aircraft:

- within 1500 m (2D) of the airfield: the AI's own lights, collision lights
  on;
- anywhere else: collision lights, the landing light and every turret
  searchlight off, and `disableAI "LIGHTS"` on the crew (cargo is not
  crew), so a SAFE or CARELESS crew does not light up at night. Given back
  over the airfield.
- only where the aircraft is local (the server for every provider's crew); a
  player at the controls owns his own lights.

**Height** (m above the terrain, `flyInHeight`):

| | Transit | On station | Attack |
|---|---|---|---|
| Helicopter | 30, nap of the earth | 30, over the point | 30 |
| Helicopter, load on the hook | 30 + rope + load height + 10 (60 when the rope cannot be read) | | |
| Fixed-wing | 4000 | 4000, 8 km off the map | 4000 |

- `[vehicle or class, phase] call jmfsb_support_fnc_flightHeight` -> m;
  phase `"transit"`, `"station"` or `"attack"`.
- `[vehicle, phase or m] call jmfsb_support_fnc_flyAt` sets it.
- `[vehicle or class, taskHeight, distance] call jmfsb_support_fnc_approachHeight`
  -> m: a task with a height of its own (a drop, a jump, a static line) is
  reached on a slope of 5 m flown per m of height, no less than 1 km out;
  further out it is the transit height.
- `[vehicle or class, pos] call jmfsb_support_fnc_holdPoint` -> where it holds
  on station: 8 km outside the map edge nearest the point for a fixed-wing,
  the point for a helicopter.

**Virtual until tasked** (user, 2026-11-02: "all support aircraft needs to be
virtual till tasked, then they spawn in at alt over the support module
location"; built, not seen in game - it replaced the same day's "on station
from the start", whose `standEntry` and `standFuel` are gone). No CAS,
transport, QRF, CAS drone, jump or logistics aircraft exists until its task is
accepted; then the provider makes it over its module at its height and,
after the task, flies it home to the module and removes it there. The
providers share one helper:

- `[vehicle, pos, height, heading] call jmfsb_support_fnc_spawnAirborne` ->
  where it was put (ATL): a vehicle made with "FLY" put at its flight level,
  level, engines on, flying - a plane 0.6 of its top speed, a helicopter
  25 m/s - flyInHeight set. **Clear of other aircraft**: with another within
  150 m (`SPAWN_SEP`) of the point it takes the nearest clear point on rings
  150 m apart, 45 deg steps, four rings out; none clear, it is stacked higher.
  The RPT says when it moved.

Every support module has a **Respawns** count (default 0) and a Respawn Delay
(user, 2026-11-02: "make sure there is a respawn count for each support,
default no respawns"): only an airframe **lost** (destroyed, crew dead,
disabled) uses one - the next task after the delay makes a new one; going
home and being removed uses none. None left, the asset leaves the list and
answers `WHY_NO_AIRFRAME`, "UNABLE - NO AIRFRAME" (each provider keeps its
own copy of the words). Per provider: `support_air`, `cas`, `jumpmaster`,
`support_logistics` READMEs.

Only the task's own height breaks it - a landing, a hover, a set-down, a drop
height. No provider offers a lights, altitude or flight-height knob any
more. Who calls what: `support_air` (`prepareAircraft`, every height),
`support_logistics` (`spawnAircraft`, `launch`, `dropTick`, `slingTick`),
`cas` (`spawnDrone`), `jumpmaster` (`airUp`, `spawnAircraft`), `support_fires` (`loiterOne`,
lights only).

Two exceptions (user, 2026-11-01):

- **CAS drones are exempt from the off-map hold.** A drone's LOITER orbits
  over the grid, dark, at 4000 m, so its camera can watch it; a strike held
  for CLEARED HOT orbits the grid the same way. Its strikes stay at 4000 m.
- **Loitering munitions** (support_fires, Darter / Switchblade type) take the
  lights rule only: on the watch from launch with no airfield, dark
  throughout. Their flight profile is their own.

## Drone escorts (2026-11-01)

Two drone wingmen with a support aircraft (`docs/DESIGN_SUPPORT_MESSAGING.md`
1.2; user, 2026-11-01: "cover, engage, flares, defend and protect"). The
provider decides whether and which class - support_air's
`escortLaunch`, read by every support aircraft module: a fixed-wing lead
always, a helicopter only on a YELLOW or RED LZ security (user, 2026-11-02:
"drone escorts is based on lz security for helos and always for fix wings")
- and hands the core a lead and a drone class. They are made with the lead
over its module and removed with it. Built, not seen in game.

| Function | Does |
|---|---|
| `escort` `[lead, class, side, point]` (Public, server) | two drones beside the lead, their crew in a group of the lead's side, `lambsOff`, ALiVE's profileIgnore (through the adapter), at their kind's tactical height (30 m / 4000 m) stacked - escort n n x 40 m / 150 m above it, made that far above the lead, so none shares a height (2026-11-05) - on the lights watch with **the lead's own airfield**; the IncomingMissile alarm on the lead and on them; the watch started. A lead with live escorts keeps them |
| `escortTick` | every 2 s. **Fly with it**: a wing slot each side (150 m / 400 m out, 100 m / 300 m back), behind the lead and aimed 5 s of its speed ahead, FULL when 400 m / 2 km off it - the left slots to the escorts furthest left of its heading, so none crosses over it; a lead slower than 30 km/h (landed, hovering, on its stand) is orbited at 300 m / 2.5 km, each escort aimed 25 deg on round the lead from where it is, all the same way (2026-11-05: the old orbit slot stepped round on its own and drew both drones through the middle). **Engage**: the missile shooter first (2 min), else the nearest enemy the lead's pilot or the escorts know within 1.5 km / 5 km of the lead, the task point or the lead's next waypoint - revealed, RED / COMBAT, doTarget / doFire, a rotary escort sent to 800 m off it, a fixed-wing over it; never past a 2 km / 8 km leash from the lead. Nothing to hit: YELLOW in the slot. **Backstop**: a missile of the other side within 2.5 km of the lead or an escort raises the alarm |
| `escortMissile` `[aircraft, shooter]` | the alarm: every escort, and an AI-flown lead, puts out its own flares; the shooter is the first target |
| `escortFlare` `[aircraft]` | 3 bursts, 1 s apart, from the first launcher of simulation `cmlauncher` on any turret, by that turret's unit, where the aircraft is local; once per 4 s per aircraft. The AI's own countermeasures still fire |
| `escortEnd` `[lead, escorts]` (Public, server) | removes them, crew and airframe; wrecks stay |
| `escortAttack` `[lead, pos, radius, side, friendlyRange, dangerOk]` (Public, server) | ALL ATTACK (user, 2026-11-02): the lead's live escorts break off and attack the area - the state on the lead; returns how many went in (0: none alive). `escortHits` on the lead reset to 0 |
| `escortStrike` | one tick of it, from `escortTick`: every hostile vehicle, static and man alive inside the radius (not aircraft, not civilian), vehicles and statics first, then men, nearest the centre first; none with a man of `side` inside `friendlyRange` unless `dangerOk`. Each armed escort (a magazine with rounds that is not `shotCM`) keeps its target or takes the first one no other has - revealed, RED / COMBAT, doTarget / doFire, sent over it. A target one was put on that is destroyed counts in `escortHits` on the lead. Over (`escortAttackEnd`) when no target is left, every escort is Winchester, or after 5 min. Escorts it does not hold this tick fly their slots |
| `escortAttackEnd` `[lead]` (Public, server) | the attack is over - the escorts rejoin on the next tick; `escortHits` stays for the provider's BDA |
| `lzSecurity` `[assetId, message]` (Public, server) | GREEN / YELLOW / RED from the root of the asset's open thread, or the message given (step 7, the card reader's) - a ticked bool on a line labelled SECURITY (`hlz` Line 4, casevac's), by the field's word, never a fixed key; a SECURITY choice (the retired 9-line MEDEVAC's, a mission deck's) by its first letter (N GREEN, P YELLOW, E / X RED); `""` for no thread, no such line or no tick. RED is also a hot LZ (step 7) |

Paired numbers above are rotary / fixed-wing (`ESCORT_*` in
`script_component.hpp`). **The end**: the
provider calls `escortEnd` with a lead still there at the end of its sortie
(a synced aircraft on its stand); a lead removed at its exit or base takes
them with it on the next tick; a lead lost sends them back to where they
were made, removed within 1 km of it or after 10 min. A lost escort is not
replaced.

## What happens to an aircraft is said in its thread

User, 2026-11-05: "needs messaging to notify of events like that" - a transport
under missile fire, flaring, shot down, had said so in the RPT and on the side
rail only. `fnc_threadEvent` `[assetId, threadId, line, flash, callsign]`
files a MESSAGE card from the asset in its open thread (FLASH when it matters)
and pops the line to the issuer. The providers reach it through the CBA event
`jmfsb_support_aircraftEvent` `[aircraft, line, flash]` on the server: the
core's escort watch raises `MISSILE - FLARES OUT` (once per 15 s per lead) and
`ESCORT DOWN - n LEFT`; support_air, cas and support_logistics raise `TAKING
FIRE AT <grid>` from their hit watches (once per 30 s per airframe), and
support_air `CANNOT FLY - <fault> - AT <grid>` and `DOWN AT <grid> - AIRFRAME
LOST - NO REPLACEMENT | REPLACEMENT IN n S`; each maps the aircraft to its
owner module's open threads and files the line.

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_messaging`
- `cba_xeh` _(external)_

## Ships

92 functions.

## Functions

<details><summary>92</summary>

- `jmfsb_support_fnc_ack`
- `jmfsb_support_fnc_ackLocal`
- `jmfsb_support_fnc_airframeCaps`
- `jmfsb_support_fnc_alertLocal`
- `jmfsb_support_fnc_approachHeight`
- `jmfsb_support_fnc_askIntentions`
- `jmfsb_support_fnc_askObservers`
- `jmfsb_support_fnc_assetCard`
- `jmfsb_support_fnc_assets`
- `jmfsb_support_fnc_bookCooldown`
- `jmfsb_support_fnc_boxName`
- `jmfsb_support_fnc_builtinCards`
- `jmfsb_support_fnc_builtinFires`
- `jmfsb_support_fnc_builtinReplies`
- `jmfsb_support_fnc_canTask`
- `jmfsb_support_fnc_cardPreview`
- `jmfsb_support_fnc_casPrompt`
- `jmfsb_support_fnc_checkIn`
- `jmfsb_support_fnc_dangerClose`
- `jmfsb_support_fnc_escort`
- `jmfsb_support_fnc_escortAttack`
- `jmfsb_support_fnc_escortAttackEnd`
- `jmfsb_support_fnc_escortEnd`
- `jmfsb_support_fnc_escortFlare`
- `jmfsb_support_fnc_escortMissile`
- `jmfsb_support_fnc_escortStrike`
- `jmfsb_support_fnc_escortTick`
- `jmfsb_support_fnc_etaText`
- `jmfsb_support_fnc_etaTo`
- `jmfsb_support_fnc_fileCard`
- `jmfsb_support_fnc_flightHeight`
- `jmfsb_support_fnc_flyAt`
- `jmfsb_support_fnc_gridPos`
- `jmfsb_support_fnc_holdPoint`
- `jmfsb_support_fnc_inbound`
- `jmfsb_support_fnc_isRotary`
- `jmfsb_support_fnc_lzClear`
- `jmfsb_support_fnc_lzClearAsk`
- `jmfsb_support_fnc_lzClearReply`
- `jmfsb_support_fnc_lzClearTick`
- `jmfsb_support_fnc_lzMarks`
- `jmfsb_support_fnc_lzSecurity`
- `jmfsb_support_fnc_mailboxFiled`
- `jmfsb_support_fnc_mailboxes`
- `jmfsb_support_fnc_markColour`
- `jmfsb_support_fnc_medicalNearest`
- `jmfsb_support_fnc_observer`
- `jmfsb_support_fnc_onAck`
- `jmfsb_support_fnc_ordnanceLeft`
- `jmfsb_support_fnc_overlay`
- `jmfsb_support_fnc_pinCard`
- `jmfsb_support_fnc_pinLive`
- `jmfsb_support_fnc_pinMarker`
- `jmfsb_support_fnc_pinRoot`
- `jmfsb_support_fnc_pinTick`
- `jmfsb_support_fnc_popWord`
- `jmfsb_support_fnc_preview`
- `jmfsb_support_fnc_prompt`
- `jmfsb_support_fnc_promptCleared`
- `jmfsb_support_fnc_provider`
- `jmfsb_support_fnc_reach`
- `jmfsb_support_fnc_readOrder`
- `jmfsb_support_fnc_registerProvider`
- `jmfsb_support_fnc_request`
- `jmfsb_support_fnc_rtbLanding`
- `jmfsb_support_fnc_sitrep`
- `jmfsb_support_fnc_spawnAirborne`
- `jmfsb_support_fnc_srvCallsign`
- `jmfsb_support_fnc_srvFileAs`
- `jmfsb_support_fnc_srvFileCard`
- `jmfsb_support_fnc_srvFiled`
- `jmfsb_support_fnc_srvFollowUp`
- `jmfsb_support_fnc_srvReply`
- `jmfsb_support_fnc_srvTake`
- `jmfsb_support_fnc_srvThreadCard`
- `jmfsb_support_fnc_state`
- `jmfsb_support_fnc_stationWilco`
- `jmfsb_support_fnc_statusReply`
- `jmfsb_support_fnc_tactical`
- `jmfsb_support_fnc_tacticalLights`
- `jmfsb_support_fnc_tacticalTick`
- `jmfsb_support_fnc_tasks`
- `jmfsb_support_fnc_threadBda`
- `jmfsb_support_fnc_threadCards`
- `jmfsb_support_fnc_threadEvent`
- `jmfsb_support_fnc_threadIssuer`
- `jmfsb_support_fnc_threadOrder`
- `jmfsb_support_fnc_types`
- `jmfsb_support_fnc_zones`
- `jmfsb_support_fnc_zonesHold`
- `jmfsb_support_fnc_zonesLocal`
- `jmfsb_support_fnc_zonesPublish`

</details>
