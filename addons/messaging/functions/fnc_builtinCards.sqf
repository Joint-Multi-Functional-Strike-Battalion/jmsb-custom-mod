#include "script_component.hpp"
/*
 * Author: YonV
 * The reports and the replies every thread takes, as the mod carries them
 * (user, 2026-11-02: card changes reach the game with the mod - nobody runs a
 * script against the database). FUNC(registerBuiltins) registers them in this
 * addon's preInit; the mod's own card always wins - the TAC//PAC deck adds
 * only the ids the mod does not have (pac templatesApply). The support cards
 * are the support core's (jmfsb_support_fnc_builtinCards); these work without
 * it.
 *
 * Each card as the report-card review left it (docs/REVIEW_REPORT_CARDS_
 * 2026-11-02.md, user decisions 2026-11-02): required is only what the
 * receiver cannot act without; ROGER answers an open report (TIC, SITREP,
 * DEFREP - REPLIES_OPEN); the 6-LINE CASEVAC; SALUTE and MIST the original
 * full cards ("SALUTE and mist need to stay they are - the original way not
 * shortened"), CONTACTREP titled SALUTE ("call it a salute"); the SITREP a
 * report and a reply ("after contact a sitrep should be sent"); WILCO and ON
 * TASK carry the asset's DETAIL line. LINE TITLES ARE FIELD KEYS
 * (FUNC(registerTemplate)): the ALiVE forwarder reads SALUTE's S/A/L/U/T/E/R
 * and SITREP's Location/Enemy/Friendly/Civ/Status/Remarks.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Cards, each [id, title, short, lines, options] - the shape
 * FUNC(registerTemplate) takes <ARRAY>
 *
 * Example:
 * private _cards = [] call jmfsb_messaging_fnc_builtinCards
 *
 * Public: No
 */

private _cards = [];

// --- The reports ------------------------------------------------------------

// SALUTE (CONTACTREP): the original full card, only the title SALUTE.
_cards pushBack ["contactrep", "SALUTE", "SALUTE", [
    ["S", "SIZE", [["", "Size of the element", "text", [["required", true]]]]],
    ["A", "ACTIVITY", [["", "Activity the element is performing", "text", []]]],
    ["L", "LOCATION", [["", "Grid of contact", "grid", [["required", true], ["source", "mapClick"]]]]],
    ["U", "UNIT", [["", "Type of unit you believe the element to be", "text", []]]],
    ["T", "TIME", [["", "Time the unit was at this location", "time", [["autoFill", "missionTime"]]]]],
    ["E", "EQUIPMENT", [["", "Equipment the unit has", "textarea", []]]],
    ["R", "REMARKS", [["", "Remarks", "textarea", []]]]
], [
    ["anchor", "L.A"],
    ["reportable", "spotrep"],
    ["replyableWith", REPLIES_TASK],
    ["subject", "CONTACT {S.A} {U.A} - {L.A}"]
]];

// MIST: the original full card.
// The PATIENT line (2026-11-07): one MIST thread per patient - the watch HUD's
// medical REPORT finds his thread by "MIST <patient>" and replies into it.
_cards pushBack ["mist", "MIST", "MIST", [
    ["Patient", "PATIENT", [["", "Who - name or callsign", "text", []]]],
    ["M", "MECHANISM OF INJURY & TIME", [["", "What caused it and when", "text", [["required", true]]]]],
    ["I", "INJURIES SUSTAINED", [["", "Injuries sustained", "textarea", []]]],
    ["S", "SYMPTOMS AND VITALS", [["", "A-Airway B-Breathing C-Pulse D-Responsive E-Everything else", "textarea", []]]],
    ["T", "TREATMENT GIVEN", [["", "Treatment given", "textarea", []]]],
    ["Remarks", "REMARKS", [["", "Remarks", "textarea", []]]]
], [
    // A REPORT AND A FOLLOW-UP (2026-11-09): MIST follows the CASEVAC in its
    // thread, per patient, and never holds it up. One form, unshortened
    // (decision 2).
    ["kind", KIND_BOTH],
    ["replyableWith", REPLIES_TASK],
    ["subject", "MIST {Patient.A} - {M.A}"]
]];

// TROOPS IN CONTACT - QUICK AND SIMPLE (user, 2026-11-02: "most of the time
// only the button will be pressed"): only the location is required, and the
// TIC key fills it, so one press sends it.
_cards pushBack ["tic", "TROOPS IN CONTACT", "TIC", [
    ["Location", "LOCATION", [["", "Grid / map position of the contact", "grid", [["required", true], ["source", "mapClick"]]]]],
    ["Enemy", "ENEMY", [["", "What is shooting at you", "text", []]]],
    ["Casualties", "FRIENDLY CASUALTIES", [["", "Friendly casualties", "text", []]]],
    ["Intentions", "INTENTIONS", [["", "What you intend to do", "text", []]]],
    ["Assistance", "ASSISTANCE REQUIRED", [["", "Any assistance required", "text", []]]],
    ["Remarks", "REMARKS", [["", "Remarks", "textarea", []]]]
], [
    ["priority", PRIORITY_FLASH],
    ["anchor", "Location.A"],
    ["broadcast", "tic"],
    ["replyableWith", REPLIES_OPEN],
    ["shortLines", ["Location"]],
    ["subject", "TIC {Location.A} - {Enemy.A}"]
]];

// SITREP, kind "both" (user, 2026-11-02: "after contact a sitrep should be
// sent"): SEND SITREP on a TIC thread files it inside that thread. No call
// sign line - the sender is on every message. AMMO and CAS fill from the
// squad's ACE letters (tacpad autoFill squadAce).
_cards pushBack ["sitrep", "SITREP", "SITREP", [
    ["Location", "LOCATION", [["", "Grid", "grid", [["source", "mapClick"]]]]],
    ["Enemy", "ENEMY SITUATION", [
        ["", "Enemy strength / activity", "text", []],
        ["EKIA ", "Enemy KIA", "number", [["min", 0], ["max", SITREP_COUNT_MAX]]]
    ]],
    ["Friendly", "FRIENDLY SITUATION", [
        ["", "Friendly forces / posture", "text", []],
        ["FKIA ", "Friendly KIA", "number", [["min", 0], ["max", SITREP_COUNT_MAX]]],
        ["FWIA ", "Friendly WIA", "number", [["min", 0], ["max", SITREP_COUNT_MAX]]]
    ]],
    ["Civ", "CIVILIAN SITUATION", [["", "Civilian presence / casualties", "text", []]]],
    ["Status", "STATUS (GREEN/AMBER/RED/BLACK)", [
        ["AMMO ", "Ammo state - the squad's ACE A", "choice", [["choices", REPORT_STATES], ["autoFill", "squadAce:A"]]],
        ["CAS ", "Medical / casevac state - the squad's ACE C", "choice", [["choices", REPORT_STATES], ["autoFill", "squadAce:C"]]],
        ["VEH ", "Vehicle state", "choice", [["choices", REPORT_STATES]]],
        ["CE ", "Combat effectiveness", "choice", [["choices", REPORT_STATES]]]
    ]],
    ["Remarks", "REMARKS", [["", "Remarks", "textarea", []]]]
], [
    ["kind", KIND_BOTH],
    ["anchor", "Location.A"],
    ["reportable", "sitrep"],
    ["replyableWith", REPLIES_OPEN],
    ["shortLines", ["Location", "Status"]],
    ["subject", "SITREP {Location.A}"]
]];

// 9-LINE CASEVAC (ATP 4-02.2 Table C-1; docs/DESIGN_MESSAGE_TEMPLATES.md
// decision 1, 2026-11-09 - it replaces the 6-line of Nov 2). The count is the
// sum of line 3 (A urgent, B urgent-surg, C priority, D routine); line 6 is
// SECURITY N / P / E / X; line 7 the marking method only - the crew calls the
// colour and the requester verifies it. MIST follows in the thread. The
// support core's lift reads these keys (CASEVAC_CARDS). Short: lines 1, 3, 6.
_cards pushBack ["casevac", "9-LINE CASEVAC", "CASEVAC", [
    ["Line 1", "LOCATION OF PICKUP SITE", [["", "Grid / map position of the pickup site", "grid", [["required", true], ["source", "mapClick"]]]]],
    ["Line 2", "CALL SIGN / NET", [["", "Filled from the sender", "callsign", [["autoFill", "ownCallsign"]]]]],
    ["Line 3", "PATIENTS BY PRECEDENCE", [
        ["A URGENT ", "Urgent", "number", [["min", 0], ["max", CASEVAC_PATIENTS_MAX]]],
        ["B URGENT-SURG ", "Urgent surgical", "number", [["min", 0], ["max", CASEVAC_PATIENTS_MAX]]],
        ["C PRIORITY ", "Priority", "number", [["min", 0], ["max", CASEVAC_PATIENTS_MAX]]],
        ["D ROUTINE ", "Routine", "number", [["min", 0], ["max", CASEVAC_PATIENTS_MAX]]]
    ]],
    ["Line 4", "SPECIAL EQUIPMENT", [["", "What the crew must bring", "choice", [["choices", CASEVAC_EQUIPMENT]]]]],
    ["Line 5", "PATIENTS BY TYPE", [
        ["LITTER ", "Litter", "number", [["min", 0], ["max", CASEVAC_PATIENTS_MAX]]],
        ["AMBULATORY ", "Ambulatory", "number", [["min", 0], ["max", CASEVAC_PATIENTS_MAX]]]
    ]],
    ["Line 6", "SECURITY AT PICKUP SITE", [
        ["N", "No enemy troops in the area", "bool", [["exclusive", "security"]]],
        ["P", "Possible enemy troops - approach with caution", "bool", [["exclusive", "security"]]],
        ["E", "Enemy troops in the area - approach with caution", "bool", [["exclusive", "security"]]],
        ["X", "Enemy troops in the area - armed escort required", "bool", [["exclusive", "security"]]]
    ]],
    ["Line 7", "METHOD OF MARKING", [["", "How the site is marked - the crew calls the colour", "choice", [["choices", CASEVAC_MARKS]]]]],
    ["Line 8", "PATIENT NATIONALITY AND STATUS", [["", "Nationality and status", "choice", [["choices", CASEVAC_NATIONALITY]]]]],
    ["Line 9", "CBRN / TERRAIN", [["", "CBRN contamination, or the terrain at the site", "text", []]]],
    ["Remarks", "REMARKS", [["", "Anything the crew must know - MIST follows in the thread", "textarea", []]]]
], [
    ["priority", PRIORITY_FLASH],
    ["transitionsTo", "ISSUED"],
    ["replyableWith", REPLIES_TASK + REPLIES_LIFT],
    ["anchor", "Line1.A"],
    ["shortLines", ["Line 1", "Line 3", "Line 6"]],
    ["subject", "CASEVAC {Line1.A}"]
]];

// FRAGO (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09): no lines of its own -
// the composer opens the thread's current tasking card with its last values,
// and what is sent is only what changed. The card it names rides in Card.A,
// each changed field under its own key, the value it had under the key +
// FRAGO_WAS (openFields - FUNC(validate) keeps them; FUNC(srvSubmit) checks
// the merged order against the tasking card). The issuer's, in an open thread.
_cards pushBack ["frago", "FRAGO", "FRAGO", [
    ["Card", "ORDER", [["", "The order it changes - filled by the composer", "text", [["required", true]]]]],
    ["Reason", "REASON", [["", "Optional", "text", []]]]
], [
    ["kind", KIND_REPLY],
    ["allowedFrom", STATES_ANY_OPEN],
    ["senderMustBe", "issuer"],
    ["openFields", true],
    ["assetThread", true],
    ["subject", "FRAGO {Reason.A}"]
]];

// VEHICLE REPORT (DEFREP): the vehicle, its damage and fuel filled from the
// vehicle the sender is in (tacpad autofills); the ROUTING tick also mails the
// command group.
private _fnc_ticks = {
    params ["_tag", "_hints", ["_auto", ""]];
    private _extra = [[], [["autoFill", _auto]]] select (_auto isNotEqualTo "");
    private _ticks = [];
    {
        _ticks pushBack [_x, _hints select _forEachIndex, "bool", [["exclusive", _tag]] + _extra];
    } forEach ["GREEN", "YELLOW", "RED", "BLACK"];
    _ticks
};
_cards pushBack ["defrep", "VEHICLE REPORT (DEFREP)", "DEFREP", [
    ["Vehicle", "VEHICLE", [["", "Call sign / type - filled from the vehicle you are in", "text", [["autoFill", "vehicle"]]]]],
    ["Line 1", "DAMAGE", ["damage", ["No damage", "Slight damage, still combat effective", "Not combat effective", "Destroyed"], "vehicleDamage"] call _fnc_ticks],
    ["Line 2", "EQUIPMENT", ["equipment", ["No damage", "Slight damage, can carry on with mission", "Major damage to equipment", "No longer mission capable"]] call _fnc_ticks],
    ["Line 3", "FUEL", ["fuel", ["More than 1/2", "Less than 1/2", "Less than 1/4", "EMPTY!"], "vehicleFuel"] call _fnc_ticks],
    ["Remarks", "REMARKS", [["", "Remarks", "textarea", []]]],
    ["Command", "ROUTING", [["CMD", "Also send to the command group", "bool", []]]]
], [
    ["routing", "Command.A"],
    ["replyableWith", REPLIES_OPEN],
    ["shortLines", ["Vehicle", "Line 1", "Line 3"]],
    ["subject", "DEFREP {Vehicle.A}"]
]];

// UXO / IED 9-LINE (2026-11-07, the watch HUD's engineer report): the
// explosive hazard spot report, line by line. The engineer profile fills 1-4.
_cards pushBack ["uxo9", "UXO / IED 9-LINE", "UXO", [
    ["1", "DATE-TIME GROUP", [["", "When it was found", "time", [["autoFill", "missionTime"]]]]],
    ["2", "REPORTING UNIT AND LOCATION", [["", "Unit and grid of the item", "text", [["required", true]]]]],
    ["3", "CONTACT METHOD", [["", "Callsign / net to reach the reporter", "text", []]]],
    ["4", "TYPE OF ORDNANCE", [["", "Dropped, projected, placed or thrown - and how many", "text", [["required", true]]]]],
    ["5", "CBRN CONTAMINATION", [["", "Any CBRN sign - none if none", "text", []]]],
    ["6", "RESOURCES THREATENED", [["", "Equipment, facilities, routes at risk", "text", []]]],
    ["7", "IMPACT ON MISSION", [["", "How it affects the mission", "text", []]]],
    ["8", "PROTECTIVE MEASURES", [["", "Marked, cordoned, evacuated - what was done", "text", []]]],
    ["9", "RECOMMENDED PRIORITY", [["", "Immediate, indirect, minor or no threat", "text", [["required", true]]]]]
], [
    ["replyableWith", REPLIES_TASK],
    ["shortLines", ["2", "4", "9"]],
    ["subject", "UXO {4.A} - {2.A}"]
]];

// MESSAGE: free text, a report or a reply.
_cards pushBack ["freetext", "MESSAGE", "MSG", [
    ["Text", "MESSAGE", [["", "Anything the templates do not cover", "textarea", [["required", true]]]]]
], [
    ["kind", KIND_BOTH],
    ["replyableWith", REPLIES_TASK],
    ["subject", "{Text.A}"]
]];

// --- The replies every thread takes -----------------------------------------

// ROGER answers a task and an open report (decision 3).
_cards pushBack ["roger", "ROGER", "ROGER", [], [
    ["kind", KIND_REPLY],
    ["transitionsTo", "RECEIPT"],
    ["allowedFrom", ["ISSUED", "OPEN"]]
]];
// WILCO and ON TASK carry what the asset says (decision 8 - `accepted` and
// `ontask`, the same replies twice, are retired: CARDS_RETIRED).
private _detail = ["Text", "DETAIL", [["", "Optional, e.g. ETA 2:40", "text", []]]];
_cards pushBack ["wilco", "WILCO", "WILCO", [_detail], [
    ["kind", KIND_REPLY],
    ["transitionsTo", "ACCEPTED"],
    ["allowedFrom", ["ISSUED", "RECEIPT"]],
    ["senderMustBe", "assignee"]
]];
_cards pushBack ["inprogress", "ON TASK", "ON TASK", [_detail], [
    ["kind", KIND_REPLY],
    ["transitionsTo", "IN_PROGRESS"],
    ["allowedFrom", ["ACCEPTED", "RECEIPT"]],
    ["senderMustBe", "assignee"]
]];
_cards pushBack ["cantco", "CANTCO", "CANTCO", [
    ["Reason", "REASON UNABLE TO COMPLY", [["", "Why not", "textarea", [["required", true]]]]]
], [
    ["kind", KIND_REPLY],
    ["priority", PRIORITY_FLASH],
    ["transitionsTo", "DECLINED"],
    ["allowedFrom", STATES_ANY_OPEN],
    ["senderMustBe", "assignee"],
    ["subject", "CANTCO - {Reason.A}"]
]];
_cards pushBack ["close", "CLOSE THREAD", "CLOSE", [
    ["Outcome", "OUTCOME / END OF MISSION", [["", "How it ended", "text", []]]]
], [
    ["kind", KIND_REPLY],
    ["transitionsTo", "CLOSED"],
    ["senderMustBe", "issuer"]
]];

_cards
