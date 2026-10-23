#include "script_component.hpp"
/*
 * Author: JMSB
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
 * Arguments:
 * 0: Body to fill <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body] call jmfsb_medic_fnc_appList
 *
 * Public: No
 */

// The state bar down a row's left edge, in screen pixels.
#define EDGE_PX 4

params [["_body", controlNull, [controlNull]]];

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

// ------------------------------------------------------- measure and sort ----
// The sort key is numbers only - urgency, state, blood left, roster index - so
// it never has to compare two units; the index takes the man back out. A heavy
// bleeder ranks with cardiac arrest (patientState never calls a dead man one).
private _units = units group player;
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

// ---------------------------------------------------------------- header ----
[_body, [_pad, _padY, _w * 0.5, _rowH], "PATIENTS", _muted, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
[
    _body, [_w * 0.5, _padY, _w * 0.5 - _pad, _rowH],
    format ["%1 HURT / %2 IN SQUAD", _hurt, count _units], [_muted, _accentText] select (_hurt > 0), TEXT_BODY, true, "right"
] call EFUNC(tacpad,drawText);

private _y = _padY + _rowH;

// Column edges as fractions of the width, so the header and every row are laid
// out from one list and cannot disagree about where a column starts.
// HR and SPO2 are the tablet's own EKG and pulse oximeter (FUNC(readVitals);
// user, 2026-10-22: "put those medical status into the medic app").
private _cols = [
    ["PATIENT", 0.000, "left"],
    ["STATE", 0.300, "left"],
    ["BLEEDING", 0.430, "left"],
    ["WOUNDS", 0.545, "left"],
    ["BLOOD", 0.630, "left"],
    ["HR", 0.720, "left"],
    ["SPO2", 0.800, "left"],
    ["RANGE", 0.885, "right"]
];
private _fnc_cell = {
    params ["_index", "_text", "_colour", "_rowY", ["_size", TEXT_BODY], ["_bold", false]];
    (_cols # _index) params ["", "_at", "_align"];
    private _next = (_cols param [_index + 1, ["", 1]]) # 1;
    [_body, [_pad + _at * (_w - 2 * _pad), _rowY, (_next - _at) * (_w - 2 * _pad) - _pad, _rowH], _text, _colour, _size, _bold, _align] call EFUNC(tacpad,drawText);
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
    [_body, [0, _y, EDGE_PX * pixelW, _rowH], _edge] call EFUNC(tacpad,drawFill);

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
    ([_unit] call FUNC(readVitals)) params ["_hr", "", "_spo2"];
    [5, _hr # 1, _otherInk, _y, TEXT_BODY] call _fnc_cell;
    [6, _spo2 # 1, _otherInk, _y, TEXT_BODY] call _fnc_cell;
    [7, [format ["%1 M", round (player distance _unit)], "YOU"] select (_unit isEqualTo player), _otherInk, _y, TEXT_BODY] call _fnc_cell;

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
