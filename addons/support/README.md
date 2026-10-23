# Support

`jmfsb_support`

The support core: one registry of support assets, one request flow, one
acknowledgement event. TAC//SUPPORT (`tacpad_apps` appSupport) reads only this
addon; every asset source - ALiVE combat support, the CAS drone modules and
the `support_fires` / `support_air` addons - is a **provider** registered here.
There is no Simplex dependency (user, 2026-10-20): these addons are our own
replacement for it. The core knows no asset kind.

Design brief: `docs/DESIGN_SUPPORT.md` (phase 1).

Providers depend on this addon, never the reverse. The ALiVE provider lives in
`adapter_alive` (the only addon allowed to name ALiVE symbols), the CAS drone
provider in `cas`, and the fires and air providers in `support_fires` and `support_air`.

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
    ["types",     [...]]    // ARRAY, optional
]] call jmfsb_support_fnc_registerProvider;   // -> BOOL
```

- **kind** `<STRING>`: non-empty, no `:`. It is the prefix of every asset id the
  provider hands out, and how a request is routed back to it. Kinds in use:
  `alive`, `cas`, `air` (support_air), `fires` (support_fires).
- Call it in **postInit on every machine** (not only the server): the screen is
  drawn on the client and calls the provider's code locally. Registering a kind
  again replaces the earlier declaration.
- A declaration missing `assets` or `task` (or with a non-code value there) is
  refused; an optional key of the wrong type is dropped with an RPT warning.

### Asset id

`"<kind>:<anything>"`, a STRING. Everything after the first `:` is the
provider's own (`cas:3`, `alive:arty:0`, `alive:ato`, `air:2`). Rows whose
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

### `task` - executing an order

`[assetId, task, pos, params] call task` -> `[ok, why, cooldown]`

| Arg | Type | Meaning |
|---|---|---|
| assetId | STRING | one of this provider's ids |
| task | STRING | a task token this provider declared, or `"rtb"` (recall) |
| pos | ARRAY | the TARGET point `[x, y, 0]` ATL, `[]` when none was picked (the provider decides what none means - ALiVE air uses the caller's position, artillery refuses) |
| params | ARRAY | the screen's parameter array, see below |

| Return | Type | Meaning |
|---|---|---|
| ok | BOOL | the order was accepted (sent) |
| why | STRING | refusal reason shown to the player; ignored on accept except by callers other than the screen |
| cooldown | NUMBER | optional - seconds the core holds the asset after an accepted order (`0`/absent: none). Not applied to `"rtb"` |

The call is made **on the requesting machine** by `jmfsb_support_fnc_request`
after the gate, validation, cooldown and `available` checks. A provider whose
work must happen on the server sends it there itself (a CBA server event, as
`cas` does) - the core does not move the call. Anything other than an array
return is treated as a refusal ("the provider gave no answer").

**`"rtb"`** is always passed through: never blocked by a cooldown or by
`available`, because an asset you want home is by definition busy. A provider
that cannot recall returns `[false, "why"]`.

### The parameter array (`params`)

One array shared by every asset type, written by the screen's steppers and
kept between orders (`jmfsb_tacpad_apps_supportParams`). Slots in use - **a new
provider must not reuse them with a different meaning**:

| Slot | Meaning | Written for |
|---|---|---|
| 0 | radius (m) | ALiVE CAS |
| 1 | altitude / height (m) | ALiVE CAS, transport |
| 2 | ROE index: 0 RED, 1 GREEN, 2 WHITE, 3 YELLOW, 4 BLUE | ALiVE CAS, transport |
| 3 | speed index: 0 LIMITED, 1 NORMAL, 2 FULL | transport |
| 4 | ordnance index | ALiVE artillery |
| 5 | rounds index into `[1, 3, 6, 12, 24]` | ALiVE artillery |
| 6 | dispersion (m) | ALiVE artillery |
| 7 | guns (0 = all) | ALiVE artillery |
| 8 | INGRESS point, `[]` = auto | CAS drones (always written by CONFIRM) |
| 9 | EGRESS point, `[]` = auto | CAS drones (always written by CONFIRM) |
| 10 | store index into row field 5 | CAS drones |
| 11 | ordnance NAME | ALiVE artillery |
| 12-19 | support_fires' steppers | support_fires |
| 20-31 | support_air's steppers (28 and 29 retired, left empty) | support_air |
| 32-35 | DELAY, INTERVAL, REPEAT, COORDINATE | support_fires |
| 36-39 | free - kept for support_fires | |
| 40-48 | support_air: 40 DANGER CLOSE, 41 LIGHTS, 42 APPROACH, 43 LZ SIGNAL, 44 VIA (a list of points), 45 LZ / SET DOWN (a point), 46 CONTENTS, 47 CRATE SIGNAL, 48 JUMP HEIGHT | support_air |
| 49+ | free | |

Slots 8 and 9 are also read by support_air's CAS: INGRESS and EGRESS mean the
same on both CAS providers. A point slot (8, 9, 44, 45) holds `[x, y, 0]` or
`[]`; a slot of a point declaration that takes several (`many` > 1) holds an
array of those.

### `sitrep` - the SITREP button

`[assetId] call sitrep` -> `[ok, line]`. One readable line for the verdict row
and the notify rail. Optional; without it the core answers `[false, "no report"]`.
The screen offers SITREP for every type, artillery included (2026-10-20).

### `preview` - the verdict before CONFIRM (2026-10-20)

`[assetId, task, pos, params] call preview` -> `[ok, line]`. Optional. Asked
through `jmfsb_support_fnc_preview` (same arguments, answers `[]` when the
provider has no preview or gives no line) on the requesting machine **every
time the board redraws** a request whose UNIT, TASK, point and required points
are all set, with exactly the `params` CONFIRM would send. Cheap, and it must
change nothing. `line` is shown as the READY checklist's VERDICT line - an ETA,
a time of flight, `OUT OF RANGE` - the way Simplex shows its ETA and verdict
beside its confirm. `ok` false is a verdict against the request: the line reads
as missing and CONFIRM waits until it changes.

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
| 1 | label | STRING | the TASK row's label |
| 2 | meta | STRING | the row's right-hand text (a long name), `""` for none |
| 3 | guidance | STRING | the sentence the TASK group label shows once the task is picked - what the task does |
| 4 | steppers | ARRAY | optional - stepper declarations; when non-empty they replace the screen's legacy per-type PARAMETERS layout for this task |
| 5 | needsPoint | BOOL | optional - CONFIRM TASKING stays unavailable until the point is set |
| 6 | pointLabel | STRING | optional - what the screen calls the task's point (`"LZ"`, `"PICKUP"`, `"DROP POINT"`); `""` or absent reads `TARGET`. The name only: the point still arrives as `task`'s `pos` |
| 7 | points | ARRAY | optional (2026-10-20) - further map points the task carries, one row each after the task point; see below |

A **point declaration** (field 7), drawn as a point row picked like the task
point (map click or MKR) and written by CONFIRM into its parameter slot:

```
[label, slot, hint, required, many, leg]
```

| # | Field | Type | Meaning |
|---|---|---|---|
| 0 | label | STRING | the row's name (`"INGRESS"`, `"VIA"`, `"LZ"`) |
| 1 | slot | NUMBER | parameter slot it is written to, 8 or more. 8 and 9 ARE the INGRESS / EGRESS rows - a declaration on them shares the point with every other asset that declares them |
| 2 | hint | STRING | what the row reads while unset (`"AUTO - STRAIGHT THROUGH"`) |
| 3 | required | BOOL | a line of the READY checklist; CONFIRM waits for it |
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
5. **Bookkeeping** - on accept: a returned cooldown is sent to the server
   (`jmfsb_support_cooldown` event) and published; `jmfsb_support_tasked`
   `[assetId, task, pos, kind, requester]` is raised as a CBA global event for
   anything that counts sorties, rounds or keeps an AAR.

Runs where it is called. TAC//SUPPORT calls it on the requesting client.

## Acknowledgement

A provider that learns the asset actually took the order (or did not, in
time) calls:

```sqf
[_assetId, _ok, _said, _requester] call jmfsb_support_fnc_ack;
```

which raises the CBA event **`jmfsb_support_ack`** with payload
`[assetId <STRING>, ok <BOOL>, said <STRING>]` - locally when `_requester` is
omitted, `objNull` or local, otherwise as a target event on the requester's
machine. TAC//SUPPORT shows `said` in its verdict row and on the notify rail
(`ok` false = the warning colour) and redraws. The ALiVE provider acks when the
FSM consumes the order and warns after 20 s if it has not; it still also raises
its old `jmfsb_adapter_alive_supportAck` event with the same payload for
mission scripts.

## Without ALiVE

TAC//SUPPORT registers whenever this addon is loaded. With ALiVE absent the
`adapter_alive` PBO is skipped, the `alive` provider never registers, and the
screen lists what the remaining providers declare (CAS drones, support_fires,
support_air).

<!-- generated below this line by tools/gen_addon_readmes.py - do not edit -->

## Requires

- `jmfsb_main`
- `jmfsb_common`
- `jmfsb_messaging`
- `cba_xeh` _(external)_

## Ships

11 functions.

## Functions

<details><summary>11</summary>

- `jmfsb_support_fnc_ack`
- `jmfsb_support_fnc_assets`
- `jmfsb_support_fnc_canTask`
- `jmfsb_support_fnc_overlay`
- `jmfsb_support_fnc_preview`
- `jmfsb_support_fnc_provider`
- `jmfsb_support_fnc_registerProvider`
- `jmfsb_support_fnc_request`
- `jmfsb_support_fnc_sitrep`
- `jmfsb_support_fnc_tasks`
- `jmfsb_support_fnc_types`

</details>
