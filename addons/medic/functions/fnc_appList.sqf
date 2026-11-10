#include "script_component.hpp"
/*
 * Author: YonV
 * The MEDIC app's patient list: every man in the player's group, worst first -
 * cardiac arrest and heavy bleeding (massive haemorrhage comes first in MARCH,
 * and either one is what turns the tile to alert), then unconscious, then
 * wounded, then fine, the dead last - and within that the least blood left.
 * Pressing a man opens his page.
 *
 * THE ONE LOUD COLOUR IS SPENT ON ARREST. An arrest row is the inverted accent
 * block; an unconscious row, and a heavy bleeder's, the accent tint with the
 * accent edge; a wounded man's state is set in accent text and a dead man is
 * dropped back to dim - the same grammar the squad table uses.
 *
 * THE STATE COLOUR IS A BLOCK, NOT A HAIRLINE (user, 2026-11-01: "the color on
 * the medical app on the left for state needs to be bigger"): the row's full
 * height, STATE_BLOCK_PX wide, the columns moved over to clear it.
 *
 * THE TABS ON TOP: SQUAD (the player's group) and NEARBY (every man within
 * NEARBY_RANGE from another squad - the casualty a medic kneels next to, or a
 * training patient). The caller picks the units; the list is the same.
 *
 * Arguments:
 * 0: Body to fill <CONTROL>
 * 1: The men to list <ARRAY>
 * 2: The NEARBY tab is up <BOOL> (optional, default false)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, units group player] call jmfsb_medic_fnc_appList
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_units", [], [[]]], ["_nearby", false, [false]]];

if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);
private _tint = ["accentTint"] call EFUNC(tacpad,theme);
private _accentText = ["accentText"] call EFUNC(tacpad,theme);
private _green = ["swatchGreen"] call EFUNC(tacpad,theme);
private _yellow = ["swatchYellow"] call EFUNC(tacpad,theme);

private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
(ctrlPosition _body) params ["", "", "_w", "_h"];
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
// The state block's width, and where the columns start: past it and its gap.
private _blockW = STATE_BLOCK_PX * pixelW;
private _left = _blockW + STATE_BLOCK_GAP_PX * pixelW;

// ------------------------------------------------------- measure and sort ----
// The sort key is numbers only - urgency, state, blood left, roster index - so
// it never has to compare two units; the index takes the man back out. A heavy
// bleeder ranks with cardiac arrest (patientState never calls a dead man one).
private _states = _units apply {[_x] call FUNC(patientState)};
private _keys = [];
{
    private _s = _states select _forEachIndex;
    _keys pushBack [
        [_s # 0, STATE_ARREST] select (_s # 1),
        _s # 0,
        _x getVariable [ACEV_BLOOD_VOLUME, BLOOD_VOLUME_FULL],
        _forEachIndex
    ];
} forEach _units;
_keys sort true;

private _hurt = {(_x # 0) in [STATE_ARREST, STATE_UNCON, STATE_WOUNDED]} count _states;

// ------------------------------------------------------------------ tabs ----
[
    _body, [0, 0, _w, _rowH], MEDIC_TABS, [TAB_SQUAD, TAB_NEARBY] select _nearby, QGVAR(tab), APP_ID,
    format ["%1 HURT / %2 %3", _hurt, count _units, ["IN SQUAD", format ["WITHIN %1 M", NEARBY_RANGE]] select _nearby]
] call EFUNC(tacpad_apps,appPageTabs);

private _y = _padY + _rowH;
if (_units isEqualTo []) then {
    [_body, [_pad, _y, _w - 2 * _pad, _rowH], ["NOBODY IN THE SQUAD", format ["NOBODY FROM ANOTHER SQUAD WITHIN %1 M", NEARBY_RANGE]] select _nearby, _muted, TEXT_BODY, true, "left"] call EFUNC(tacpad,drawText);
};

// Column edges as fractions of the width, so the header and every row are laid
// out from one list and cannot disagree about where a column starts.
// HR and SPO2 are the tablet's own EKG and pulse oximeter (FUNC(readVitals);
// user, 2026-10-22: "put those medical status into the medic app").
// BP and RR beside them (user, 2026-10-24: "bp resp rate and o2 need to be in
// the medical app").
private _cols = [
    ["PATIENT", 0.000, "left"],
    ["STATE", 0.235, "left"],
    ["BLEEDING", 0.335, "left"],
    ["WOUNDS", 0.435, "left"],
    ["BLOOD", 0.505, "left"],
    ["HR", 0.580, "left"],
    ["BP", 0.640, "left"],
    ["SPO2", 0.750, "left"],
    ["RR", 0.815, "left"],
    ["RANGE", 0.870, "right"]
];
private _fnc_cell = {
    params ["_index", "_text", "_colour", "_rowY", ["_size", TEXT_BODY], ["_bold", false]];
    (_cols # _index) params ["", "_at", "_align"];
    private _next = (_cols param [_index + 1, ["", 1]]) # 1;
    [_body, [_left + _at * (_w - _left - _pad), _rowY, (_next - _at) * (_w - _left - _pad) - _pad, _rowH], _text, _colour, _size, _bold, _align] call EFUNC(tacpad,drawText);
};

{
    _x params ["_label"];
    [_forEachIndex, _label, _muted, _y, TEXT_LABEL, true] call _fnc_cell;
} forEach _cols;
_y = _y + _rowH;
[_body, [0, _y, _w, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + RULE_THICK * pixelH;

// The foot is measured first so the rows know where they must stop.
private _footH = ([TEXT_BODY] call EFUNC(tacpad,textH)) + 2 * _padY;
private _limitY = _h - _footH - _padY;
private _hidden = 0;

// ------------------------------------------------------------------ rows ----
{
    private _index = _x # 3;
    private _unit = _units select _index;
    (_states select _index) params ["_state", "_heavy", "_grade", "_wounds"];

    if (_y + _rowH > _limitY) then {
        _hidden = _hidden + 1;
        continue;
    };

    // [fill, edge bar, name ink, state ink, other ink]. A heavy bleeder who is
    // still awake gets the unconscious row - he is the row the tile alerted on.
    (switch (true) do {
        case (_state isEqualTo STATE_ARREST): {[_accent, _ground, _ground, _ground, _ground]};
        case (_state isEqualTo STATE_UNCON || _heavy): {[_tint, _accent, _ink, _accentText, _ink]};
        case (_state isEqualTo STATE_WOUNDED): {[[], _yellow, _ink, _accentText, _ink]};
        case (_state isEqualTo STATE_DEAD): {[[], _dim, _dim, _dim, _dim]};
        default {[[], _green, _ink, _muted, _muted]};
    }) params ["_fill", "_edge", "_nameInk", "_stateInk", "_otherInk"];

    if (_fill isNotEqualTo []) then {
        [_body, [0, _y, _w, _rowH], _fill] call EFUNC(tacpad,drawFill);
    };
    [_body, [0, _y, _blockW, _rowH], _edge] call EFUNC(tacpad,drawFill);

    private _alive = _state isNotEqualTo STATE_DEAD;
    private _volume = _unit getVariable [ACEV_BLOOD_VOLUME, BLOOD_VOLUME_FULL];

    [0, format ["%1 %2", [rank _unit] call EFUNC(tacpad,rankShort), [_unit] call FUNC(nameOf)], _nameInk, _y, TEXT_TITLE] call _fnc_cell;
    [1, STATE_WORDS select _state, _stateInk, _y, TEXT_BODY, true] call _fnc_cell;
    private _bleedWord = "-";
    if (_alive && {_grade > -1}) then {_bleedWord = BLEED_WORDS select _grade};
    [
        2, _bleedWord,
        [_otherInk, [_accentText, _ground] select (_state isEqualTo STATE_ARREST)] select _heavy, _y, TEXT_BODY, _heavy
    ] call _fnc_cell;
    [3, [str _wounds, "-"] select (!_alive || _wounds isEqualTo 0), _otherInk, _y, TEXT_BODY] call _fnc_cell;
    [4, [format ["%1 L", (_volume max 0) toFixed 1], "-"] select !_alive, _otherInk, _y, TEXT_BODY] call _fnc_cell;
    ([_unit] call FUNC(readVitals)) params ["_hr", "_bp", "_spo2", "_rr"];
    [5, _hr # 1, _otherInk, _y, TEXT_BODY] call _fnc_cell;
    [6, _bp # 1, _otherInk, _y, TEXT_BODY] call _fnc_cell;
    [7, _spo2 # 1, _otherInk, _y, TEXT_BODY] call _fnc_cell;
    [8, _rr # 1, _otherInk, _y, TEXT_BODY] call _fnc_cell;
    [9, [format ["%1 M", round (player distance _unit)], "YOU"] select (_unit isEqualTo player), _otherInk, _y, TEXT_BODY] call _fnc_cell;

    [_body, [0, _y + _rowH - RULE_THIN * pixelH, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

    private _hit = [_body, [0, _y, _w, _rowH], {
        params ["_ctrl"];
        private _picked = _ctrl getVariable [QGVAR(unit), objNull];
        if (isNull _picked) exitWith {};
        GVAR(patient) = _picked;
        {[APP_ID] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(unit), _unit];

    _y = _y + _rowH;
} forEach _keys;

// ------------------------------------------------------------------ foot ----
private _footY = _h - _footH;
[_body, [0, _footY - _padY, _w, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
[
    _body, [_pad, _footY, _w - 2 * _pad, _footH],
    [
        "TAP A PATIENT FOR VITALS, WOUNDS AND SHOW ON MAP",
        format ["%1 PATIENTS OFF SCREEN - LOWER THE TEXT SIZE IN SETTINGS", _hidden]
    ] select (_hidden > 0),
    [_muted, _accentText] select (_hidden > 0), TEXT_LABEL, true, "right"
] call EFUNC(tacpad,drawText);
