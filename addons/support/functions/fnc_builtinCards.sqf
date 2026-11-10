#include "script_component.hpp"
/*
 * Author: YonV
 * The support cards the mod carries - the one entry point: the reply cards
 * (FUNC(builtinReplies)), the requests below and the calls for fire
 * (FUNC(builtinFires)). The reports and the replies every thread takes are
 * messaging's (jmfsb_messaging_fnc_builtinCards) and work without this addon.
 *
 * THE MOD'S OWN CARD ALWAYS WINS (user, 2026-11-02: card changes reach the
 * game with the mod - nobody runs a script against the database). Every card
 * here is built in and is the one used: registered in this addon's preInit
 * (jmfsb_messaging_fnc_registerBuiltins), and the TAC//PAC deck adds only the
 * ids the mod does not have (pac templatesApply). It began (user, 2026-11-01:
 * "trans transport did not come") because the deck had none of the cards
 * support by message files and answers with. tools/check_invariants.py fails
 * the build when a card id the providers, the prompts' quick replies or the
 * card reader name is not built in. Every card is one `_cards pushBack [...]`
 * line - that is what the check reads.
 *
 * THE REPORT-CARD REVIEW (docs/REVIEW_REPORT_CARDS_2026-11-02.md, user
 * 2026-11-02): required is only what the receiver cannot act without; no CUR
 * LOC on a target grid; one marking list per kind (MARKS_GROUND, MARKS_TARGET);
 * the BDA's target from the thread's point; titles LIFT REQUEST (HLZ) and
 * PARADROP (supplies go by RESUPPLY); an AIRFRAME CHECK-IN's CAPABILITIES and
 * LASER CODE; a QRF's RECOGNITION SIGNALS and its ACTION ON ARRIVAL a pick.
 * The same day, later (user): one CAS card - "CAS REQUEST and CAS 9-line do
 * not need both", so `nineline` is retired; CALL FOR FIRE as three cards; an
 * EXTRACTION card - "need a pick up version where the pick up is the hot
 * zone"; REQUEST ON STATION's AREA a map marker, required; RESUPPLY's items
 * picks of the pre-made crates.
 *
 * THE CAS, HLZ AND EXTRACTION FLOWS (user, 2026-11-02: "the message templates
 * need to have all the above fields in them"): the LIFT REQUEST's PICKUP
 * (always safe), its ROUTE to the LZ and EGRESS after the drop (Line 6 /
 * Line 7, up to ROUTE_POINTS_MAX points each - Line6.A / Line7.A were the
 * single ingress / egress point); the BDA's DECISION, RE-ATTACK or EGRESS, one
 * required; the EXTRACTION's STATION and its EGRESS points; ALL IN and EXTRACT
 * among the lift cards' answers.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Cards, each [id, title, short, lines, options] - the shape
 * jmfsb_messaging_fnc_registerTemplate takes <ARRAY>
 *
 * Example:
 * private _cards = [] call jmfsb_support_fnc_builtinCards
 *
 * Public: No
 */

private _live = [STATE_ACCEPTED, STATE_IN_PROGRESS];
private _liftReplies = BUILTIN_REPLIES + BUILTIN_LIFT_REPLIES;

// A flight path's fields: ROUTE_POINTS_MAX grids (A to D - the keys the
// reader takes in order), a map click or a marker each, no CUR LOC.
private _fnc_points = {
    params ["_word", "_empty"];
    private _fields = [];
    for "_n" from 1 to ROUTE_POINTS_MAX do {
        _fields pushBack ["", format ["%1 point %2 - grid / map marker; empty = %3", _word, _n, _empty], "grid", [["source", "mapClick"], ["noCur", true]]];
    };
    _fields
};

// The lines several cards share - field keys the providers read (Count.A,
// Reattack.A).
private _bdaCount = ["Count", "COUNT", [["", "How many destroyed or damaged", "number", [["min", 0]]]]];
// THE BDA DECIDES, THREE PICKS (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09):
// DECISION, one tick required - RE-ATTACK (Reattack.A - it holds for a new
// clearance), BACK TO STATION (Reattack.B - it returns to its station for the
// next tasking) or RTB (Reattack.C - the card's egress, home; the old EGRESS).
private _decisionOpts = [["required", true], ["exclusive", "decision"]];
private _bdaReattack = ["Reattack", "DECISION", [
    ["RE-ATTACK", "Re-attack - it holds for a new clearance", "bool", _decisionOpts],
    ["BACK TO STATION", "Back to station - it waits for the next tasking", "bool", _decisionOpts],
    ["RTB", "RTB - it flies the egress and goes home", "bool", _decisionOpts]
]];

private _cards = [] call FUNC(builtinReplies);

// CAS REQUEST (STRIKE_CARDS) - THE TRUE 9-LINE (JP 3-09.3 Fig V-11;
// docs/DESIGN_MESSAGE_TEMPLATES.md decision 3, 2026-11-09): the TYPE OF
// CONTROL before the brief (decision 6 - Type 3 is CLEARED TO ENGAGE), lines 1
// to 9 in the pub's order, the remarks (restrictions, final attack heading,
// munitions) and the TOT. Lines 2-4 (heading, distance, elevation) and line 8's
// direction and distance are filled by the game (tacpad autoFill ipHeading,
// ipDistance, targetElevation, friendlies); the server still measures the
// friendlies itself. Short: the description, the target and DANGER CLOSE.
_cards pushBack ["cas", "CAS REQUEST", "CAS", [
    ["Control", "TYPE OF CONTROL", [
        ["1", "Type 1 - the JTAC sees the aircraft and the target, every pass", "bool", [["exclusive", "control"]]],
        ["2", "Type 2 - the JTAC sees the target or has its data, each pass cleared", "bool", [["exclusive", "control"]]],
        ["3", "Type 3 - attacks within the limits given, CLEARED TO ENGAGE", "bool", [["exclusive", "control"]]]
    ]],
    ["Line 1", "IP / BP", [["", "Initial point / battle position - grid / map marker", "grid", [["source", "mapClick"], ["noCur", true]]]]],
    ["Line 2", "HEADING (IP TO TARGET)", [["", "Degrees - filled from the IP and the target", "text", [["autoFill", "ipHeading"]]]]],
    ["Line 3", "DISTANCE (IP TO TARGET)", [["", "Metres - filled from the IP and the target", "text", [["autoFill", "ipDistance"]]]]],
    ["Line 4", "TARGET ELEVATION", [["", "Metres - filled from the map", "text", [["autoFill", "targetElevation"]]]]],
    ["Line 5", "TARGET DESCRIPTION", [["", "What, how many, moving?", "textarea", [["required", true]]]]],
    ["Line 6", "TARGET LOCATION", [["", "Target grid / map position", "grid", [["required", true], ["source", "mapClick"], ["noCur", true]]]]],
    ["Line 7", "MARK / CODE", [
        ["", "How the target is marked", "choice", [["choices", MARKS_TARGET]]],
        ["", "Laser code (4 digits) / mark detail", "text", []]
    ]],
    ["Line 8", "FRIENDLIES", [
        ["", "Direction and distance from the target - filled from your position", "text", [["autoFill", "friendlies"]]],
        ["DANGER CLOSE", format ["Under %1 m - tick to acknowledge", DANGER_CLOSE_CAS], "bool", []]
    ]],
    ["Line 9", "EGRESS", [["", "Egress direction / map marker", "grid", [["source", "mapClick"], ["noCur", true]]]]],
    ["Remarks", "REMARKS", [["", "Restrictions, final attack heading, munitions", "textarea", []]]],
    ["TOT", "TIME ON TARGET", [["", "TOT - 1430, 143015, or +5 for 5 min from now", "time", []]]]
], [
    ["priority", PRIORITY_FLASH],
    ["anchor", "Line6.A"],
    ["transitionsTo", "ISSUED"],
    ["replyableWith", BUILTIN_REPLIES + BUILTIN_CAS_REPLIES],
    ["shortLines", ["Line 5", "Line 6", "Line 8"]],
    ["shortFields", ["Line8.B"]],
    ["subject", "CAS {Line6.A} - {Line5.A}"]
]];

// AIRFRAME CHECK-IN, an open report (CARD_CHECKIN): what the aircraft brings,
// its CAPABILITIES and LASER CODE.
_cards pushBack ["checkin", "AIRFRAME CHECK-IN", "CHECK-IN", [
    ["Line 1", "AIRFRAME CALL SIGN", [["", "Call sign", "callsign", [["autoFill", "ownCallsign"]]]]],
    ["Line 2", "NUMBER AND TYPE OF AIRCRAFT", [["", "e.g. 2x AH-99", "text", []]]],
    ["Line 3", "POSITION AND ALTITUDE", [
        ["", "Grid / marker / battle position", "grid", [["source", "mapClick"]]],
        ["ALT ", "Altitude (m)", "number", [["min", 0], ["max", BUILTIN_CHECKIN_ALT_MAX]]]
    ]],
    ["Line 4", "ORDNANCE", [["", "Quantity of each munition", "textarea", []]]],
    ["Line 5", "TIME ON STATION (MIN)", [["", "Minutes available for tasking", "number", [["min", 0], ["max", BUILTIN_CHECKIN_TOS_MAX]]]]],
    ["Line 6", "ABORT CODE", [["", "Provided by flight lead", "text", []]]],
    ["Capabilities", "CAPABILITIES", [
        ["FMV", "Full-motion video", "bool", []],
        ["LASER", "Laser designator", "bool", []],
        ["IR", "IR pointer", "bool", []],
        ["NVG", "Night vision", "bool", []]
    ]],
    ["Laser", "LASER CODE", [["", "Four digits, 1111-1788", "number", [["min", BUILTIN_LASER_MIN], ["max", BUILTIN_LASER_MAX]]]]],
    ["Line 7", "REMARKS", [["", "Remarks", "textarea", []]]]
], [
    ["anchor", "Line3.A"],
    ["replyableWith", BUILTIN_OPEN_REPLIES],
    ["shortLines", ["Line 1", "Line 5"]],
    ["subject", "CHECK-IN {Line1.A} - {Line2.A}"]
]];

_cards append ([] call FUNC(builtinFires));

// PICKUP (PICKUP_CARDS) - THE PICKUP REPORT ON ITS OWN (user, 2026-11-08:
// "split the transport in to two things, pick up with the helo lands turns
// off, insertion happens after a pickup"): the transport lands at the pickup
// (always safe - no LZ status, no circle), shuts down, and asks for the
// INSERTION, filed in this thread.
_cards pushBack ["pickup", "PICKUP", "PICKUP", [
    ["Pickup", "PICKUP - ALWAYS SAFE", [["", "Pickup grid / map position; empty = your position", "grid", [["source", "mapClick"]]]]],
    ["Pax", "PAX / LOAD", [["", "Passengers / load", "text", []]]],
    ["Marking", "MARKING METHOD", [["", "How the pickup is marked - the crew calls the colour", "choice", [["choices", MARKS_GROUND]]]]],
    ["Heading", "LAND HEADING", [["", "Degrees", "number", [["min", 0], ["max", BUILTIN_HEADING_MAX]]]]],
    ["Wind", "WIND", [["", "Surface wind - filled from the game", "text", [["autoFill", "wind"]]]]],
    ["Obstacles", "OBSTACLES", [["", "Wires, trees, slope, debris at the pickup", "text", []]]],
    ["Remarks", "REMARKS", [["", "Remarks", "textarea", []]]]
], [
    ["anchor", "Pickup.A"],
    ["transitionsTo", "ISSUED"],
    ["replyableWith", _liftReplies + BUILTIN_HLZ_REPLIES],
    ["shortLines", ["Pickup"]],
    ["subject", "PICKUP {Pickup.A}"]
]];

// INSERTION (HLZ) (LIFT_CARDS) - after the pickup (user, 2026-11-08): filed
// in the PICKUP's thread it flies from there; filed alone it picks up at the
// sender first. THE FLOW (user, 2026-11-02: "2) troop load, all in 3) flight
// path 4) insertion 5) egress"): the route to the LZ and the egress after the
// drop, empty = the pilot picks.
_cards pushBack ["hlz", "INSERTION (HLZ)", "INSERT", [
    ["Line 6", format ["ROUTE TO THE LZ (UP TO %1, IN ORDER)", ROUTE_POINTS_MAX], ["Route", "direct"] call _fnc_points],
    ["Line 1", "DROP-OFF LZ", [["", "Grid / map position of the LZ", "grid", [["required", true], ["source", "mapClick"]]]]],
    // HOW THE TROOPS GO IN (user, 2026-11-08): a rope insertion comes in as
    // fast as it can, puts them down from the hover and leaves at once - no
    // LZ STATUS, no circle, no clearance.
    ["Insert", "INSERTION", [
        ["LAND", "Land at the LZ - LZ status, the mark, cleared to land", "bool", [["exclusive", "insert"]]],
        ["FAST ROPE", "ACE fast rope from the hover, in fast and out fast (the rappel where the airframe takes no FRIES)", "bool", [["exclusive", "insert"]]],
        ["RAPPEL", "Everyone aboard rappels from the hover, any airframe, in fast and out fast", "bool", [["exclusive", "insert"]]]
    ]],
    ["Line 4", "SECURITY AT THE DROP-OFF", [
        ["GREEN", "Secure, no threat", "bool", [["exclusive", "lz"]]],
        ["YELLOW", "Secure but threatened", "bool", [["exclusive", "lz"]]],
        ["RED", "Under fire", "bool", [["exclusive", "lz"]]]
    ]],
    ["Line 5", "MARKING METHOD", [["", "How the LZ is marked - the crew calls the colour", "choice", [["choices", MARKS_GROUND]]]]],
    ["Heading", "LAND HEADING", [["", "Degrees", "number", [["min", 0], ["max", BUILTIN_HEADING_MAX]]]]],
    ["Line 3", "PAX / LOAD", [["", "Passengers / load", "text", []]]],
    ["Line 7", format ["EGRESS AFTER THE DROP (UP TO %1, IN ORDER)", ROUTE_POINTS_MAX], ["Egress", "home direct"] call _fnc_points],
    ["Wind", "WIND", [["", "Surface wind - filled from the game", "text", [["autoFill", "wind"]]]]],
    ["Obstacles", "OBSTACLES", [["", "Wires, trees, slope, debris on the approach or the LZ", "text", []]]],
    ["Remarks", "REMARKS", [["", "Remarks", "textarea", []]]]
], [
    ["anchor", "Line1.A"],
    ["transitionsTo", "ISSUED"],
    ["replyableWith", _liftReplies + BUILTIN_HLZ_REPLIES],
    ["shortLines", ["Line 1", "Insert"]],
    ["subject", "INSERT {Line1.A}"]
]];

// EXTRACTION (HLZ) (user, 2026-11-02: "LIFT REQUEST (HLZ) seems to only be
// toward the drop off, need a pick up version where the pick up is the hot
// zone"): the transport flies the whole landing procedure at the pickup -
// a low hover there, never down - then home base on ALL IN (user,
// 2026-11-08: "extraction should be a low hover never touching the groups
// then rtb on all in"; EXTRACT_CARDS - no destination). THE FLOW ON THE
// CARD ("extraction: 1) on station 2) extraction 3) troop load, all in 4)
// egress"): the STATION it holds at until EXTRACT (a map marker, optional -
// empty, 1 km short of the HLZ), and up to ROUTE_POINTS_MAX EGRESS points
// flown from the HLZ on the way home.
_cards pushBack ["extract", "EXTRACTION (HLZ)", "EXTRACT", [
    ["Station", "STATION", [["", "Pick a map marker near the HLZ - it holds there until EXTRACT; empty = 1 km short of the HLZ", "grid", [["source", "marker"], ["markerOnly", true], ["noCur", true]]]]],
    ["Pickup", "PICKUP HLZ", [["", "Grid / map marker of the pickup - the hot zone", "grid", [["required", true], ["source", "mapClick"]]]]],
    ["Security", "LZ SECURITY", [
        ["GREEN", "Secure, no threat", "bool", [["exclusive", "lz"]]],
        ["YELLOW", "Secure but threatened", "bool", [["exclusive", "lz"]]],
        ["RED", "Under fire", "bool", [["exclusive", "lz"]]]
    ]],
    ["Marking", "MARKING METHOD", [["", "How the HLZ is marked - the crew calls the colour", "choice", [["choices", MARKS_GROUND]]]]],
    ["Passengers", "NUMBER OF PASSENGERS", [["", "How many to lift", "number", [["min", 1], ["max", BUILTIN_EXTRACT_PAX_MAX]]]]],
    ["Egress", format ["EGRESS (UP TO %1, IN ORDER)", ROUTE_POINTS_MAX], ["Egress", "direct"] call _fnc_points],
    ["Wind", "WIND", [["", "Surface wind - filled from the game", "text", [["autoFill", "wind"]]]]],
    ["Obstacles", "OBSTACLES", [["", "Wires, trees, slope, debris on the approach or the HLZ", "text", []]]],
    ["Remarks", "REMARKS", [["", "Threats at the pickup, casualties, who is in charge", "textarea", []]]]
], [
    ["anchor", "Pickup.A"],
    ["transitionsTo", "ISSUED"],
    ["replyableWith", _liftReplies + BUILTIN_EXTRACT_REPLIES],
    ["shortLines", ["Pickup", "Security"]],
    ["subject", "EXTRACT {Pickup.A}"]
]];

// PARADROP (DROP_CARDS): a transport flies it - supplies go by RESUPPLY.
_cards pushBack ["airdrop", "PARADROP", "PARADROP", [
    ["Line 1", "DROP ZONE", [["", "Grid / map position of the point of impact", "grid", [["required", true], ["source", "mapClick"]]]]],
    ["Contents", "LOAD", [["", "Who or what jumps", "text", []]]],
    ["Marking", "MARKING", [["", "How the DZ is marked - the crew calls the colour", "choice", [["choices", MARKS_GROUND]]]]],
    ["Line 6", "INGRESS LOCATION", [["", "Ingress point / run-in start", "grid", [["source", "mapClick"], ["noCur", true]]]]],
    ["Line 7", "EGRESS LOCATION", [["", "Egress point / off-target turn", "grid", [["source", "mapClick"], ["noCur", true]]]]],
    ["Remarks", "REMARKS", [["", "Remarks", "textarea", []]]]
], [
    ["anchor", "Line1.A"],
    ["transitionsTo", "ISSUED"],
    ["replyableWith", _liftReplies + ["nodrop"]],
    ["shortLines", ["Line 1"]],
    ["subject", "PARADROP {Line1.A}"]
]];

// REACT/QRF LINK-UP (QRF_CARDS): the link-up first, what the QRF does there a
// pick, the recognition signals.
_cards pushBack ["qrf", "REACT/QRF LINK-UP", "QRF", [
    ["Line 2", "LINK-UP LOCATION", [["", "Grid or map marker", "grid", [["required", true], ["source", "mapClick"]]]]],
    ["Line 5", "ACTION ON ARRIVAL", [
        ["", "What the QRF does there", "choice", [["choices", BUILTIN_QRF_ACTIONS]]],
        ["", "Detail", "text", []]
    ]],
    ["Signals", "RECOGNITION SIGNALS", [
        ["FAR ", "Far recognition: smoke, panel, IR", "text", []],
        ["NEAR ", "Near recognition: challenge and password, signal", "text", []]
    ]],
    ["Line 3", "SUGGESTED ROUTE", [["", "Route to the link-up site", "text", []]]],
    ["Line 4", "SPECIAL ATTACHMENTS NEEDED", [["", "Any special attachments needed", "text", []]]],
    ["Line 1", "WHO LINKS WITH WHO", [["", "Elements linking up; empty = you and the QRF", "text", []]]],
    ["Remarks", "REMARKS", [["", "Remarks", "textarea", []]]]
], [
    ["anchor", "Line2.A"],
    ["transitionsTo", "ISSUED"],
    ["replyableWith", BUILTIN_REPLIES + BUILTIN_QRF_REPLIES],
    ["shortLines", ["Line 2", "Line 5"]],
    ["subject", "QRF LINK-UP {Line2.A} - {Line1.A}"]
]];

// JUMP REQUEST (user, 2026-11-02: "change the halo/haho/static app in to a
// message based one"): the squad leader's jump for his squad, to the jump
// aircraft (jmfsb_jumpmaster). TYPE required, tick one; the passes; the exit;
// the RED LIGHT and GREEN LIGHT points, required, a map click or a marker;
// the pickup, empty = the sender's position (JUMP_CARDS). It answers to the
// root set and BOARD / GO / ABORT / RTB.
private _typeOpts = [["required", true], ["exclusive", "type"]];
_cards pushBack ["jump", "JUMP REQUEST", "JUMP", [
    ["Type", "TYPE", [
        ["HALO", "HALO - high altitude, low opening", "bool", _typeOpts],
        ["HAHO", "HAHO - high altitude, high opening", "bool", _typeOpts],
        ["STATIC", "Static line", "bool", _typeOpts]
    ]],
    ["Passes", "PASSES", [["", "Passes over the DZ; empty = the mission's default", "number", [["min", BUILTIN_JUMP_PASSES_MIN], ["max", BUILTIN_JUMP_PASSES_MAX]]]]],
    ["Exit", "EXIT", [
        ["AUTO", "Automatic at the green light", "bool", [["exclusive", "exit"]]],
        ["MANUAL", "Manual - each man jumps himself", "bool", [["exclusive", "exit"]]]
    ]],
    ["Red", "RED LIGHT", [["", "Grid / map marker - the red light, the run's start", "grid", [["required", true], ["source", "mapClick"], ["noCur", true]]]]],
    ["Green", "GREEN LIGHT", [["", "Grid / map marker - the green light, where the stick goes", "grid", [["required", true], ["source", "mapClick"], ["noCur", true]]]]],
    ["Pickup", "PICKUP", [["", "Grid / map marker - a strip, a marker; empty = your position", "grid", [["source", "mapClick"]]]]],
    ["Remarks", "REMARKS", [["", "Remarks", "textarea", []]]]
], [
    ["anchor", "Green.A"],
    ["transitionsTo", "ISSUED"],
    ["replyableWith", BUILTIN_REPLIES + BUILTIN_JUMP_REPLIES],
    ["shortLines", ["Type", "Red", "Green"]],
    ["subject", "JUMP {Red.A} - {Green.A}"]
]];

// THE BDA (report-card review, 2026-11-02, D33): filed in a thread - the
// usual case, answering REQUEST BDA - its target is the thread's own point
// (tacpad autoFill threadAnchor), so it is not required; a BDA says its
// RESULT or nothing.
_cards pushBack ["bda", "BATTLE DAMAGE ASSESSMENT", "BDA", [
    ["Target", "TARGET LOCATION", [["", "Target grid - in a thread, the thread's own point", "grid", [["source", "mapClick"], ["noCur", true], ["autoFill", "threadAnchor"]]]]],
    ["Result", "RESULT", [["", "What the strike did", "choice", [["required", true], ["choices", ["DESTROYED", "DAMAGED", "NO EFFECT", "NOT OBSERVED"]]]]]],
    _bdaCount,
    _bdaReattack,
    ["Remarks", "REMARKS", [["", "What was seen, what is left", "textarea", []]]]
], [
    ["kind", "both"],
    ["anchor", "Target.A"],
    ["allowedFrom", _live],
    ["roots", ROOTS_BDA],
    ["replyableWith", BUILTIN_REPLIES],
    ["shortLines", ["Result", "Reattack"]],
    ["subject", "BDA {Target.A} - {Result.A}"]
]];

// THE RESUPPLY (report-card review, 2026-11-02): an item's COUNT and the
// METHOD have readers that default them (1, the asset's first), so only the
// first item's name and the delivery point are required. Supplies by air come
// here, METHOD AIRDROP; the `airdrop` card is a PARADROP.
// THE ITEMS ARE PICKS OF THE PRE-MADE CRATES (user, 2026-11-02: "we have pre
// made crates so the requested items should be a drop down of them"): the
// composer fills them from the catalog of the logistics asset on the TO line,
// or of every logistics asset of the side (choicesFrom, CHOICES_LOGI_CATALOG);
// the card's own choices stay empty, so any name passes validation and the
// server matches it to the catalog as before. Each keeps its COUNT.
private _items = [];
for "_n" from 1 to BUILTIN_RESUPPLY_ITEMS do {
    private _pickOpts = [["choices", []], ["choicesFrom", CHOICES_LOGI_CATALOG]];
    if (_n isEqualTo 1) then {_pickOpts = [["required", true]] + _pickOpts};
    _items pushBack [format ["Item %1", _n], format ["ITEM %1", _n], [
        ["", "A pre-made crate from the logistics asset's catalog", "choice", _pickOpts],
        ["COUNT", "How many; empty = 1", "number", [["min", 1]]]
    ]];
};
_cards pushBack ["resupply", "RESUPPLY REQUEST", "RESUPPLY", _items + [
    ["Location", "DELIVERY POINT", [["", "Delivery grid", "grid", [["required", true], ["source", "mapClick"]]]]],
    ["Method", "METHOD", [["", "How it is delivered; empty = the asset's first", "choice", [["choices", ["AIRDROP", "SLING"]]]]]],
    ["Marking", "MARKING", [["", "What marks it on landing - the crew calls the colour", "choice", [["choices", MARKS_GROUND]]]]],
    ["Remarks", "REMARKS", [["", "Threats at the point, who receives it", "textarea", []]]]
], [
    ["anchor", "Location.A"],
    ["transitionsTo", "ISSUED"],
    ["replyableWith", BUILTIN_REPLIES + ["escort"]],
    ["shortLines", ["Item 1", "Location"]],
    ["subject", "RESUPPLY {Location.A} - {Method.A}"]
]];

// AREA IS A MAP MARKER (user, 2026-11-02: "REQUEST ON STATION should require
// a map marker"): required and markerOnly - the composer offers the marker
// list only, and the engine refuses a typed grid or none with PICK A MAP
// MARKER FOR THE AREA (EFUNC(messaging,validate)).
_cards pushBack ["onstation", "REQUEST ON STATION", "ON STATION", [
    ["Line 1", "TIME ON STATION (MIN)", [["", "Minutes wanted on station; empty = what the aircraft has", "number", [["min", 1], ["max", BUILTIN_STATION_MAX_MIN]]]]],
    ["Line 2", "AREA", [["", "Pick a map marker - the aircraft takes its station from it", "grid", [["required", true], ["source", "marker"], ["markerOnly", true], ["noCur", true]]]]],
    ["Remarks", "REMARKS", [["", "Threats, what it is wanted for", "textarea", []]]]
], [
    ["anchor", "Line2.A"],
    ["transitionsTo", "ISSUED"],
    ["replyableWith", BUILTIN_REPLIES + ["move"]],
    ["shortLines", ["Line 2"]],
    ["subject", "ON STATION {Line2.A}"]
]];

_cards
