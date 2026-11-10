#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a lift card as the job a transport flies for its thread (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING step 7) - kept on the module (QGVAR(liftJob)) and
 * read by FUNC(liftGo), FUNC(liftTick) and FUNC(liftReply):
 *
 *   thread, issuer, kind     the thread, who asked, the card's kind
 *   task, first              the transport task and the point it flies to
 *   prm                      the board's parameter array the order is read
 *                            from (FUNC(transportOrder)): the LZ signal from the
 *                            card's marking, the LZ of a PICKUP > LZ
 *   lz, ingress, egress      the card's LZ and its first points in and out
 *   lzVia, homeVia           the card's flight path (user, 2026-11-02): the
 *                            legs after the pickup - the LIFT REQUEST's ROUTE,
 *                            the EXTRACTION's EGRESS - and home's after the
 *                            drop or an RTB - the LIFT REQUEST's EGRESS
 *   station                  an extraction's STATION, where it holds until
 *                            EXTRACT (step JOB_STATION); [] none, or called in
 *   safePickup               the LIFT REQUEST's pickup, always safe: no 1 MIN
 *                            OUT, no circle, no clearance - it lands
 *   allIn                    the troop load is done: ALL IN (FUNC(liftReply),
 *                            FUNC(srvAllIn)) - it lifts (FUNC(transportStep))
 *   patients                 a casevac's, at least 1
 *   askAt                    the task whose landing is the card's LZ - asked
 *                            1 MIN - LZ STATUS? on the way in: the hlz's LAND
 *                            (the second leg), the casevac's PICKUP, the
 *                            extraction's pickup (2026-11-02: the hot zone);
 *                            "" for a rope insertion
 *   insertTask               the hlz's second leg (the INSERT line, 2026-11-08):
 *                            LAND, FASTROPE or RAPPEL
 *   step                     JOB_FLYING, an extraction JOB_STATION
 *                            (FUNC(liftThread) sets JOB_CONFIRM for a hot LZ)
 *   marking, inboundTo       the card's marking words, and the tasks whose leg
 *                            in says INBOUND - ETA and 1 MIN OUT - POP SMOKE
 *                            (EFUNC(support,inbound), user 2026-11-01): the
 *                            first point and the card's LZ, never a casevac's
 *                            destination; an extraction's pickup, never home
 *                            base
 *   approach                 the card's LAND HEADING as the board's approach
 *                            bearing (2026-11-09), -1 none
 *   landing, landAt          circling the leg's landing point, then cleared to
 *                            land and where (user, 2026-11-02, FUNC(liftTick),
 *                            FUNC(liftCleared)); "" on each new leg
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The order (EFUNC(support,readOrder)) <HASHMAP>
 * 2: The issuer <OBJECT>
 * 3: Thread id <STRING>
 * 4: The transport task <STRING>
 * 5: The point it flies to first <ARRAY>
 *
 * Return Value:
 * The job <HASHMAP>
 *
 * Example:
 * [_logic, _order, _issuer, _threadId, "LIFT", _pickup] call jmfsb_support_air_fnc_liftJob
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_order", createHashMap, [createHashMap]],
    ["_issuer", objNull, [objNull]],
    ["_threadId", "", [""]],
    ["_task", "", [""]],
    ["_first", [], [[]]]
];

private _kind = _order getOrDefault ["kind", ""];

// THE LZ SIGNAL from the card's marking words.
private _marking = _order getOrDefault ["marking", ""];
if !(_marking isEqualType "") then {_marking = ""};
private _signal = SIGNAL_NONE;
{
    _x params ["_word", "_value"];
    if (_word in _marking) exitWith {_signal = _value};
} forEach MARKING_SIGNALS;

private _lz = _order getOrDefault ["lz", []];
private _prm = [];
_prm resize (SLOT_JUMP_ALT + 1);
_prm set [SLOT_SIGNAL, _signal];
if (_task isEqualTo TASK_LIFT) then {_prm set [SLOT_LZ, _lz]};
// A PICKUP has no LZ until its INSERTION comes (user, 2026-11-08): the order
// takes the pickup in its place, the job's own "lz" stays [] - it waits on the
// ground for the insertion (JOB_INSERT, FUNC(liftTick)), which brings the LZ
// it flies to (FUNC(liftReply), FUNC(transportStep)).
if (_kind isEqualTo ORDER_PICKUP) then {_prm set [SLOT_LZ, _first]};

// THE FLIGHT PATH ON THE CARD (user, 2026-11-02: "up to 4 route points from
// pickup to the LZ and up to 4 egress points after the drop; empty = the pilot
// picks"): the LIFT REQUEST's ROUTE is flown from the pickup to the LZ, its
// EGRESS home after the drop; the EXTRACTION's EGRESS from the HLZ home. An
// older card's single ingress / egress point is a
// route of one.
private _ingress = _order getOrDefault ["ingress", []];
private _egress = _order getOrDefault ["egress", []];
private _route = _order getOrDefault ["route", [[], [_ingress]] select (_ingress isNotEqualTo [])];
private _egressRoute = _order getOrDefault ["egressRoute", [[], [_egress]] select (_egress isNotEqualTo [])];
private _extract = _kind isEqualTo ORDER_EXTRACT;
// The legs after the pickup, and home's after an RTB or ABORT: an extraction
// flies its egress after the HLZ only - an abort before that goes home direct.
private _lzVia = [_route, _egressRoute] select _extract;
private _homeVia = [_egressRoute, []] select _extract;

// THE EXTRACTION IS ON STATION FIRST (user, 2026-11-02: "1) on station 2)
// extraction"): its STATION marker, else STATION_SHORT m short of the HLZ on
// the side it comes from, flown as the order's first leg (VIA); it holds there
// until EXTRACT (FUNC(liftTick), FUNC(liftReply)).
private _station = [];
if (_extract) then {
    _station = _order getOrDefault ["station", []];
    if (_station isEqualTo []) then {
        (_first getPos [STATION_SHORT, _first getDir (_logic getVariable [QGVAR(home), getPosATL _logic])]) params ["_sx", "_sy"];
        _station = [_sx, _sy, 0];
    };
    _prm set [SLOT_VIA, [_station]];
};

// HOW THE LIFT REQUEST GOES IN (user, 2026-11-08: the INSERT line): a landing,
// or from the hover on ropes - in fast, out fast, nothing asked on the way in
// (FUNC(transportStep) picks ACE's ropes or the rappel by the airframe).
private _insertTask = switch (_order getOrDefault ["insert", ""]) do {
    case "rope": {TASK_FASTROPE};
    case "rappel": {TASK_RAPPEL};
    default {TASK_LAND};
};
private _askAt = switch (_kind) do {
    case ORDER_LIFT: {[TASK_LAND, ""] select (_insertTask isNotEqualTo TASK_LAND)};
    case ORDER_CASEVAC: {TASK_PICKUP};
    // THE PICKUP IS THE HOT ZONE (user, 2026-11-02).
    case ORDER_EXTRACT: {_task};
    default {""};
};
// On the way in to the first point and the card's LZ - an extraction has no
// destination (2026-11-08: home on ALL IN), so its pickup only. The LIFT
// REQUEST's pickup is always safe (user, 2026-11-02: "pick up site (always
// safe)"): nothing is said on the way in to it, and it lands there without
// the mark or a clearance (safePickup, FUNC(liftTick)).
private _safePickup = _kind in [ORDER_LIFT, ORDER_PICKUP];
// A rope insertion still calls its 1 MIN OUT, and asks nothing.
private _inbound = [[_task, _askAt], [[_askAt], [_insertTask, TASK_RAPPEL]] select (_insertTask isNotEqualTo TASK_LAND)] select _safePickup;
_inbound = (_inbound arrayIntersect _inbound) select {_x isNotEqualTo ""};

// LAND HEADING (2026-11-09): the leg it lands on comes in on it - the board's
// approach bearing is where it comes from (FUNC(transportPlan)); a PICKUP's on
// its pickup leg (FUNC(liftGo)), an INSERTION's on the LZ leg
// (FUNC(transportStep)).
private _heading = _order getOrDefault ["heading", -1];
if !(_heading isEqualType 0) then {_heading = -1};
private _approach = [-1, (_heading + HEADING_REVERSE) mod FULL_CIRCLE] select (_heading >= 0);

createHashMapFromArray [
    ["thread", _threadId],
    ["approach", _approach],
    ["issuer", _issuer],
    ["kind", _kind],
    ["task", _task],
    ["first", _first],
    ["prm", _prm],
    ["lz", _lz],
    ["ingress", _ingress],
    ["egress", _egress],
    ["lzVia", _lzVia],
    ["homeVia", _homeVia],
    ["station", _station],
    ["safePickup", _safePickup],
    ["allIn", false],
    ["patients", (_order getOrDefault ["patients", 1]) max 1],
    ["askAt", _askAt],
    ["insertTask", _insertTask],
    ["marking", toUpper _marking],
    ["inboundTo", _inbound],
    ["step", [JOB_FLYING, JOB_STATION] select _extract],
    ["legs", 0],
    ["leg", ""],
    ["asked", false],
    ["down", false],
    ["holding", false],
    ["landing", ""],
    ["landAt", []],
    ["loadUntil", 0],
    ["destName", ""]
]
