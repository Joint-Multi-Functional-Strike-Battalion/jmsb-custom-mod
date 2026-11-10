#include "script_component.hpp"
/*
 * Author: YonV
 * The support reply cards the mod carries - the requester's commands and
 * follow-ups, the asset's calls, the answers to its questions (part of
 * FUNC(builtinCards), the one entry point). THE MOD'S OWN CARD ALWAYS WINS
 * (user, 2026-11-02): each is the one used, whatever the TAC//PAC deck holds.
 *
 * THE MESSAGE TEMPLATES (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09). Every
 * card is one of four classes - a starter (FUNC(builtinCards)), a follow-up
 * (fields, only in a thread), a command (no fields, one press) or what the
 * asset says - and the template options tell the reader which
 * (EFUNC(messaging,registerTemplate)):
 *
 *   assetThread  offered only in a thread an asset answers: FRAGO, STATUS,
 *                HOLD, ABORT, RTB, ROGER (`copy`), in every one while it is
 *                open
 *   roots        offered only where the thread's current tasking is one of
 *                these cards (ROOTS_*): the landing commands in a transport's
 *                thread, the CAS commands in a flight's, the fires commands
 *                in a battery's
 *   answerOnly   offered only when the asset asks for it (its ASSET ASKS'
 *                answers): HOT, COLD, CORRECT, WRONG, NO SMOKE, RECEIVED,
 *                NOT FOUND, NO, PAX OFF
 *   assetOnly    the asset's side - never in the requester's menu, refused
 *                from a player in an asset's thread (FUNC(srvThreadCard))
 *
 * New: MOVE, STATUS, STATUS REPLY, CONTINUE APPROACH, GO AROUND, CONTINUE,
 * CLEARED TO ENGAGE, EXECUTE, NO DROP, IP INBOUND, ROUNDS COMPLETE, ESCORT
 * (user, 2026-11-09: "a way to call in escorts to all transports no mater the
 * phase or tasking"). Retired: DESTINATION (into MOVE), CONFIRM (into EXECUTE -
 * still told to the providers as "confirm", FOLLOW_UP_WORDS). READBACK, STATE
 * INTENTIONS and ATTACK COMPLETE are questions, so they are the asset's ASKS
 * (`prompt`) with their answers (FUNC(askIntentions)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Cards, each [id, title, short, lines, options] <ARRAY>
 *
 * Example:
 * private _cards = [] call jmfsb_support_fnc_builtinReplies
 *
 * Public: No
 */

private _live = [STATE_ACCEPTED, STATE_IN_PROGRESS];
private _anyOpen = ["ISSUED", STATE_RECEIPT, STATE_ACCEPTED, STATE_IN_PROGRESS];
private _onTask = [STATE_IN_PROGRESS];

// A reply card: the thread keeps its state unless the options say otherwise.
private _fnc_reply = {
    params ["_options"];
    [["kind", CARD_KIND_REPLY]] + _options
};
// The class options, added to a reply's.
private _command = [["assetThread", true]];
private _asset = [["assetOnly", true]];
private _answer = [["answerOnly", true]];

// The lines several cards share - field keys the providers read (Text.A,
// Rounds.A). One label for the asset's text line, DETAIL (report-card review,
// 2026-11-02).
private _assetText = ["Text", "DETAIL", [["", "Optional, e.g. TOF 32", "text", []]]];
private _detail = ["Text", "DETAIL", [["", "Optional, e.g. ETA 2:40", "text", []]]];
private _ffeRounds = ["Rounds", "ROUNDS (PER GUN)", [["", "Rounds per gun; empty = as the mission was called", "number", [["min", 1]]]]];

private _cards = [];

// --- Any asset thread: the commands ------------------------------------------
// STATUS (new): the asset says where it is, what it is doing, time left on
// station, fuel, ammo and pax (FUNC(statusReply)).
_cards pushBack ["status", "STATUS", "STATUS", [], [[["allowedFrom", _anyOpen]] + _command] call _fnc_reply];
// HOLD: stop where you are and wait for the next order (meaning widened).
_cards pushBack ["hold", "HOLD", "HOLD", [], [[["allowedFrom", _anyOpen]] + _command] call _fnc_reply];
// ABORT: stop what you are doing now; on a landing do not complete it, on a
// CAS run abort the pass - then the asset asks for intentions.
_cards pushBack ["abort", "ABORT", "ABORT", [], [[["priority", PRIORITY_FLASH], ["allowedFrom", _anyOpen]] + _command] call _fnc_reply];
// THE RTB LANDING POINT (user, 2026-11-09: "we need a way to set an rtb
// landing location if an aircraft has players on board"): optional - an
// aircraft with players aboard lands there and lets them off before it goes
// home; empty, or nobody aboard, home base as before (RTB_CARDS).
_cards pushBack ["rtb", "RETURN TO BASE", "RTB", [
    ["Land", "LAND AT - WITH PLAYERS ABOARD", [["", "Grid / map marker where the players get off; empty = base", "grid", [["source", "mapClick"]]]]]
], [[["allowedFrom", _anyOpen], ["anchor", "Land.A"], ["subject", "RTB {Land.A}"]] + _command] call _fnc_reply];
// ROGER from the requester: received and understood, commits to nothing - no
// state, unlike messaging's ROGER (a RECEIPT, the asset's own).
_cards pushBack ["copy", "ROGER", "ROGER", [], [[["allowedFrom", _anyOpen]] + _command] call _fnc_reply];

// --- Follow-ups ---------------------------------------------------------------
// MOVE (new, replaces DESTINATION): go to a point, then LOITER / LAND / HOVER
// / HOLD. Short: the point and what it does there.
private _arrivalOpts = [["required", true], ["exclusive", "arrival"]];
private _route = [];
for "_n" from 1 to ROUTE_POINTS_MAX do {
    _route pushBack ["", format ["Route point %1 - grid / map marker; empty = direct", _n], "grid", [["source", "mapClick"], ["noCur", true]]];
};
_cards pushBack ["move", "MOVE", "MOVE", [
    ["Point", "POINT", [["", "Grid / map marker to go to", "grid", [["required", true], ["source", "mapClick"]]]]],
    ["Arrival", "ON ARRIVAL", [
        ["LOITER", "Orbit the point", "bool", _arrivalOpts],
        ["LAND", "Land at the point", "bool", _arrivalOpts],
        ["HOVER", "Hover at the point", "bool", _arrivalOpts],
        ["HOLD", "Hold at the point until told", "bool", _arrivalOpts]
    ]],
    ["Route", format ["ROUTE (UP TO %1, IN ORDER)", ROUTE_POINTS_MAX], _route],
    ["Altitude", "ALTITUDE (M)", [["", "Metres; empty = its own", "number", [["min", 0], ["max", BUILTIN_MOVE_ALT_MAX]]]]],
    ["Time", "TIME (MIN)", [["", "Minutes to stay; empty = until told", "number", [["min", 1], ["max", BUILTIN_MOVE_TIME_MAX]]]]],
    ["Remarks", "REMARKS", [["", "Remarks", "textarea", []]]]
], [[
    ["allowedFrom", _anyOpen], ["roots", ROOTS_MOVE], ["anchor", "Point.A"],
    ["shortLines", ["Point", "Arrival"]],
    ["subject", "MOVE {Point.A}"]
] + _command] call _fnc_reply];

// ESCORT (user, 2026-11-09): drone escorts up with the transport now, or with
// it when it launches - any phase, any tasking (support_air escortCall).
_cards pushBack ["escort", "ESCORT", "ESCORT", [], [[["allowedFrom", _anyOpen], ["roots", ROOTS_TRANSPORT]] + _command] call _fnc_reply];

// --- Fires --------------------------------------------------------------------
// A SECOND CORRECTION (report-card review, 2026-11-02, decision 10): "RIGHT
// 50, ADD 100" is one transmission on the net - the other axis, optional.
_cards pushBack ["adjust", "ADJUST FIRE", "ADJUST", [
    ["Direction", "CORRECTION", [["", "Add, drop, left or right", "choice", [["required", true], ["choices", ADJUST_WORDS]]]]],
    ["Distance", "DISTANCE (M)", [["", "Metres", "number", [["required", true], ["min", 0]]]]],
    ["Second", "AND - THE OTHER AXIS (OPTIONAL)", [
        ["", "Add, drop, left or right", "choice", [["choices", ADJUST_WORDS]]],
        ["", "Metres", "number", [["min", 0]]]
    ]]
], [[["allowedFrom", _live], ["roots", ROOTS_FIRES], ["subject", "ADJUST {Direction.A} {Distance.A} {Second.A} {Second.B}"]]] call _fnc_reply];
_cards pushBack ["ffe", "FIRE FOR EFFECT", "FFE", [_ffeRounds], [[["transitionsTo", STATE_IN_PROGRESS], ["allowedFrom", _live], ["roots", ROOTS_FIRES]]] call _fnc_reply];
// REPEAT: fire the same again; after CHECK FIRE, resume (decision 7).
_cards pushBack ["repeat", "REPEAT", "REPEAT", [], [[["allowedFrom", _live], ["roots", ROOTS_FIRES]]] call _fnc_reply];
_cards pushBack ["checkfire", "CHECK FIRE", "CHECK FIRE", [], [[["priority", PRIORITY_FLASH], ["allowedFrom", _anyOpen], ["roots", ROOTS_FIRES]]] call _fnc_reply];
// RECORD AS TARGET (user, 2026-11-02): the battery names the mission's point
// a target (AB1001) and marks it for the side.
_cards pushBack ["record", "RECORD AS TARGET", "RECORD", [], [[["allowedFrom", _live], ["roots", ROOTS_FIRES]]] call _fnc_reply];

// --- CAS ----------------------------------------------------------------------
_cards pushBack ["clearedhot", "CLEARED HOT", "CLEARED HOT", [], [[["priority", PRIORITY_FLASH], ["allowedFrom", _live], ["roots", ROOTS_CAS]]] call _fnc_reply];
// CLEARED TO ENGAGE (new, Type 3 control): attack within the limits given;
// the aircraft reports ATTACK COMPLETE.
_cards pushBack ["clearedengage", "CLEARED TO ENGAGE", "CLEARED TO ENGAGE", [], [[["priority", PRIORITY_FLASH], ["allowedFrom", _live], ["roots", ROOTS_CAS]]] call _fnc_reply];
// CONTINUE (new): proceed with the attack run, no release yet.
_cards pushBack ["continue", "CONTINUE", "CONTINUE", [], [[["allowedFrom", _live], ["roots", ROOTS_CAS]]] call _fnc_reply];
// ALL ATTACK (user, 2026-11-02): CLEARED HOT for a fixed-wing flight's jet and
// its escort drones. Kept as a game command (decision 5).
_cards pushBack ["allattack", "ALL ATTACK", "ALL ATTACK", [], [[["priority", PRIORITY_FLASH], ["allowedFrom", _live], ["roots", ROOTS_CAS]]] call _fnc_reply];

// --- Landing ------------------------------------------------------------------
// Circle, verify the mark, cleared to land (user, 2026-11-02; FUNC(lzClear)).
_cards pushBack ["clearedland", "CLEARED TO LAND", "CLEARED TO LAND", [], [[["priority", PRIORITY_FLASH], ["allowedFrom", _onTask], ["roots", ROOTS_LIFT + ["qrf"]]]] call _fnc_reply];
// CONTINUE APPROACH (new): keep coming, not cleared to land yet.
_cards pushBack ["continueapp", "CONTINUE APPROACH", "CONTINUE APPROACH", [], [[["allowedFrom", _onTask], ["roots", ROOTS_LIFT + ["qrf"]]]] call _fnc_reply];
// GO AROUND (new): do not land - circle and begin another approach.
_cards pushBack ["goaround", "GO AROUND", "GO AROUND", [], [[["priority", PRIORITY_FLASH], ["allowedFrom", _onTask], ["roots", ROOTS_LIFT + ["qrf"]]]] call _fnc_reply];

// --- Lift ---------------------------------------------------------------------
// ALL IN lifts the helicopter from the pickup; EXTRACT calls an extraction
// holding on its station in to the HLZ (user, 2026-11-02).
_cards pushBack ["allin", "ALL IN", "ALL IN", [], [[["allowedFrom", _onTask], ["roots", ROOTS_LIFT]]] call _fnc_reply];
_cards pushBack ["extractnow", "EXTRACT - COME IN TO THE HLZ", "EXTRACT", [], [[["priority", PRIORITY_FLASH], ["allowedFrom", _onTask], ["roots", ["extract"]]]] call _fnc_reply];
// BOARD (user, 2026-11-02): the stick is boarding the jump aircraft.
_cards pushBack ["board", "BOARD", "BOARD", [], [[["allowedFrom", _live], ["roots", ["jump"]]]] call _fnc_reply];

// --- Drop and jump ------------------------------------------------------------
// EXECUTE (new, replaces CONFIRM): drop - and a hot LZ's go-ahead, a battery
// laid AT MY COMMAND's first salvo, as CONFIRM was.
_cards pushBack ["execute", "EXECUTE", "EXECUTE", [], [[["priority", PRIORITY_FLASH], ["allowedFrom", _live], ["roots", ROOTS_EXECUTE]]] call _fnc_reply];
// NO DROP (new): do not drop - another pass, or await orders.
_cards pushBack ["nodrop", "NO DROP", "NO DROP", [], [[["priority", PRIORITY_FLASH], ["allowedFrom", _live], ["roots", ROOTS_DROP]]] call _fnc_reply];
// GO: jump - given at the red light to release the stick.
_cards pushBack ["go", "GO - JUMP", "GO", [], [[["priority", PRIORITY_FLASH], ["allowedFrom", _onTask], ["roots", ["jump"]]]] call _fnc_reply];

// --- Answers, offered only when the asset asks --------------------------------
_cards pushBack ["cold", "LZ COLD", "COLD", [], [[["allowedFrom", _onTask]] + _answer] call _fnc_reply];
_cards pushBack ["hot", "LZ HOT", "HOT", [], [[["priority", PRIORITY_FLASH], ["allowedFrom", _onTask]] + _answer] call _fnc_reply];
_cards pushBack ["correct", "CORRECT", "CORRECT", [], [[["allowedFrom", _anyOpen]] + _answer] call _fnc_reply];
_cards pushBack ["wrong", "WRONG", "WRONG", [], [[["allowedFrom", _anyOpen]] + _answer] call _fnc_reply];
_cards pushBack ["nosmoke", "NO SMOKE - LAND ON THE GRID", "NO SMOKE", [], [[["allowedFrom", _onTask]] + _answer] call _fnc_reply];
_cards pushBack ["received", "RECEIVED", "RECEIVED", [], [[["allowedFrom", _onTask]] + _answer] call _fnc_reply];
_cards pushBack ["notfound", "NOT FOUND", "NOT FOUND", [], [[["allowedFrom", _onTask]] + _answer] call _fnc_reply];
_cards pushBack ["no", "NO", "NO", [], [[["allowedFrom", _onTask]] + _answer] call _fnc_reply];
// PAX OFF: the answer to WHEELS DOWN - PAX OFF? (the design lists it among
// the asset's calls and says it is the least certain; the asset still asks).
_cards pushBack ["paxoff", "PAX OFF", "PAX OFF", [], [[["allowedFrom", _onTask]] + _answer] call _fnc_reply];

// --- What the asset says ------------------------------------------------------
_cards pushBack ["shot", "SHOT", "SHOT", [_assetText], [[["allowedFrom", _onTask], ["subject", "SHOT {Text.A}"]] + _asset] call _fnc_reply];
_cards pushBack ["splash", "SPLASH", "SPLASH", [_assetText], [[["allowedFrom", _onTask], ["subject", "SPLASH {Text.A}"]] + _asset] call _fnc_reply];
// ROUNDS COMPLETE (new): the battery has fired what was called.
_cards pushBack ["roundscomplete", "ROUNDS COMPLETE", "ROUNDS COMPLETE", [_assetText], [[["allowedFrom", _live], ["subject", "ROUNDS COMPLETE {Text.A}"]] + _asset] call _fnc_reply];
_cards pushBack ["prompt", "ASSET ASKS", "ASKS", [
    ["Text", "ASKS", [["", "What the asset asks", "text", [["required", true]]]]],
    ["Answers", "ANSWERS", [["", "Asset use - leave empty (reply ids offered as quick replies)", "text", []]]]
], [[["allowedFrom", _anyOpen], ["subject", "{Text.A}"]] + _asset] call _fnc_reply];
// STATUS REPLY (new): the answer to STATUS.
_cards pushBack ["statusreply", "STATUS REPLY", "STATUS", [
    ["Position", "POSITION", [["", "Grid and altitude", "text", []]]],
    ["Task", "TASK", [["", "What it is doing", "text", []]]],
    ["Station", "TIME LEFT ON STATION", [["", "Minutes", "text", []]]],
    ["Fuel", "FUEL", [["", "Fuel left", "text", []]]],
    ["Ammo", "AMMO", [["", "Ordnance left", "text", []]]],
    ["Pax", "PAX", [["", "Passengers aboard", "text", []]]]
], [[["allowedFrom", _anyOpen], ["subject", "STATUS {Position.A} - {Task.A}"]] + _asset] call _fnc_reply];
_cards pushBack ["wheelsup", "WHEELS UP", "WHEELS UP", [_assetText], [[["allowedFrom", _live], ["subject", "WHEELS UP {Text.A}"]] + _asset] call _fnc_reply];
_cards pushBack ["wheelsdown", "WHEELS DOWN", "WHEELS DOWN", [_assetText], [[["allowedFrom", _live], ["subject", "WHEELS DOWN {Text.A}"]] + _asset] call _fnc_reply];
// An extraction never touches down (2026-11-08): IN THE HOVER at its pickup.
_cards pushBack ["inhover", "IN THE HOVER", "IN THE HOVER", [_assetText], [[["allowedFrom", _live], ["subject", "IN THE HOVER {Text.A}"]] + _asset] call _fnc_reply];
// IP INBOUND (new): leaving the IP for the target; IN follows.
_cards pushBack ["ipinbound", "IP INBOUND", "IP INBOUND", [_assetText], [[["allowedFrom", _live], ["subject", "IP INBOUND {Text.A}"]] + _asset] call _fnc_reply];
_cards pushBack ["in", "IN", "IN", [], [[["allowedFrom", _onTask]] + _asset] call _fnc_reply];
_cards pushBack ["off", "OFF", "OFF", [], [[["allowedFrom", _onTask]] + _asset] call _fnc_reply];
// The jump aircraft's milestones (user, 2026-11-02).
_cards pushBack ["redlight", "RED LIGHT", "RED LIGHT", [_assetText], [[["priority", PRIORITY_FLASH], ["allowedFrom", _onTask], ["subject", "RED LIGHT {Text.A}"]] + _asset] call _fnc_reply];
_cards pushBack ["greenlight", "GREEN LIGHT - GO", "GREEN LIGHT", [_assetText], [[["priority", PRIORITY_FLASH], ["allowedFrom", _onTask], ["subject", "GREEN LIGHT - GO {Text.A}"]] + _asset] call _fnc_reply];
_cards pushBack ["stickout", "STICK OUT", "STICK OUT", [_assetText], [[["allowedFrom", _onTask], ["subject", "STICK OUT {Text.A}"]] + _asset] call _fnc_reply];
// INBOUND, the ETA on the way (user, 2026-11-01).
_cards pushBack ["inbound", "INBOUND", "INBOUND", [_detail], [[["allowedFrom", _live], ["subject", "INBOUND {Text.A}"]] + _asset] call _fnc_reply];

_cards
