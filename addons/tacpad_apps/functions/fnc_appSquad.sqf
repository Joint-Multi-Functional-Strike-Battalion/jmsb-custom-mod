#include "script_component.hpp"
/*
 * Author: JMSB
 * SQUAD STATUS, full size, to the design: the section as a table on the left and
 * the summary, the dispersion and your own ACE report down a rail on the right.
 *
 * The rail on the map answers "is anyone hurt". This answers "where is everyone,
 * what have they got left, and what do I tell higher" - which is three questions
 * that need a table, and one that needs a form.
 *
 * A LEADER GETS THE PLATOON. A man the mission flags isLeader sees every squad
 * on his side - the declared squads first, in the order the mission declares
 * them, then any other group with a player in it. Each squad is one header row
 * until it is opened; his own opens itself. Everyone else gets the section view
 * this app has always been, untouched - a rifleman has no platoon to read.
 *
 * THE ACE COLUMN IS REPORTED, NOT MEASURED. Ammunition can be counted off a
 * man's kit; casualties and equipment cannot - "my optic is out" is not
 * something the engine knows. So the column shows what each man last SENT, and
 * the form at the bottom of the rail is how you send yours.
 *
 * A MAN WHO HAS NOT REPORTED READS GREEN. It read as a dim nothing, which meant
 * a section that had not touched the screen showed no state at all and the first
 * job of every leader was to ask eight men to press three buttons to say that
 * nothing had happened. The report is for the exceptions.
 *
 * THERE IS NO REPORT TO SEND. A man's letters are published onto his unit the
 * moment he presses them, every roster in the suite draws off that variable,
 * and the platoon view is how a leader reads the lot at once - so the old
 * SEND TEAM ACE REPORT button, and the ace template behind it, were a second
 * copy of a state the screen already carries live. Both are gone.
 *
 * Arguments (app handler):
 * 0: Map display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];

if (isNull _display) exitWith {};

// The mission's framework compiles the customVariable "true" to a real boolean
// before it lands on the unit; anything else that ends up in the variable reads
// as not a leader rather than throwing in an if.
private _platoon = (player getVariable ["isLeader", false]) isEqualTo true;

([_display, ["SQUAD STATUS", "PLATOON STATUS"] select _platoon, 0.84, 0.78] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
private _pos = ctrlPosition _body;
private _w = _pos # 2;
private _h = _pos # 3;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];

// The rail is fixed and the table takes what is left, so a narrow screen costs
// the table columns rather than making the form unusable.
private _railW = _w * 0.26;
private _tw = _w - _railW - RULE_THICK * pixelW;

[_body, [_tw, 0, RULE_THICK * pixelW, _h], _ink] call EFUNC(tacpad,drawFill);

// ------------------------------------------------------------ the roster ----
// One section for a section leader; every squad for a platoon leader. The
// declared squads come off the mission config - the same list the messaging
// nets are built from, so the screen and the radio agree about what a squad is
// called - and any other group with a player in it follows, so an ad-hoc
// detachment does not vanish off the platoon picture for not being declared.
private _sections = [];
if (_platoon) then {
    private _own = group player;
    private _live = allGroups select {
        side _x == side _own && {(units _x) findIf {isPlayer _x} > -1}
    };

    private _ordered = [];
    {
        private _name = _x;
        private _i = _live findIf {groupId _x == _name};
        if (_i > -1) then {_ordered pushBack (_live deleteAt _i)};
    } forEach ([] call EFUNC(messaging,squadNets));
    _ordered append _live;

    // Open state is the player's, per squad, and survives the app closing -
    // because toggling a header IS the app closing and reopening. A squad with
    // no saved state answers the default: your own open, the rest folded.
    _sections = _ordered apply {
        [_x, GVAR(platoonOpen) getOrDefault [groupId _x, _x isEqualTo _own]]
    };
} else {
    _sections = [[group player, true]];
};

// ------------------------------------------------------- measure the men ----
// Every man is measured HERE, before anything is drawn, so a folded squad still
// counts in the rail totals, still feeds the ammunition average and can still
// put its casualty on the CASEVAC button. Drawing is what a header toggles;
// counting is not. Each section grows its rows - [unit, out, health, hurt] -
// and a one-line summary for its header.
private _alive = 0;
private _wia = 0;
private _uncon = 0;
private _kia = 0;
private _ammoSum = 0;
private _ammoCount = 0;
private _worst = objNull;
private _worstUrgent = false;
private _units = [];

// EACH MAN'S SKILLS, ONCE PER REDRAW. Off the roster TAC//PAC publishes -
// uid -> "MED JFO" - so a leader sees who the medic is without asking. An AI
// has no uid and no row; a mission without pac shows nothing here.
private _skillsOf = createHashMap;
if (!isNil "jmfsb_pac_fnc_lookup") then {
    {
        _x params ["_uid", "", "", "", "", "", "_skillIds"];
        // [abbrev, id] pairs - the id is what the colour is looked up by
        _skillsOf set [_uid, _skillIds apply {
            private _ab = ["skills", _x, "abbrev"] call jmfsb_pac_fnc_lookup;
            [[toUpper _x, _ab] select (_ab isNotEqualTo "" && {_ab isNotEqualTo "(" + _x + "?)"}), _x]
        }];
    } forEach (missionNamespace getVariable ["jmfsb_pac_roster", []]);
};

{
    _x params ["_grp", "_open"];
    private _members = (units _grp) select {!isNull _x};
    private _rows = [];
    private _gWia = 0;
    private _gUncon = 0;
    private _gKia = 0;

    {
        private _unit = _x;

        private _out = if (isNil QEFUNC(common,isUnconscious)) then {
            lifeState _unit == "INCAPACITATED"
        } else {
            [_unit] call EFUNC(common,isUnconscious)
        };

        private _health = round ((1 - damage _unit) * 100);
        private _hurt = alive _unit && {!_out} && _health < 90;

        switch (true) do {
            case (!alive _unit): {_kia = _kia + 1; _gKia = _gKia + 1};
            case (_out): {_uncon = _uncon + 1; _gUncon = _gUncon + 1; _alive = _alive + 1};
            case (_hurt): {_wia = _wia + 1; _gWia = _gWia + 1; _alive = _alive + 1};
            default {_alive = _alive + 1};
        };

        // The worst man is who the CASEVAC button is for. Unconscious outranks
        // wounded whatever order the roster happens to be listed in, and a man
        // already dead does not need an aircraft.
        if (_out && {!_worstUrgent}) then {_worst = _unit; _worstUrgent = true};
        if (_hurt && {isNull _worst}) then {_worst = _unit};

        // Still counted, still shown in the STRENGTH block as the average - it
        // is a useful number about the force. It is not a column about a man.
        ([_unit] call FUNC(ammoState)) params ["_ammoPct"];
        if (_ammoPct >= 0) then {
            _ammoSum = _ammoSum + _ammoPct;
            _ammoCount = _ammoCount + 1;
        };

        _rows pushBack [_unit, _out, _health, _hurt];
    } forEach _members;

    _units append _members;

    // The flags are what a folded header owes the leader: trouble he can see
    // without opening the squad. A squad with none flies no flags.
    private _flags = [];
    if (_gUncon > 0) then {_flags pushBack format ["%1 DOWN", _gUncon]};
    if (_gWia > 0) then {_flags pushBack format ["%1 WIA", _gWia]};
    if (_gKia > 0) then {_flags pushBack format ["%1 KIA", _gKia]};

    _x set [2, _rows];
    _x set [3, format ["%1 EFFECTIVE / %2", (count _members) - _gWia - _gUncon - _gKia, count _members]];
    _x set [4, _flags joinString "  "];
} forEach _sections;

// ------------------------------------------------------------- the table ----
// Column edges as fractions of the table, so the header and every row are laid
// out from one list and cannot disagree about where a column starts.
//
// RADIO is each man's own published channel - see FUNC(radioState) for why it
// has to arrive that way. PING is the design's and is not here: there is no
// scripting command for it, and a column of invented latencies is worse than a
// column that is missing. RANGE takes that space, and is the thing a leader
// actually reads off a roster on a map screen.
//
// NO AMMO COLUMN. It is a magazine count dressed as a readiness state, and the
// section already reports its ammunition properly - the A of the ACE column two
// places to its left, which is a man's own claim rather than a number counted
// off his vest. Two answers to one question, and the worse one took a column.
//
// The seven that are left get the width it was using: a table that has to be
// read at a glance off a map screen wants air between its columns more than it
// wants another of them.
// SKILLS IS THE WIDE ONE (user, 2026-09-05: "make wider so all these skills
// show") - nine three-letter codes on one line. ROLE is two letters and gives
// up the width; STATUS keeps enough for "WIA - 85% remaining".
private _cols = [
    ["CALLSIGN", 0.000, "left"],
    ["ROLE", 0.150, "left"],
    ["SKILLS", 0.205, "left"],
    ["STATUS", 0.420, "left"],
    ["ACE", 0.560, "left"],
    ["GRID", 0.710, "left"],
    ["RADIO", 0.815, "left"],
    ["RANGE", 0.925, "right"]
];
private _aceCol = _cols findIf {(_x # 0) isEqualTo "ACE"};

{
    _x params ["_label", "_at", "_align"];
    private _next = (_cols param [_forEachIndex + 1, ["", 1]]) # 1;
    [
        _body, [_pad + _at * _tw, 0, (_next - _at) * _tw - _pad, _rowH],
        _label, _mute, TEXT_BODY, true, _align, true
    ] call EFUNC(tacpad,drawText);
} forEach _cols;

[_body, [0, _rowH, _tw, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);

private _fnc_cell = {
    params ["_index", "_text", "_colour", "_y", "_size"];
    (_cols # _index) params ["", "_at", "_align"];
    private _next = (_cols param [_index + 1, ["", 1]]) # 1;
    [
        _body, [_pad + _at * _tw, _y, (_next - _at) * _tw - _pad, _rowH],
        _text, _colour, _size, false, _align
    ] call EFUNC(tacpad,drawText);
};

// The foot is measured before the rows so the rows know where they must stop.
// A platoon with everything opened is taller than the window; rows past the
// line are counted rather than drawn over the buttons, and the count replaces
// the hint in the foot.
private _footH = ([TEXT_TITLE] call EFUNC(tacpad,textH)) + 2 * _padY;
private _footY = _h - _footH - _padY;
private _limitY = _footY - _padY;

private _row = 1;
private _hidden = 0;
{
    _x params ["_grp", "_open", "_rows", "_gSummary", "_gFlags"];

    // The header row, platoon view only. A band rather than a fill so it reads
    // as furniture next to the state fills the rows use, the accent edge marks
    // your own section the way the accent edge marks a selected row, and the
    // whole row is the button - see drawHit for why the labels do not eat it.
    if (_platoon) then {
        private _y = _row * _rowH + RULE_THICK * pixelH;
        if (_y + _rowH > _limitY) then {
            _hidden = _hidden + 1 + ([0, count _rows] select _open);
            continue;
        };

        [_body, [0, _y, _tw, _rowH], [_ink # 0, _ink # 1, _ink # 2, 0.08]] call EFUNC(tacpad,drawFill);
        if (_grp isEqualTo group player) then {
            [_body, [0, _y, 4 * pixelW, _rowH], _accent] call EFUNC(tacpad,drawFill);
        };

        [
            _body, [_pad, _y, _tw * 0.4 - _pad, _rowH],
            format ["%1  %2", ["+", "-"] select _open, groupId _grp], _ink, TEXT_TITLE, true
        ] call EFUNC(tacpad,drawText);
        [
            _body, [_pad + _tw * 0.4, _y, _tw * 0.3 - _pad, _rowH],
            _gSummary, _mute, TEXT_BODY, true
        ] call EFUNC(tacpad,drawText);
        if (_gFlags isNotEqualTo "") then {
            [
                _body, [_tw * 0.7, _y, _tw * 0.3 - _pad, _rowH],
                _gFlags, _accent, TEXT_BODY, true, "right"
            ] call EFUNC(tacpad,drawText);
        };

        [_body, [0, _y + _rowH - RULE_THIN * pixelH, _tw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

        private _hit = [_body, [0, _y, _tw, _rowH], {
            params ["_ctrl"];
            private _gid = _ctrl getVariable [QGVAR(gid), ""];
            if (_gid isEqualTo "") exitWith {};

            GVAR(platoonOpen) set [_gid, !(_ctrl getVariable [QGVAR(open), false])];
            {["squad"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }] call EFUNC(tacpad,drawHit);
        _hit setVariable [QGVAR(gid), groupId _grp];
        _hit setVariable [QGVAR(open), _open];

        _row = _row + 1;
    };

    if (!_open) then {continue};

    {
        _x params ["_unit", "_out", "_health", "_hurt"];
        private _y = _row * _rowH + RULE_THICK * pixelH;
        if (_y + _rowH > _limitY) then {
            _hidden = _hidden + 1;
            _row = _row + 1;
            continue;
        };

        (switch (true) do {
            case (!alive _unit): {[ICON_KIA, "KIA", "dead"]};
            case (_out): {[ICON_UNCON, "UNRESPONSIVE - no vitals", "out"]};
            case (_hurt): {[ICON_WIA, format ["WIA - %1%2 remaining", _health, "%"], "hurt"]};
            default {[ICON_OK, "Effective", "ok"]};
        }) params ["_icon", "_status", "_state"];

        // A row that needs answering is filled, a row that is merely wounded is
        // washed, and a man off the net is dropped back. The design spends its one
        // loud colour on exactly one of the three.
        private _rowInk = _ink;
        private _statusInk = _mute;

        switch (_state) do {
            case "out": {
                [_body, [0, _y, _tw, _rowH], _accent] call EFUNC(tacpad,drawFill);
                _rowInk = _ground;
                _statusInk = _ground;
            };
            case "hurt": {
                [_body, [0, _y, _tw, _rowH], [_accent # 0, _accent # 1, _accent # 2, 0.12]] call EFUNC(tacpad,drawFill);
                _statusInk = _accent;
            };
            case "dead": {
                _rowInk = _dim;
                _statusInk = _dim;
            };
        };

        // The selected row keeps a 4px accent edge - the same mark the reader puts
        // on a selected thread. It is an edge rather than a fill because a fill
        // would argue with the three state fills above it.
        if (_unit isEqualTo GVAR(squadSelected)) then {
            [_body, [0, _y, 4 * pixelW, _rowH], _accent] call EFUNC(tacpad,drawFill);
        };

        private _self = _unit isEqualTo player;

        [0, format ["%1 %2", [rank _unit] call EFUNC(tacpad,rankShort), name _unit], _rowInk, _y, TEXT_TITLE] call _fnc_cell;
        [1, [_unit] call EFUNC(tacpad,roleShort), ([_mute, _ground] select (_state == "out")), _y, TEXT_BODY] call _fnc_cell;
        // SKILLS, EACH IN ITS OWN COLOUR - medical green, leadership yellow,
        // the rest as the unit's skills config says (user, 2026-09-05). Drawn
        // one code at a time, stepping by the measured width, stopping at the
        // column's edge. On an accent-filled row the colours would not read,
        // so those stay ground.
        private _skillX = _pad + (_cols # 2 # 1) * _tw;
        private _skillEnd = (_cols # 3 # 1) * _tw;
        private _skillInk = [_mute, _ground] select (_state == "out");
        {
            _x params ["_ab", "_sid"];
            if (_skillX >= _skillEnd) exitWith {};
            private _c = if (_state == "out" || {isNil "jmfsb_pac_fnc_skillColor"}) then {_skillInk} else {[_sid, _skillInk] call jmfsb_pac_fnc_skillColor};
            private _t = [_body, [_skillX, _y, _skillEnd - _skillX, _rowH], _ab, _c, TEXT_LABEL, false] call EFUNC(tacpad,drawText);
            _skillX = _skillX + (ctrlTextWidth _t) + _pad * 0.5;
        } forEach (_skillsOf getOrDefault [getPlayerUID _unit, []]);
        [3, _status, _statusInk, _y, TEXT_TITLE] call _fnc_cell;

        // ACE, three letters each with the swatch that man last reported. Drawn
        // rather than written out, because three colours read in one glance and
        // "GREEN GREEN AMBER" does not.
        //
        // A MAN ONLY REPORTS HIS OWN, AND NOT THE TWO THE ENGINE ALREADY KNOWS.
        // Ammunition and equipment are his to claim; being dead or unconscious is
        // not a claim, it is a fact, and a KIA whose last report said NONE would sit
        // in the table showing green. So C is overwritten from the engine for those
        // two states and left alone for the rest.
        private _reported = _unit getVariable [QGVAR(ace), []];
        private _casualty = switch (true) do {
            case (!alive _unit): {3};
            case (_out): {2};
            default {_reported param [1, -1]};
        };

        private _aceX = _pad + (_cols # _aceCol # 1) * _tw;
        private _swatchH = _rowH * 0.42;
        {
            private _idx = [_reported param [0, -1], _casualty, _reported param [2, -1]] # _forEachIndex;
            // GREEN UNTIL SOMEBODY SAYS OTHERWISE. An unreported letter used to draw
            // as a dim nothing, so a section that had not touched the screen looked
            // like a section with no state at all - and the first thing a leader did
            // was ask eight men to press three buttons to tell him nothing had
            // happened. The report is for the exceptions.
            private _colour = [
                HEALTH_OK,
                HEALTH_OK, HEALTH_WIA, [0.85, 0.20, 0.10, 1], HEALTH_KIA
            ] select (_idx + 1);

            private _cx = _aceX + _forEachIndex * (_tw * 0.05);
            [_body, [_cx, _y + (_rowH - _swatchH) * 0.5, _swatchH * pixelW / pixelH, _swatchH], _colour] call EFUNC(tacpad,drawFill);
            [_body, [_cx + _swatchH * pixelW / pixelH + _pad * 0.4, _y, _tw * 0.04, _rowH], _x, _rowInk, TEXT_LABEL, true] call EFUNC(tacpad,drawText);
        } forEach ["A", "C", "E"];

        [5, [mapGridPosition _unit, "-"] select (!alive _unit), _rowInk, _y, TEXT_TITLE] call _fnc_cell;

        // Column 6 - RADIO. It was 5, the GRID column, so the channel was drawn
        // through the grid ("text seems to be overlapping", user, 2026-09-05).
        private _radio = _unit getVariable [QGVAR(radio), ""];
        [
            6,
            [_radio, "NO SET"] select (_radio == ""),
            ([_mute, _ground] select (_state == "out")),
            _y, TEXT_BODY
        ] call _fnc_cell;

        [7, [format ["%1 M", round (player distance _unit)], "-"] select _self, ([_mute, _ground] select (_state == "out")), _y, TEXT_TITLE] call _fnc_cell;

        [_body, [0, _y + _rowH - RULE_THIN * pixelH, _tw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

        // Pressing a man SELECTS him - for MESSAGE and CALL in the foot. It used
        // to try to centre the map on him as well, which never worked under the
        // app frame and was never wanted (user, 2026-09-05: "does not centre
        // the map, had never planned for it to centre, so remove").
        private _hit = [_body, [0, _y, _tw, _rowH], {
            params ["_ctrl"];
            private _unit = _ctrl getVariable [QGVAR(unit), objNull];
            if (isNull _unit) exitWith {};

            GVAR(squadSelected) = _unit;

            {["squad"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }] call EFUNC(tacpad,drawHit);
        _hit setVariable [QGVAR(unit), _unit];

        _row = _row + 1;
    } forEach _rows;
} forEach _sections;

// -------------------------------------------------------- the table foot ----
[_body, [0, _footY - _padY, _tw, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);

if (!isNull _worst) then {
    private _btnW = _tw * 0.32;
    [_body, [_pad, _footY, _btnW, _footH], _accent] call EFUNC(tacpad,drawFill);
    [_body, [_pad * 2, _footY, _btnW - 2 * _pad, _footH], format ["FILE CASEVAC FOR %1", name _worst], _ground, TEXT_BODY, true] call EFUNC(tacpad,drawText);

    // It opens the CASEVAC card with the pick-up site set to where the casualty
    // is - the one place in the suite a location is filled in for you, because
    // the button names the man it is filling it in for. The field is the
    // template's own anchor, so nothing here has to know which line that is, and
    // it can be typed over like any other.
    private _hit = [_body, [_pad, _footY, _btnW, _footH], {
        params ["_ctrl"];
        private _casualty = _ctrl getVariable [QGVAR(casualty), objNull];
        private _anchor = (["casevac"] call EFUNC(messaging,template)) getOrDefault ["anchor", ""];

        private _values = [];
        if (_anchor isNotEqualTo "" && {!isNull _casualty}) then {
            _values pushBack [_anchor, getPosATL _casualty];
        };

        ["", "casevac", false, "", _values] call EFUNC(tacpad,composeOpen);
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(casualty), _worst];
};

// A THREAD WITH THE SELECTED MAN. Addressed to him by uid, so it reaches him
// and nobody else - which is the difference between a message and a broadcast.
private _selected = GVAR(squadSelected);
if (!isNull _selected && {_selected in _units} && {isPlayer _selected}) then {
    private _msgW = _tw * 0.17;
    private _msgX = _tw * 0.34;

    [_body, [_msgX, _footY, _msgW, _footH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
    [_body, [_msgX + _pad, _footY, _msgW - 2 * _pad, _footH], format ["MESSAGE %1", name _selected], _ink, TEXT_BODY, true] call EFUNC(tacpad,drawText);

    [_body, [_msgX, _footY, _msgW, _footH], {
        private _to = GVAR(squadSelected);
        if (isNull _to) exitWith {};

        ["", "", false, format ["P:%1", getPlayerUID _to]] call EFUNC(tacpad,composeOpen);
    }] call EFUNC(tacpad,drawHit);

    // CALL HIM (user, 2026-10-21: "change tune to a call function"). Rings him
    // through FUNC(radioDial) - a new call, or into the live one you own - so
    // the roster and the RADIO app cannot disagree about what a press rings.
    // Voice says why when it cannot (no route, busy, not the owner).
    if (!isNil QEFUNC(voice,call)) then {
        private _callX = _msgX + _msgW + _pad;
        private _callW = _tw * 0.11;

        [_body, [_callX, _footY, _callW, _footH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);
        [_body, [_callX + _pad, _footY, _callW - 2 * _pad, _footH], "CALL", _ink, TEXT_BODY, true, "center"] call EFUNC(tacpad,drawText);

        [_body, [_callX, _footY, _callW, _footH], {
            private _to = GVAR(squadSelected);
            if (isNull _to) exitWith {};

            [[_to]] call FUNC(radioDial);
            {["squad"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }] call EFUNC(tacpad,drawHit);
    };
};

// The hint gives its slot to the overflow count when there is one - a screen
// that has run out of room should say so, and what to do about it, rather than
// leaving the leader to notice a squad is short a man.
private _hint = ["TAP ANOTHER ROW TO CHANGE THE SELECTION", "TAP A ROW TO SELECT A PLAYER"] select (isNull _selected);
if (_hidden > 0) then {
    _hint = format ["%1 ROWS OFF SCREEN - FOLD A SQUAD", _hidden];
};
[
    _body, [_tw * 0.64, _footY, _tw * 0.36 - _pad, _footH],
    _hint, _mute, TEXT_LABEL, true, "right", true
] call EFUNC(tacpad,drawText);

// ------------------------------------------------------------- the rail -----
private _rx = _tw + RULE_THICK * pixelW + _pad;
private _rw = _railW - 2 * _pad;
private _ry = 0;

[_body, [_rx, _ry, _rw * 0.5, _rowH], ["STRENGTH", "PLATOON"] select _platoon, _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
[
    _body, [_rx + _rw * 0.5, _ry, _rw * 0.5, _rowH],
    format ["%1 EFFECTIVE / %2", _alive - _wia - _uncon, count _units], _mute, TEXT_LABEL, true, "right", true
] call EFUNC(tacpad,drawText);
_ry = _ry + _rowH;
[_body, [_rx, _ry, _rw, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);
_ry = _ry + _padY;

// Four counts, two up. Each is a kicker and one number, which is the tile
// anatomy the rest of the suite is built on. In the platoon view they roll up
// the whole roster, folded squads included - that is what the measuring pass
// is for.
// TALLER TILES. At 1.9 rows the 1.4-size number sat on the kicker and the
// frame clipped it (user, 2026-09-05: "make the row taller so the text fits
// better, it's ok to move ACE down"). 2.4 rows, the number under the kicker
// with air; everything below the tiles moves down with them.
private _statW = _rw / 2;
private _statH = _rowH * 2.4;
{
    _x params ["_label", "_value", "_hot"];
    private _sx = _rx + (_forEachIndex mod 2) * _statW;
    private _sy = _ry + floor (_forEachIndex / 2) * _statH;

    [_body, [_sx, _sy, _statW - _pad, _statH - _padY], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
    [_body, [_sx + _pad, _sy + _padY, _statW - 2 * _pad, _rowH * 0.6], _label, _mute, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    [_body, [_sx + _pad, _sy + _rowH * 0.95, _statW - 2 * _pad, _rowH * 1.3], ([str _value, _value] select (_value isEqualType "")), ([_ink, _accent] select _hot), TEXT_DISPLAY, true] call EFUNC(tacpad,drawText);
} forEach [
    ["WIA", _wia, _wia > 0],
    ["UNRESPONSIVE", _uncon, _uncon > 0],
    // Already a string, so the tile must not str() it again - that is what put
    // quotation marks round the number on screen.
    ["AMMO AVG", format ["%1%2", [round (_ammoSum / (1 max _ammoCount)), 0] select (_ammoCount == 0), "%"], _ammoCount > 0 && {_ammoSum / (1 max _ammoCount) < 35}],
    ["KIA", _kia, _kia > 0]
];
_ry = _ry + 2 * _statH + _padY;

// Dispersion in a sentence, and who is causing it. "640 m" alone tells a leader
// there is a problem; naming the man tells him what to do about it. Across the
// platoon it names the squad's stray as readily as the section's.
private _centre = [0, 0, 0];
{_centre = _centre vectorAdd getPosATL _x} forEach _units;
if (_units isNotEqualTo []) then {_centre = _centre vectorMultiply (1 / count _units)};

private _far = objNull;
private _farDist = 0;
{
    private _d = _x distance _centre;
    if (_d > _farDist) then {_farDist = _d; _far = _x};
} forEach _units;

[_body, [_rx, _ry, _rw, _rowH], "DISPERSION", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
_ry = _ry + _rowH;
[
    _body, [_rx, _ry, _rw, _rowH],
    if (isNull _far) then {"-"} else {format ["WIDEST %1 M - %2", round _farDist, name _far]},
    _ink, TEXT_TITLE, false
] call EFUNC(tacpad,drawText);
_ry = _ry + _rowH + _padY;
[_body, [_rx, _ry, _rw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
_ry = _ry + _padY;

// ------------------------------------------------------- my ACE report ------
[_body, [_rx, _ry, _rw * 0.6, _rowH], "MY ACE REPORT", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
[_body, [_rx + _rw * 0.6, _ry, _rw * 0.4, _rowH], [player] call EFUNC(tacpad,roleShort), _mute, TEXT_LABEL, true, "right", true] call EFUNC(tacpad,drawText);
_ry = _ry + _rowH;

private _draft = GVAR(aceDraft);
private _segH = ([TEXT_LABEL] call EFUNC(tacpad,textH)) + 1.2 * _padY;

{
    // _aceLine, NOT _line. The theme's divider colour is called _line in every
    // function in this suite, and naming the ACE line index the same thing
    // handed drawFrame the number 0 where a colour goes.
    _x params ["_aceLine", "_label", "_options"];
    [_body, [_rx, _ry, _rw, _rowH * 0.8], _label, _mute, TEXT_LABEL, true, "left", true] call EFUNC(tacpad,drawText);
    _ry = _ry + _rowH * 0.8;

    private _segW = _rw / 4;
    {
        private _on = (_draft param [_aceLine, 0]) == _forEachIndex;
        private _sx = _rx + _forEachIndex * _segW;

        // KIA on the casualties line is not yours to press. You are alive - you
        // are holding the tablet - and the table takes that state off the engine
        // for everyone, so offering it here would only let you lie about it.
        private _locked = _aceLine == 1 && _forEachIndex == 3;
        if (_locked) then {
            [_body, [_sx, _ry, _segW - _pad * 0.5, _segH], _dim, RULE_THIN] call EFUNC(tacpad,drawFrame);
            [
                _body, [_sx + _pad * 0.6, _ry, _segW - _pad * 1.2, _segH],
                "KIA - AUTO", _dim, TEXT_LABEL, true
            ] call EFUNC(tacpad,drawText);
            continue;
        };

        if (_on) then {
            [_body, [_sx, _ry, _segW - _pad * 0.5, _segH], _accent] call EFUNC(tacpad,drawFill);
        } else {
            [_body, [_sx, _ry, _segW - _pad * 0.5, _segH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
        };

        private _dot = _segH * 0.42;
        [_body, [_sx + _pad * 0.6, _ry + (_segH - _dot) * 0.5, _dot * pixelW / pixelH, _dot], [HEALTH_OK, HEALTH_WIA, [0.85, 0.20, 0.10, 1], HEALTH_KIA] select _forEachIndex] call EFUNC(tacpad,drawFill);
        [
            _body, [_sx + _pad * 1.2 + _dot * pixelW / pixelH, _ry, _segW - _dot - _pad * 2, _segH],
            _x, ([_ink, _ground] select _on), TEXT_LABEL, true
        ] call EFUNC(tacpad,drawText);

        private _hit = [_body, [_sx, _ry, _segW - _pad * 0.5, _segH], {
            params ["_ctrl"];
            private _draft = +GVAR(aceDraft);
            _draft set [_ctrl getVariable [QGVAR(aceLine), 0], _ctrl getVariable [QGVAR(aceIndex), 0]];
            GVAR(aceDraft) = _draft;

            // PUBLISHED THE MOMENT IT IS PRESSED. A man's own letters are his
            // claim about himself, and the table draws them off this variable -
            // so pressing AMBER and watching your own row stay green was the
            // screen disagreeing with itself. Sending is what rolls the section
            // up for the leader; it is not what makes your own state true.
            player setVariable [QGVAR(ace), _draft, true];

            {["squad"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
        }] call EFUNC(tacpad,drawHit);
        _hit setVariable [QGVAR(aceLine), _aceLine];
        _hit setVariable [QGVAR(aceIndex), _forEachIndex];
    } forEach _options;

    _ry = _ry + _segH + _padY;
} forEach [
    [0, "A - AMMUNITION", ["GRN", "AMB", "RED", "BLK"]],
    [1, "C - CASUALTIES", ["NONE", "WIA", "URGENT", "KIA"]],
    [2, "E - EQUIPMENT", ["OK", "DEGR", "LOST", "NMC"]]
];

// NO SEND BUTTON UNDER THE PICKER. There was one - SEND TEAM ACE REPORT, the
// leader's worst-of-section roll-up filed on the group net through the ace
// template - and it was a second copy of a state this screen already carries
// live: the letters are published the moment they are pressed, and the platoon
// view reads every squad's at once. The template went with the button.
