#include "script_component.hpp"
/*
 * Author: YonV
 * Posts a handful of plausible messages so the reader has traffic to be tested
 * against. Off by default, and only ever run on request.
 *
 * A messaging system is the one thing that cannot be tested by looking at it: an
 * empty inbox looks the same whether the engine works, the client never asked,
 * or the server dropped it. Three threads at three precedences, on three
 * different mailboxes, exercise the index, the net tabs, the FLASH treatment,
 * the reply spine and the unread counts in one go.
 *
 * They go through FUNC(submit) like anything else - the same validation, the
 * same server round trip - so what appears in the reader has been through the
 * whole path rather than injected past it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_messaging_fnc_seedTest
 *
 * Public: Yes
 */

if (!hasInterface || {isNull player}) exitWith {};

private _grid = mapGridPosition player;

// The CASEVAC is the FLASH one: its template carries priority "high", which is
// what puts the accent wash and the 4px border on its row. It is the 6-line
// (user, 2026-11-02: "the 6-line only" - the mod's built-in card,
// FUNC(builtinCards)), so these are its keys.
// Line 4 is an exclusive set of ticks, so YELLOW is Line4.B being TRUE - not
// the word "YELLOW" in Line4.A, which is the GREEN tick and would have filed a
// secure LZ. Line 5 is a marking METHOD off a fixed set, with the colour and
// the detail beside it.
// THE 9-LINE since 2026-11-09 (ATP 4-02.2): Line 3 the precedence counts
// (A urgent ... D routine), Line 6 SECURITY N / P / E / X as exclusive ticks
// (Line6.B is P), Line 7 the marking method - no colour, the crew calls it.
["casevac", [
    ["Line1.A", getPosATL player],
    ["Line3.A", 1],
    ["Line5.A", 1],
    ["Line6.B", true],
    ["Line7.A", "SMOKE"],
    ["Remarks.A", "On your call, west of the road"]
], ["B:HQ"]] call FUNC(submit);

// No CALL SIGN line since the report-card review (2026-11-02, D10): the
// sender is on every message.
["sitrep", [
    ["Location.A", _grid],
    ["Enemy.A", "Two technicals seen north of the town, withdrew east"],
    ["Friendly.A", "Section holding the compound, no contact for 40 minutes"],
    ["Civ.A", "Handful of civilians moving south on the MSR"],
    ["Status.A", "AMBER"],
    ["Status.B", "GREEN"],
    ["Status.C", "GREEN"],
    ["Status.D", "GREEN"],
    ["Remarks.A", "Request resupply before last light"]
], ["B:HQ"]] call FUNC(submit);

// The CONTACTREP's line titles are the SALUTE letters themselves, so its field
// keys are S.A, A.A and so on - line titles are keys. The card stays the
// original full SALUTE (user, 2026-11-02).
["contactrep", [
    ["S.A", "Four dismounts"],
    ["A.A", "Digging in on the treeline"],
    ["L.A", _grid],
    ["U.A", "Unknown, mixed dress"],
    ["T.A", "Now"],
    ["E.A", "Small arms, one RPG seen"]
], ["B:Intel"]] call FUNC(submit);

INFO("seeded three test threads");
