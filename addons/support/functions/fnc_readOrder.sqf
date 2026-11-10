#include "script_component.hpp"
/*
 * Author: YonV
 * Server: what a support card asks for, read off its fields by key - the one
 * reader every CAS provider shares (2026-11-01, DESIGN_SUPPORT_MESSAGING
 * section 4). Line titles are field keys (Line1.A ...), so the reader names
 * the keys and never counts lines; the deck stays the mission's data.
 *
 * A STRIKE (`cas` - one CAS card, user 2026-11-02) - kind "strike":
 *
 *   target       Line 1 as a position (FUNC(gridPos)), [] none
 *   label        Line 2, the map reference (an older deck's), "" none
 *   ingress      Line 3, [] = the provider picks
 *   egress       Line 4, [] = the provider picks
 *   description  Line 5, shown in the replies
 *   friendlies   Line 6 range from friendlies, m, -1 none
 *   dcTick       Line 6's DANGER CLOSE tick, or REMARKS saying DANGER CLOSE
 *   dangerClose  the card's `dangerClose` option, else DANGER_CLOSE_CAS m
 *   mark, code   Line 7, upper-cased (LASER, SMOKE ...) and its code / colour
 *   munition     the PREFERRED MUNITIONS line, "" = the provider picks
 *                (the 9-line has none since 2026-11-09 - munitions are in
 *                the remarks)
 *   remarks      REMARKS
 *   control      THE TYPE OF CONTROL (2026-11-09): 1, 2 or 3; 0 none ticked
 *   tot          the TOT line's text, "" none
 *
 * THE TRUE 9-LINE (2026-11-09): target is Line 6, ingress the IP / BP of
 * Line 1, egress Line 9, description Line 5, friendlies Line 8 (A the game's
 * direction and distance - text, so -1 here and the server measures; B the
 * DANGER CLOSE tick), mark and code Line 7; no label.
 *
 * REQUEST ON STATION (`onstation`, doc 1.1) - kind "station":
 *
 *   minutes      Line 1, time on station wanted, 0 = the aircraft's own
 *   area         Line 2, the AREA - a map marker's point, required since
 *                2026-11-02; [] (an older deck's empty line) = the provider
 *                picks
 *   remarks      REMARKS
 *
 * CALL FOR FIRE (step 6, 2026-11-01) - kind "fire", three cards since
 * 2026-11-02 (user: "break arty in to 3 reports grid polar and shift fire"):
 * `callforfire` CFF GRID, `cffpolar` CFF POLAR, `cffshift` CFF SHIFT, read
 * alike (FIRE_CARDS):
 *
 *   mission      Warno 1: "adjust", "ffe", "suppress", "immediate"; "" none
 *   guns         Warno 2 (size of element) - the first number in it, 0 = all
 *   target       the point, [] none: CFF GRID the Warno 3A grid; CFF POLAR
 *                the Polar line's direction and distance from the observer;
 *                CFF SHIFT the Lateral (LEFT / RIGHT), Range (ADD / DROP)
 *                metres from the Known point, on the observer-target line
 *                (vertical - UP / DOWN, m, up positive: support_fires lays the
 *                guns for the known point's height plus it). An older CFF GRID's polar
 *                (Warno 3B, or no grid and a Target 2 distance) and shift
 *                (Target 3 filled, or the Warno 3C tick) are still read
 *   method       "grid", "polar" or "shift"; known - the shift's known point
 *   observer     the card's Observer as a unit on the server (FUNC(observer)),
 *                else the issuer; observerName - the Observer line's text;
 *                observerPos - where he is: the Observer line's grid when
 *                given, else the sender's position (the named observer's
 *                when the line names another man)
 *   description  the target description
 *   shell        Engagement: "HE", "SMOKE", "ILLUM", "CLUSTER", "GUIDED",
 *                "AIRBURST"; "" = the provider picks. rounds - its number of
 *                rounds, -1 none
 *   dcTick       Danger Close ticked; friendlies - its distance, -1 none
 *   dangerClose  the card's `dangerClose` option, else DANGER_CLOSE_ARTY m
 *   control      Control: "ready", "command", "tot", "cannot", "checkfire",
 *                "again"; "" none. tot - the TOT line's text
 *   remarks      REMARKS
 *   shape        TARGET SHAPE (user, 2026-11-02), the Shape line's tick:
 *                "point", "area", "linear", "creeping"; "" none. size - its
 *                number (m, -1 none): an area's radius, a line's or a walk's
 *                length
 *   end          the End line's far end of a line or a walk, [] none;
 *                attitude - its direction (deg, -1 none)
 *   interval     METHOD OF FIRE (user, 2026-11-02), the Method line: the
 *                interval (s), volleys, continuous (min) - each -1 none
 *
 * THE OBSERVER'S REPLIES (step 6): `adjust` - kind "adjust", direction (ADD,
 * DROP, LEFT, RIGHT) and distance (m, -1 none), and corrections - every
 * [direction, metres] the card gives, the other axis second (2026-11-02);
 * `ffe` - kind "ffe", rounds (-1 = the mission's).
 *
 * STEP 7 (2026-11-01: transport, casevac, airdrop, resupply, QRF):
 *
 *   `pickup` - PICKUP (user, 2026-11-08: split from the insertion), kind
 *     "pickup": pickup (the Pickup line, [] - the sender), carry (Pax),
 *     marking, wind, obstacles, remarks
 *   `hlz` - INSERTION (HLZ), kind "lift": pickup always [] (the card has no
 *     pickup line since 2026-11-08), lz (Line 1, else Line
 *     2 as a marker), lzName (Line 2), carry (Line 3), security (Line 4,
 *     FUNC(lzSecurity): GREEN / YELLOW / RED / ""), marking (Line 5's words),
 *     route (the ROUTE line, Line 6 A-D: up to ROUTE_POINTS_MAX points from
 *     the pickup to the LZ, in order, [] direct - user, 2026-11-02) and
 *     egressRoute (the EGRESS line, Line 7 A-D, after the drop), ingress /
 *     egress (the first of each, [] none), wind, obstacles, remarks, insert
 *     (the INSERTION tick, INSERT_METHODS: land / rope / rappel; none - land;
 *     user, 2026-11-08)
  *   `casevac` - the 9-LINE CASEVAC (2026-11-09, ATP 4-02.2), kind "casevac":
 *     pickup (Line 1), callsign (Line 2), patients (the sum of Line 3, or of
 *     Line 5 when that is more), urgent / urgentSurg / priority / routine
 *     (Line 3 A-D), equipment (Line 4), litter / ambulatory (Line 5 A-B, -1
 *     none), security (Line 6 N / P / E / X, FUNC(lzSecurity) - GREEN /
 *     YELLOW / RED), marking (Line 7), nationality (Line 8), terrain (Line
 *     9), remarks
 *   `airdrop` - the PARADROP (2026-11-02), kind "drop": point (Line 1),
 *     contents (the Contents line: who or what jumps), marking (the Marking
 *     line), ingress / egress, remarks
 *   `resupply` - kind "supply": items [[name, count], ...] (Item N: its name
 *     and COUNT, count 1 when empty), point (the delivery point), method
 *     ("AIRDROP", "SLING", "" none), marking and colour, upper-cased, remarks
 *   `qrf` - kind "qrf": linkup (Line 2), who (Line 1), route, attachments,
 *     action (Line 5, upper-cased), remarks
 *   `extract` - EXTRACTION (HLZ) (user, 2026-11-02: the pickup is the hot
 *     zone), kind "extract": pickup (the PICKUP HLZ - no destination, home
 *     base on ALL IN, 2026-11-08), passengers (-1 none), security (LZ SECURITY,
 *     FUNC(lzSecurity)), marking, wind, obstacles, remarks, station (the
 *     STATION marker it holds at until EXTRACT, [] - the provider picks) and
 *     egressRoute (the EGRESS line A-D, flown from the HLZ, [] direct) - user,
 *     2026-11-02
 *   `jump` - JUMP REQUEST (user, 2026-11-02), kind "jump": type (the Type
 *     line's tick: "HALO", "HAHO", "STATIC"; "" none), passes (-1 none), exit
 *     (the Exit line's tick: "auto", "manual"; "" none), red and green (the
 *     RED LIGHT and GREEN LIGHT points, [] none), pickup ([] none - the
 *     provider takes the sender's position), remarks
 *   `pickup` and `hlz` carry heading too (LAND HEADING, 2026-11-09; -1 none)
 *   `move` - MOVE (2026-11-09, replaces DESTINATION), kind "move": point,
 *     arrival (MOVE_ARRIVALS: "LOITER", "LAND", "HOVER", "HOLD"; "" none),
 *     route (A-D, [] direct), altitude (m, -1 none), minutes (-1 - until
 *     told), remarks
 *   `freetext` - kind "destination", the answer to a CASEVAC's
 *     DESTINATION?: point ([] none), default (the DEFAULT answer: an empty
 *     destination, or a message saying DEFAULT), text
 *
 * STEP 5 (2026-11-01): `bda` - kind "bda", the observer's assessment: target
 * (the TARGET grid as a position, [] none; targetText - the line as typed),
 * effect (Result: DESTROYED / DAMAGED / NO EFFECT / NOT OBSERVED, upper-cased,
 * "" none), count (-1 none), reattack (the RE-ATTACK tick), decision (the
 * DECISION line, user 2026-11-02: BDA_REATTACK, BDA_EGRESS, "" neither - an
 * older deck; 2026-11-09 three picks - BDA_REATTACK, BDA_STATION back to
 * station, BDA_EGRESS the RTB), remarks
 *
 * Any other card: kind "". Every order carries "card" (its id).
 *
 * Arguments:
 * 0: Thread <HASHMAP>
 * 1: Its root message <HASHMAP>
 *
 * Return Value:
 * The order <HASHMAP>
 *
 * Example:
 * ([_thread, _message] call jmfsb_support_fnc_readOrder) get "target"
 *
 * Public: Yes
 */

params [["_thread", createHashMap, [createHashMap]], ["_message", createHashMap, [createHashMap]]];

private _cardId = _message getOrDefault ["templateId", _thread getOrDefault ["rootTemplateId", ""]];
private _values = createHashMapFromArray (_message getOrDefault ["payload", []]);

private _fnc_get = {
    params ["_key"];
    if (_key isEqualTo "") exitWith {""};
    _values getOrDefault [_key, ""]
};
private _fnc_text = {
    private _v = _this call _fnc_get;
    if (_v isEqualType "") exitWith {trim _v};
    if (_v isEqualType 0) exitWith {str _v};
    ""
};
// A number field arrives as a number, or as the text the composer kept.
private _fnc_number = {
    private _v = _this call _fnc_get;
    if (_v isEqualType 0) exitWith {_v};
    if (_v isEqualType "" && {(trim _v) regexMatch "^-?\d+(\.\d+)?$"}) exitWith {parseNumber (trim _v)};
    -1
};
private _fnc_pos = {
    private _v = _this call _fnc_get;
    if !(_v isEqualTypeAny [[], ""]) exitWith {[]};
    [_v] call FUNC(gridPos)
};

private _order = createHashMapFromArray [["card", _cardId], ["kind", ""]];

private _strike = STRIKE_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_strike >= 0) exitWith {
    (STRIKE_CARDS select _strike) params ["", "_kTarget", "_kLabel", "_kIn", "_kOut", "_kDesc", "_kFriendly", "_kTick", "_kMark", "_kCode", "_kMunition", "_kRemarks", ["_kControl", ""], ["_kTot", ""]];
    // THE TYPE OF CONTROL (2026-11-09): the ticked letter of the line, as
    // CAS_CONTROL_TYPES; 0 none ticked.
    private _control = 0;
    if (_kControl isNotEqualTo "") then {
        private _at = FIELD_LETTERS findIf {(_values getOrDefault [format ["%1.%2", _kControl, _x], false]) isEqualTo true};
        if (_at >= 0) then {_control = CAS_CONTROL_TYPES param [_at, 0]};
    };

    // The card's DANGER CLOSE tick, or a remark saying it - the net's way.
    private _remarks = [_kRemarks] call _fnc_text;
    private _tick = DANGER_CLOSE_WORDS in toUpper _remarks;
    if (!_tick && _kTick isNotEqualTo "") then {
        _tick = ([_kTick] call _fnc_get) isEqualTo true;
    };
    private _threshold = ([_cardId] call EFUNC(messaging,template)) getOrDefault ["dangerClose", 0];
    if !(_threshold isEqualType 0) then {_threshold = 0};
    if (_threshold <= 0) then {_threshold = DANGER_CLOSE_CAS};

    {_order set _x} forEach [
        ["kind", ORDER_STRIKE],
        ["target", [_kTarget] call _fnc_pos],
        ["label", [_kLabel] call _fnc_text],
        ["ingress", [_kIn] call _fnc_pos],
        ["egress", [_kOut] call _fnc_pos],
        ["description", [_kDesc] call _fnc_text],
        ["friendlies", [_kFriendly] call _fnc_number],
        ["dcTick", _tick],
        ["dangerClose", _threshold],
        ["mark", toUpper ([_kMark] call _fnc_text)],
        ["code", [_kCode] call _fnc_text],
        ["munition", [_kMunition] call _fnc_text],
        ["remarks", _remarks],
        ["control", _control],
        ["tot", [_kTot] call _fnc_text]
    ];
    _order
};

private _station = STATION_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_station >= 0) exitWith {
    (STATION_CARDS select _station) params ["", "_kMinutes", "_kArea", "_kRemarks"];
    {_order set _x} forEach [
        ["kind", ORDER_STATION],
        ["minutes", ([_kMinutes] call _fnc_number) max 0],
        ["area", [_kArea] call _fnc_pos],
        ["remarks", [_kRemarks] call _fnc_text]
    ];
    _order
};

// --- CALL FOR FIRE (step 6) ----------------------------------------------------
// The first ticked letter of a line, as the word at its place in a word list.
private _fnc_ticked = {
    params ["_line", "_words"];
    if (_line isEqualTo "") exitWith {""};
    private _at = FIELD_LETTERS findIf {(_values getOrDefault [format ["%1.%2", _line, _x], false]) isEqualTo true};
    if (_at < 0) exitWith {""};
    _words param [_at, ""]
};
// A shift's metres: the first number in the text, negative when it says one of
// the minus words or carries a minus sign.
private _fnc_shift = {
    params ["_key", "_minusWords"];
    private _text = toUpper ([_key] call _fnc_text);
    private _found = _text regexFind [NUMBER_PATTERN];
    if (_found isEqualTo []) exitWith {0};
    private _metres = parseNumber (((_found select 0) select 0) select 0);
    private _minus = SHIFT_MINUS in _text;
    if (!_minus) then {_minus = (_minusWords findIf {_x in _text}) >= 0};
    [_metres, -_metres] select _minus
};

// A shift line of CFF SHIFT (2026-11-02): its word (A) and metres (B), negative
// when the word is one of the minus words.
private _fnc_shiftLine = {
    params ["_line", "_minusWords"];
    if (_line isEqualTo "") exitWith {0};
    private _word = toUpper ([format ["%1.A", _line]] call _fnc_text);
    private _metres = ([format ["%1.B", _line]] call _fnc_number) max 0;
    [_metres, -_metres] select ((_minusWords findIf {_x in _word}) >= 0)
};

private _fire = FIRE_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_fire >= 0) exitWith {
    (FIRE_CARDS select _fire) params ["", "", "_kObserverGrid", "_kMission", "_kSize", "_kGrid", "_kPolar", "_kShift", "_kPolarLine", "_kShiftLine", "_kShiftLines", "_kDesc", "_kShell", "_kDanger", "_kControl", "_kTot", "_kRemarks", ["_kShape", ""], ["_kEnd", ""], ["_kMethod", ""]];

    // THE OBSERVER, for polar and shift: the card's, else the issuer - where
    // he is: the Observer line's grid when the card gives one, else the
    // sender's position, or the named observer's when the line names another
    // man (user, 2026-11-02).
    ([_thread, _message] call FUNC(observer)) params ["_observerName", "_observers"];
    private _issuerUid = [_thread] call FUNC(threadIssuer);
    private _issuerAt = allPlayers findIf {(getPlayerUID _x) isEqualTo _issuerUid};
    private _issuer = objNull;
    if (_issuerAt >= 0) then {_issuer = allPlayers select _issuerAt};
    private _observer = _observers param [0, objNull];
    if (_issuer in _observers) then {_observer = _issuer};
    if (isNull _observer) then {_observer = _issuer};
    private _observerPos = [_kObserverGrid] call _fnc_pos;
    if (_observerPos isEqualTo [] && !isNull _observer) then {
        (getPosATL _observer) params ["_ox", "_oy"];
        _observerPos = [_ox, _oy, 0];
    };

    private _grid = [_kGrid] call _fnc_pos;
    private _polarDir = [format ["%1.A", _kPolarLine]] call _fnc_number;
    private _polarDist = [format ["%1.B", _kPolarLine]] call _fnc_number;
    private _method = FIRE_BY_GRID;
    // A SHIFT IS A FILLED SHIFT LINE (report-card review, 2026-11-02, D07):
    // the deck dropped the "tick if shifting" helper; an older deck's tick
    // still says it. CFF SHIFT is a shift by what it is.
    private _shiftLateral = [format ["%1.A", _kShiftLine]] call _fnc_text;
    private _shiftRange = [format ["%1.B", _kShiftLine]] call _fnc_text;
    if (([_kShift] call _fnc_get) isEqualTo true || _shiftLateral isNotEqualTo "" || _shiftRange isNotEqualTo "") then {
        _method = FIRE_BY_SHIFT;
    };
    if (_kShiftLines isNotEqualTo []) then {_method = FIRE_BY_SHIFT};
    if (([_kPolar] call _fnc_get) isEqualTo true) then {_method = FIRE_BY_POLAR};
    if (_method isEqualTo FIRE_BY_GRID && _grid isEqualTo [] && _polarDist > 0) then {_method = FIRE_BY_POLAR};

    // The shift's metres: CFF SHIFT's lines, else an older CFF GRID's text.
    _kShiftLines params [["_kLateral", ""], ["_kRange", ""], ["_kVertical", ""]];
    private _lateral = [_kLateral, SHIFT_LEFT_WORDS] call _fnc_shiftLine;
    private _range = [_kRange, SHIFT_DROP_WORDS] call _fnc_shiftLine;
    if (_kShiftLines isEqualTo []) then {
        _lateral = [format ["%1.A", _kShiftLine], SHIFT_LEFT_WORDS] call _fnc_shift;
        _range = [format ["%1.B", _kShiftLine], SHIFT_DROP_WORDS] call _fnc_shift;
    };

    private _target = [];
    switch (_method) do {
        case FIRE_BY_GRID: {_target = _grid};
        case FIRE_BY_POLAR: {
            if (_observerPos isNotEqualTo [] && _polarDist > 0) then {
                (_observerPos getPos [_polarDist, _polarDir max 0]) params ["_px", "_py"];
                _target = [_px, _py, 0];
            };
        };
        case FIRE_BY_SHIFT: {
            if (_grid isNotEqualTo [] && _observerPos isNotEqualTo []) then {
                private _dir = _observerPos getDir _grid;
                ((_grid getPos [_range, _dir]) getPos [_lateral, _dir + SHIFT_RIGHT]) params ["_sx", "_sy"];
                _target = [_sx, _sy, 0];
            };
        };
    };

    // The rounds are the Engagement line's letter after its shells.
    private _rounds = [format ["%1.%2", _kShell, FIELD_LETTERS param [count FIRE_SHELLS, ""]]] call _fnc_number;
    private _size = toUpper ([_kSize] call _fnc_text);
    private _sizeFound = _size regexFind [NUMBER_PATTERN];
    private _guns = 0;
    if (_sizeFound isNotEqualTo []) then {_guns = parseNumber (((_sizeFound select 0) select 0) select 0)};

    private _threshold = ([_cardId] call EFUNC(messaging,template)) getOrDefault ["dangerClose", 0];
    if !(_threshold isEqualType 0) then {_threshold = 0};
    if (_threshold <= 0) then {_threshold = DANGER_CLOSE_ARTY};

    {_order set _x} forEach [
        ["kind", ORDER_FIRE],
        ["mission", [_kMission, FIRE_MISSIONS] call _fnc_ticked],
        ["guns", _guns],
        ["target", _target],
        ["method", _method],
        ["known", [[], _grid] select (_method isEqualTo FIRE_BY_SHIFT)],
        ["vertical", [_kVertical, SHIFT_DOWN_WORDS] call _fnc_shiftLine],
        ["observer", _observer],
        ["observerName", _observerName],
        ["observerPos", _observerPos],
        ["description", [_kDesc] call _fnc_text],
        ["shell", [_kShell, FIRE_SHELLS] call _fnc_ticked],
        ["rounds", _rounds],
        ["dcTick", ([format ["%1.A", _kDanger]] call _fnc_get) isEqualTo true],
        ["friendlies", [format ["%1.B", _kDanger]] call _fnc_number],
        ["dangerClose", _threshold],
        ["control", [_kControl, FIRE_CONTROLS] call _fnc_ticked],
        ["tot", [_kTot] call _fnc_text],
        ["remarks", [_kRemarks] call _fnc_text],
        // TARGET SHAPE and METHOD OF FIRE (user, 2026-11-02): the Shape
        // line's tick and its size after the ticks, the End line's far end
        // and attitude, the Method line's interval, volleys and minutes.
        ["shape", [_kShape, FIRE_SHAPES] call _fnc_ticked],
        ["size", [format ["%1.%2", _kShape, FIELD_LETTERS param [count FIRE_SHAPES, ""]]] call _fnc_number],
        ["end", [format ["%1.A", _kEnd]] call _fnc_pos],
        ["attitude", [format ["%1.B", _kEnd]] call _fnc_number],
        ["interval", [format ["%1.A", _kMethod]] call _fnc_number],
        ["volleys", [format ["%1.B", _kMethod]] call _fnc_number],
        ["continuous", [format ["%1.C", _kMethod]] call _fnc_number]
    ];
    _order
};

// --- THE OBSERVER'S REPLIES (step 6) ---------------------------------------------
private _adjust = ADJUST_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_adjust >= 0) exitWith {
    (ADJUST_CARDS select _adjust) params ["", "_kDirection", "_kDistance", ["_kSecond", ""], ["_kSecondDistance", ""]];
    // Every correction the card gives, in order: the first, then the other
    // axis when it is filled (report-card review, 2026-11-02, decision 10).
    private _corrections = [];
    {
        _x params ["_kDir", "_kDist"];
        private _dir = toUpper ([_kDir] call _fnc_text);
        if (_dir isEqualTo "") then {continue};
        _corrections pushBack [_dir, ([_kDist] call _fnc_number) max 0];
    } forEach [[_kDirection, _kDistance], [_kSecond, _kSecondDistance]];
    {_order set _x} forEach [
        ["kind", ORDER_ADJUST],
        ["direction", toUpper ([_kDirection] call _fnc_text)],
        ["distance", [_kDistance] call _fnc_number],
        ["corrections", _corrections]
    ];
    _order
};

private _ffe = FFE_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_ffe >= 0) exitWith {
    (FFE_CARDS select _ffe) params ["", "_kRounds"];
    {_order set _x} forEach [
        ["kind", ORDER_FFE],
        ["rounds", [_kRounds] call _fnc_number]
    ];
    _order
};

// --- STEP 7: TRANSPORT, CASEVAC, AIRDROP, RESUPPLY, QRF --------------------------
// The first of some keys that holds text, upper-cased (a marking the 6-line
// and the 9-line keep on different lines).
private _fnc_firstText = {
    private _found = "";
    {
        private _text = [_x] call _fnc_text;
        if (_text isNotEqualTo "" && {!(_text regexMatch NUMBER_ONLY_PATTERN)}) exitWith {_found = toUpper _text};
    } forEach _this;
    _found
};
// A point from a grid line, else from a line that names a marker.
private _fnc_posOr = {
    params ["_key", "_markerKey"];
    private _pos = [_key] call _fnc_pos;
    if (_pos isEqualTo []) then {_pos = [_markerKey] call _fnc_pos};
    _pos
};

// THE CARD'S FLIGHT PATH (user, 2026-11-02): a line's fields A to
// ROUTE_POINTS_MAX as points, in order, the empty ones left out.
private _fnc_points = {
    params ["_line"];
    if (_line isEqualTo "") exitWith {[]};
    private _points = (FIELD_LETTERS select [0, ROUTE_POINTS_MAX]) apply {[format ["%1.%2", _line, _x]] call _fnc_pos};
    _points select {_x isNotEqualTo []}
};

// THE PICKUP (user, 2026-11-08: the pickup report split from the insertion):
// always safe, so no security line.
private _pickupCard = PICKUP_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_pickupCard >= 0) exitWith {
    (PICKUP_CARDS select _pickupCard) params ["", "_kPickup", "_kCarry", "_kMarking", "_kWind", "_kObstacles", "_kRemarks", ["_kHeading", ""]];
    {_order set _x} forEach [
        ["kind", ORDER_PICKUP],
        ["pickup", [_kPickup] call _fnc_pos],
        ["carry", [_kCarry] call _fnc_text],
        ["marking", [_kMarking] call _fnc_firstText],
        ["wind", [_kWind] call _fnc_text],
        ["obstacles", [_kObstacles] call _fnc_text],
        ["remarks", [_kRemarks] call _fnc_text],
        ["heading", [_kHeading] call _fnc_number]
    ];
    _order
};

private _lift = LIFT_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_lift >= 0) exitWith {
    (LIFT_CARDS select _lift) params ["", "_kPickup", "_kLz", "_kName", "_kCarry", "_kMarking", "_kRoute", "_kOut", "_kWind", "_kObstacles", "_kRemarks", "_kInsert", ["_kHeading", ""]];
    private _route = [_kRoute] call _fnc_points;
    // nothing ticked - an older deck's card - is a landing
    private _insert = [_kInsert, INSERT_METHODS] call _fnc_ticked;
    if (_insert isEqualTo "") then {_insert = INSERT_METHODS select 0};
    private _egressRoute = [_kOut] call _fnc_points;
    {_order set _x} forEach [
        ["kind", ORDER_LIFT],
        ["pickup", [[], [_kPickup] call _fnc_pos] select (_kPickup isNotEqualTo "")],
        ["lz", [_kLz, _kName] call _fnc_posOr],
        ["lzName", [_kName] call _fnc_text],
        ["carry", [_kCarry] call _fnc_text],
        ["security", ["", _message] call FUNC(lzSecurity)],
        ["marking", [_kMarking] call _fnc_firstText],
        ["route", _route],
        ["egressRoute", _egressRoute],
        ["ingress", _route param [0, []]],
        ["egress", _egressRoute param [0, []]],
        ["wind", [_kWind] call _fnc_text],
        ["obstacles", [_kObstacles] call _fnc_text],
        ["remarks", [_kRemarks] call _fnc_text],
        ["insert", _insert],
        ["heading", [_kHeading] call _fnc_number]
    ];
    _order
};

private _casevac = CASEVAC_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_casevac >= 0) exitWith {
    (CASEVAC_CARDS select _casevac) params ["", "_kPickup", "_kPatients", "_kPriority", "_kMarkings", "_kRemarks", ["_kEquipment", ""], ["_kType", ""], ["_kNationality", ""], ["_kTerrain", ""], ["_kCallsign", ""]];
    // Line 3 by its letters: urgent, urgent-surg, priority, routine (the
    // 9-line, 2026-11-09) - the sum is the count; line 5 litter, ambulatory.
    private _byLetter = (FIELD_LETTERS select [0, CASEVAC_PRECEDENCE]) apply {([format ["%1.%2", _kPriority, _x]] call _fnc_number) max 0};
    private _sum = 0;
    {_sum = _sum + _x} forEach _byLetter;
    private _litter = -1;
    private _walking = -1;
    if (_kType isNotEqualTo "") then {
        _litter = [format ["%1.A", _kType]] call _fnc_number;
        _walking = [format ["%1.B", _kType]] call _fnc_number;
    };
    {_order set _x} forEach [
        ["kind", ORDER_CASEVAC],
        ["pickup", [_kPickup] call _fnc_pos],
        ["patients", ([_kPatients] call _fnc_number) max (_sum max ((_litter max 0) + (_walking max 0)))],
        ["urgent", _byLetter select 0],
        ["urgentSurg", _byLetter select 1],
        ["priority", _byLetter select 2],
        ["routine", _byLetter select 3],
        ["litter", _litter],
        ["ambulatory", _walking],
        ["equipment", toUpper ([_kEquipment] call _fnc_text)],
        ["nationality", toUpper ([_kNationality] call _fnc_text)],
        ["terrain", [_kTerrain] call _fnc_text],
        ["callsign", [_kCallsign] call _fnc_text],
        ["security", ["", _message] call FUNC(lzSecurity)],
        ["marking", _kMarkings call _fnc_firstText],
        ["remarks", [_kRemarks] call _fnc_text]
    ];
    _order
};

private _drop = DROP_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_drop >= 0) exitWith {
    (DROP_CARDS select _drop) params ["", "_kPoint", "_kContents", "_kMarking", "_kIn", "_kOut", "_kRemarks"];
    {_order set _x} forEach [
        ["kind", ORDER_DROP],
        ["point", [_kPoint] call _fnc_pos],
        ["contents", [_kContents] call _fnc_text],
        ["marking", [_kMarking] call _fnc_firstText],
        ["ingress", [_kIn] call _fnc_pos],
        ["egress", [_kOut] call _fnc_pos],
        ["remarks", [_kRemarks] call _fnc_text]
    ];
    _order
};

private _supply = SUPPLY_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_supply >= 0) exitWith {
    (SUPPLY_CARDS select _supply) params ["", "_kItem", "_kPoint", "_kMethod", "_kMarking", "_kColour", "_kRemarks"];
    private _items = [];
    for "_n" from 1 to SUPPLY_ITEMS_MAX do {
        private _name = [format ["%1%2.A", _kItem, _n]] call _fnc_text;
        if (_name isEqualTo "") then {continue};
        private _count = [format ["%1%2.B", _kItem, _n]] call _fnc_number;
        _items pushBack [toUpper _name, [round _count, 1] select (_count < 1)];
    };
    {_order set _x} forEach [
        ["kind", ORDER_SUPPLY],
        ["items", _items],
        ["point", [_kPoint] call _fnc_pos],
        ["method", toUpper ([_kMethod] call _fnc_text)],
        ["marking", toUpper ([_kMarking] call _fnc_text)],
        ["colour", toUpper ([_kColour] call _fnc_text)],
        ["remarks", [_kRemarks] call _fnc_text]
    ];
    _order
};

private _qrf = QRF_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_qrf >= 0) exitWith {
    (QRF_CARDS select _qrf) params ["", "_kWho", "_kLinkup", "_kRoute", "_kAttach", "_kAction", "_kRemarks"];
    {_order set _x} forEach [
        ["kind", ORDER_QRF],
        ["linkup", [_kLinkup] call _fnc_pos],
        ["who", [_kWho] call _fnc_text],
        ["route", [_kRoute] call _fnc_text],
        ["attachments", [_kAttach] call _fnc_text],
        ["action", toUpper ([_kAction] call _fnc_text)],
        ["remarks", [_kRemarks] call _fnc_text]
    ];
    _order
};

// EXTRACTION (HLZ) (user, 2026-11-02): the pickup is the hot zone; home base
// after it, always (2026-11-08: no destination).
private _extract = EXTRACT_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_extract >= 0) exitWith {
    (EXTRACT_CARDS select _extract) params ["", "_kPickup", "_kPax", "_kMarking", "_kWind", "_kObstacles", "_kRemarks", ["_kStation", ""], ["_kOut", ""]];
    private _egressRoute = [_kOut] call _fnc_points;
    {_order set _x} forEach [
        ["kind", ORDER_EXTRACT],
        ["pickup", [_kPickup] call _fnc_pos],
        ["passengers", [_kPax] call _fnc_number],
        ["security", ["", _message] call FUNC(lzSecurity)],
        ["marking", [_kMarking] call _fnc_firstText],
        ["wind", [_kWind] call _fnc_text],
        ["obstacles", [_kObstacles] call _fnc_text],
        ["remarks", [_kRemarks] call _fnc_text],
        ["station", [_kStation] call _fnc_pos],
        ["egressRoute", _egressRoute]
    ];
    _order
};

// THE JUMP REQUEST (user, 2026-11-02): the squad's jump, flown by
// jmfsb_jumpmaster. The type and the exit by their ticked letters; an empty
// pickup is the sender's, an empty passes or exit the mission's default -
// the provider's to fill.
private _jump = JUMP_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_jump >= 0) exitWith {
    (JUMP_CARDS select _jump) params ["", "_kType", "_kPasses", "_kExit", "_kRed", "_kGreen", "_kPickup", "_kRemarks"];
    {_order set _x} forEach [
        ["kind", ORDER_JUMP],
        ["type", [_kType, JUMP_TYPES] call _fnc_ticked],
        ["passes", [_kPasses] call _fnc_number],
        ["exit", [_kExit, JUMP_EXITS] call _fnc_ticked],
        ["red", [_kRed] call _fnc_pos],
        ["green", [_kGreen] call _fnc_pos],
        ["pickup", [_kPickup] call _fnc_pos],
        ["remarks", [_kRemarks] call _fnc_text]
    ];
    _order
};

// THE BDA (step 5, 2026-11-01): the observer's battle damage assessment.
private _bda = BDA_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_bda >= 0) exitWith {
    (BDA_CARDS select _bda) params ["", "_kTarget", "_kEffect", "_kCount", "_kReattack", "_kEgress", "_kRemarks", ["_kStation", ""]];
    // THE DECISION, THREE PICKS (2026-11-09): RE-ATTACK, BACK TO STATION or
    // RTB (BDA_EGRESS - the card's egress, home); none is an older deck's BDA.
    private _reattack = ([_kReattack] call _fnc_get) isEqualTo true;
    private _egress = ([_kEgress] call _fnc_get) isEqualTo true;
    private _station = ([_kStation] call _fnc_get) isEqualTo true;
    private _decision = "";
    if (_station) then {_decision = BDA_STATION};
    if (_egress) then {_decision = BDA_EGRESS};
    if (_reattack) then {_decision = BDA_REATTACK};
    {_order set _x} forEach [
        ["kind", ORDER_BDA],
        ["target", [_kTarget] call _fnc_pos],
        ["targetText", [_kTarget] call _fnc_text],
        ["effect", toUpper ([_kEffect] call _fnc_text)],
        ["count", [_kCount] call _fnc_number],
        ["reattack", _reattack],
        ["decision", _decision],
        ["remarks", [_kRemarks] call _fnc_text]
    ];
    _order
};

// RTB (2026-11-09): where players aboard get off before it goes home.
private _rtb = RTB_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_rtb >= 0) exitWith {
    (RTB_CARDS select _rtb) params ["", "_kLand"];
    {_order set _x} forEach [
        ["kind", ORDER_RTB],
        ["land", [_kLand] call _fnc_pos]
    ];
    _order
};

// MOVE (2026-11-09, replaces DESTINATION): a point, what it does there, the
// route, its altitude and how long it stays.
private _move = MOVE_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_move >= 0) exitWith {
    (MOVE_CARDS select _move) params ["", "_kPoint", "_kArrival", "_kRoute", "_kAltitude", "_kTime", "_kRemarks"];
    {_order set _x} forEach [
        ["kind", ORDER_MOVE],
        ["point", [_kPoint] call _fnc_pos],
        ["arrival", [_kArrival, MOVE_ARRIVALS] call _fnc_ticked],
        ["route", [_kRoute] call _fnc_points],
        ["altitude", [_kAltitude] call _fnc_number],
        ["minutes", [_kTime] call _fnc_number],
        ["remarks", [_kRemarks] call _fnc_text]
    ];
    _order
};

// THE CASEVAC'S DESTINATION: the card's grid (empty = DEFAULT), or a message
// that gives a grid or a marker, or says DEFAULT.
private _destination = DESTINATION_CARDS findIf {(_x select 0) isEqualTo _cardId};
if (_destination >= 0) exitWith {
    (DESTINATION_CARDS select _destination) params ["", "_kWhere", "_free"];
    private _text = [_kWhere] call _fnc_text;
    private _point = [_kWhere] call _fnc_pos;
    if (_point isEqualTo [] && _free) then {
        {
            if (_point isNotEqualTo []) exitWith {};
            _point = [_x] call FUNC(gridPos);
        } forEach ([_text] + (_text splitString WORD_SEPARATORS));
    };
    private _default = [_text isEqualTo "", DESTINATION_DEFAULT in toUpper _text] select _free;
    {_order set _x} forEach [
        ["kind", ORDER_DESTINATION],
        ["point", _point],
        ["default", _point isEqualTo [] && _default],
        ["text", _text]
    ];
    _order
};

_order
