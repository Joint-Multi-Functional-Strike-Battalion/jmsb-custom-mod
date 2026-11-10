#include "script_component.hpp"
/*
 * Author: YonV
 * The calls for fire the mod carries (part of FUNC(builtinCards), the one
 * entry point). THE MOD'S OWN CARD ALWAYS WINS (user, 2026-11-02): each is
 * the one used, whatever the TAC//PAC deck holds.
 *
 * CALL FOR FIRE AS THREE CARDS (user, 2026-11-02: "break arty in to 3 reports
 * grid polar and shift fire"): CFF GRID (`callforfire`, its keys unchanged),
 * CFF POLAR and CFF SHIFT. Each carries its target lines, then the same lines
 * - TYPE OF MISSION (required, tick one: "with call for fire Warno1 is still
 * needed"), the description, TARGET SHAPE and its far end or attitude, the
 * engagement and rounds, DANGER CLOSE (the card's 600 m), METHOD OF FIRE, the
 * control and the TOT (HHMM, HHMMSS or +M), the observer, the guns, REMARKS.
 * A polar or a shift is measured from the observer, so those two ask where he
 * is (Observer.B; empty = the sender). FUNC(readOrder) reads all three
 * (FIRE_CARDS); a battery answers them alike. THE ARTILLERY BY MESSAGE (user,
 * 2026-11-02, ideas from Tun Firesupport by Tuntematon / Armafinland): the
 * shape, the method of fire, the TOT to the second, RECORD AS TARGET among
 * their answers.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Cards, each [id, title, short, lines, options] <ARRAY>
 *
 * Example:
 * private _cards = [] call jmfsb_support_fnc_builtinFires
 *
 * Public: No
 */

private _fireReplies = BUILTIN_REPLIES + BUILTIN_CFF_REPLIES;
private _missionOpts = [["required", true], ["exclusive", "mission"]];

// The lines after the target; the observer's grid on a polar and a shift.
private _fnc_common = {
    params ["_observerGrid"];
    private _observer = [["", "Observer call sign; empty = you", "callsign", [["autoFill", "ownCallsign"]]]];
    if (_observerGrid) then {
        _observer pushBack ["", "Observer grid / map marker; empty = your position", "grid", [["source", "mapClick"]]];
    };
    [
        ["Warno 1", "TYPE OF MISSION", [
            ["A", "Adjust fire", "bool", _missionOpts],
            ["B", "Fire for effect", "bool", _missionOpts],
            ["C", "Suppress", "bool", _missionOpts],
            ["D", "Immediate suppression", "bool", _missionOpts]
        ]],
        ["Description", "TARGET DESCRIPTION", [["", "Target description", "textarea", []]]],
        // TARGET SHAPE (user, 2026-11-02): optional - none is a point.
        // Shape.A-D the tick, Shape.E the size; End.A a line's or a walk's
        // far end, End.B its attitude (FIRE_SHAPES, FIRE_CARDS).
        ["Shape", "TARGET SHAPE (EMPTY = POINT)", [
            ["A", "Point", "bool", [["exclusive", "shape"]]],
            ["B", "Area - the size is its radius", "bool", [["exclusive", "shape"]]],
            ["C", "Linear - to the far end, or the size at the attitude", "bool", [["exclusive", "shape"]]],
            ["D", "Creeping - walks to the far end, or the size along the attitude", "bool", [["exclusive", "shape"]]],
            ["", "Size (m) - radius or length", "number", [["min", 0], ["max", BUILTIN_CFF_SIZE_MAX]]]
        ]],
        ["End", "LINEAR / CREEPING - FAR END OR ATTITUDE", [
            ["", "Far end - grid / map marker", "grid", [["source", "mapClick"], ["noCur", true]]],
            ["", "Attitude (deg, 0-360); empty = across the line of fire (creeping: away from the guns)", "number", [["min", 0], ["max", BUILTIN_CFF_DIRECTION_MAX]]]
        ]],
        ["Engagement", "METHOD OF ENGAGEMENT", [
            ["A", "HE", "bool", [["exclusive", "shell"]]],
            ["B", "Smoke", "bool", [["exclusive", "shell"]]],
            ["C", "Illumination", "bool", [["exclusive", "shell"]]],
            ["D", "Cluster", "bool", [["exclusive", "shell"]]],
            ["E", "Laser-guided", "bool", [["exclusive", "shell"]]],
            ["F", "Airburst", "bool", [["exclusive", "shell"]]],
            ["", "Rounds per gun", "number", [["min", 1], ["max", BUILTIN_CFF_ROUNDS_MAX]]]
        ]],
        ["Danger Close", format ["DANGER CLOSE - UNDER %1 M", DANGER_CLOSE_ARTY], [
            ["DC", "Danger close - tick to acknowledge", "bool", []],
            ["", "Distance to friendlies (m) - optional, the server measures it", "number", [["min", 0], ["max", BUILTIN_CFF_FRIENDLIES_MAX]]]
        ]],
        // METHOD OF FIRE (user, 2026-11-02): optional - none is one volley.
        // Method.A the interval, Method.B the volleys, Method.C continuous
        // minutes.
        ["Method", "METHOD OF FIRE (EMPTY = ONE VOLLEY)", [
            ["INT", "Interval (s) between a gun's rounds", "number", [["min", 0], ["max", BUILTIN_CFF_INTERVAL_MAX]]],
            ["VOL", "Volleys", "number", [["min", 1], ["max", BUILTIN_CFF_VOLLEYS_MAX]]],
            ["CONT", "Or continuous for (min) - illumination kept up", "number", [["min", 0], ["max", BUILTIN_CFF_CONTINUOUS_MAX]]]
        ]],
        ["Control", "METHOD OF FIRE CONTROL", [
            ["A", "Fire when ready", "bool", [["exclusive", "control"]]],
            ["B", "At my command", "bool", [["exclusive", "control"]]],
            ["C", "Time on target", "bool", [["exclusive", "control"]]],
            ["D", "Cannot observe", "bool", [["exclusive", "control"]]]
        ]],
        ["TOT", "TIME ON TARGET (IF C) - HHMM, HHMMSS OR +MIN", [["", "TOT - 1430, 143015, or +5 for 5 min from now", "time", []]]],
        ["Observer", "OBSERVER ID/CALL SIGN", _observer],
        ["Warno 2", "GUNS", [["", "Guns to fire; empty = all", "number", [["min", 0], ["max", BUILTIN_CFF_GUNS_MAX]]]]],
        ["Remarks", "REMARKS", [["", "Remarks", "textarea", []]]]
    ]
};

// FLASH, ISSUED, the replies, its subject, the 600 m danger close (D8).
private _fnc_options = {
    params ["_subject", "_anchor", "_targetLine"];
    // THE SHORT FORM (2026-11-09): the target, the type of mission, the
    // description.
    private _options = [["priority", PRIORITY_FLASH], ["shortLines", [_targetLine, "Warno 1", "Description"]]];
    if (_anchor isNotEqualTo "") then {_options pushBack ["anchor", _anchor]};
    _options + [
        ["transitionsTo", "ISSUED"],
        ["replyableWith", +_fireReplies],
        ["subject", _subject],
        ["dangerClose", DANGER_CLOSE_ARTY]
    ]
};

private _cards = [];

// CFF GRID: the target by grid, required, no CUR LOC (Warno3A.A - the key the
// reader and the thread's anchor read).
_cards pushBack ["callforfire", "CALL FOR FIRE - GRID", "CFF GRID", [
    ["Warno 3A", "TARGET - GRID", [["", "Target grid (6-digit) or map marker", "grid", [["required", true], ["source", "mapClick"], ["noCur", true]]]]]
] + ([false] call _fnc_common), ["CFF GRID {Warno3A.A} - {Description.A}", "Warno3A.A", "Warno 3A"] call _fnc_options];

// CFF POLAR: direction and distance from the observer - the point is worked
// out by FUNC(readOrder), so no anchor.
_cards pushBack ["cffpolar", "CALL FOR FIRE - POLAR", "CFF POLAR", [
    ["Polar", "TARGET - POLAR FROM THE OBSERVER", [
        ["", "Direction (deg, 0-360) - mils not accepted", "number", [["required", true], ["min", 0], ["max", BUILTIN_CFF_DIRECTION_MAX]]],
        ["", "Distance (m)", "number", [["required", true], ["min", 1], ["max", BUILTIN_CFF_POLAR_MAX]]]
    ]]
] + ([true] call _fnc_common), ["CFF POLAR {Polar.A} {Polar.B} - {Description.A}", "", "Polar"] call _fnc_options];

// CFF SHIFT: a known point - a grid or a map marker - and the shift along the
// observer-target line.
_cards pushBack ["cffshift", "CALL FOR FIRE - SHIFT", "CFF SHIFT", [
    ["Known", "KNOWN POINT", [["", "Grid or map marker of the known point", "grid", [["required", true], ["source", "mapClick"], ["noCur", true]]]]],
    ["Lateral", "SHIFT - LEFT / RIGHT (M)", [
        ["", "Left or right", "choice", [["choices", ["LEFT", "RIGHT"]]]],
        ["", "Metres", "number", [["min", 0], ["max", BUILTIN_CFF_SHIFT_MAX]]]
    ]],
    ["Range", "SHIFT - ADD / DROP (M)", [
        ["", "Add or drop", "choice", [["choices", ["ADD", "DROP"]]]],
        ["", "Metres", "number", [["min", 0], ["max", BUILTIN_CFF_SHIFT_MAX]]]
    ]],
    ["Vertical", "SHIFT - UP / DOWN (M)", [
        ["", "Up or down", "choice", [["choices", ["UP", "DOWN"]]]],
        ["", "Metres", "number", [["min", 0], ["max", BUILTIN_CFF_SHIFT_MAX]]]
    ]]
] + ([true] call _fnc_common), ["CFF SHIFT {Known.A} - {Description.A}", "Known.A", "Known"] call _fnc_options];

_cards
