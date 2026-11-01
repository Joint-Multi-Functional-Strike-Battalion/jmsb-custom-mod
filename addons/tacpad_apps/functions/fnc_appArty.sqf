#include "script_component.hpp"
/*
 * Author: JMSB
 * ARTY - the artillery team's calculator (user, 2026-10-25: "a good arty
 * calculator that works with ACE built in"; reference: the ITC BCS). The gun
 * is the one the player crews or stands at (FUNC(artyGun)); the target is a
 * typed grid (6, 8 or 10 digits) or the counter-battery radar's last fix
 * (jmfsb_reaction's report to the team, GVAR(artyFix)). Out come the azimuth,
 * the range and the height difference, then one row per charge the gun
 * carries with the low and high angle elevations in mils and the times of
 * flight - ACE's own solver (FUNC(artySolve)).
 *
 * Arguments:
 * 0: Host display <DISPLAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_display] call jmfsb_tacpad_apps_fnc_appArty
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]]];
if (isNull _display) exitWith {};

([_display, "ARTY - FIRING SOLUTIONS", ARTY_APP_W, ARTY_APP_H] call EFUNC(tacpad,appFrame)) params ["", "_body"];
if (isNull _body) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];
private _mute = ["muted"] call EFUNC(tacpad,theme);
private _dim = ["dim"] call EFUNC(tacpad,theme);
private _pos = ctrlPosition _body;
private _w = _pos # 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;
private _rowH = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H * ARTY_ROW_K;
private _fnc_grid = {
    params ["_p"];
    if (!isNil QEFUNC(maptools,gridText)) exitWith {[_p] call EFUNC(maptools,gridText)};
    mapGridPosition _p
};

// ------------------------------------------------------------ the gun ----
private _gun = [] call FUNC(artyGun);
private _y = _padY;
[_body, [_pad, _y, _w * 0.14, _rowH], "GUN", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
if (isNull _gun) exitWith {
    [
        _body, [_pad + _w * 0.14, _y, _w * 0.84, _rowH * 2],
        format ["NO GUN - crew an artillery piece, or stand within %1 m of one.", round GVAR(artyGunRange)], _accent, TEXT_TITLE, true
    ] call EFUNC(tacpad,drawText);
};
private _gunASL = getPosASL _gun;
[
    _body, [_pad + _w * 0.14, _y, _w * 0.84, _rowH],
    format ["%1  -  GRID %2  -  ALT %3 M", toUpper getText (configOf _gun >> "displayName"), [getPosATL _gun] call _fnc_grid, round (_gunASL # 2)],
    _ink, TEXT_TITLE, true
] call EFUNC(tacpad,drawText);
_y = _y + _rowH * 1.2;
[_body, [_pad, _y, _w - 2 * _pad, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
_y = _y + _padY;

// --------------------------------------------------------- the target ----
[_body, [_pad, _y, _w * 0.14, _rowH], "TARGET", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
private _boxX = _pad + _w * 0.14;
private _boxW = _w * 0.24;
[_body, [_boxX, _y, _boxW, _rowH], _line, RULE_THIN] call EFUNC(tacpad,drawFrame);
private _box = (ctrlParent _body) ctrlCreate ["RscEdit", -1, _body];
_box ctrlSetPosition [_boxX + _pad, _y, _boxW - 2 * _pad, _rowH];
_box ctrlSetBackgroundColor [0, 0, 0, 0];
_box ctrlSetTextColor _ink;
_box ctrlSetFontHeight (_rowH * 0.72);
_box ctrlSetText (uiNamespace getVariable [QGVAR(artyGridText), ""]);
_box ctrlSetTooltip "Target grid, 6, 8 or 10 digits. Then SET.";
_box ctrlCommit 0;
_box ctrlAddEventHandler ["KeyUp", {
    params ["_ctrl"];
    uiNamespace setVariable [QGVAR(artyGridText), ctrlText _ctrl];
    false
}];
private _btnW = _w * 0.1;
private _bx = _boxX + _boxW + _pad;
[_body, [_bx, _y, _btnW, _rowH], "SET", "fill", {
    private _p = if (isNil QEFUNC(maptools,gridToPos)) then {[]} else {
        [uiNamespace getVariable [QGVAR(artyGridText), ""]] call EFUNC(maptools,gridToPos)
    };
    if (_p isEqualTo []) exitWith {
        ["ARTY", "Not a grid on this map - 6, 8 or 10 digits."] call EFUNC(notify,notify);
    };
    GVAR(artyTarget) = AGLToASL _p;
    {["arty"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}] call FUNC(appPageButton);
_bx = _bx + _btnW + _pad;
private _fix = GVAR(artyFix);
[_body, [_bx, _y, _w * 0.2, _rowH], "RADAR FIX", ["line", "alarm"] select (_fix isNotEqualTo []), [{
    if (GVAR(artyFix) isEqualTo []) exitWith {};
    GVAR(artyTarget) = AGLToASL (GVAR(artyFix) # 0);
    {["arty"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
}, {}] select (_fix isEqualTo [])] call FUNC(appPageButton);
_bx = _bx + _w * 0.2 + _pad;
if (_fix isNotEqualTo []) then {
    _fix params ["_fixPos", "_fixAt", ["_fixWhat", ""]];
    [
        _body, [_bx, _y, _w - _bx - _pad, _rowH],
        format ["%1 - %2 MIN AGO", toUpper _fixWhat, floor ((CBA_missionTime - _fixAt) / 60)],
        _mute, TEXT_LABEL, true, "left", true
    ] call EFUNC(tacpad,drawText);
};
_y = _y + _rowH * 1.3;

// A MAP MARKER AS THE TARGET (user, 2026-10-25: "map-marked targets"): the
// markers on the map - the players' own and the mission's named ones - nearest
// the gun first.
[_body, [_pad, _y, _w * 0.14, _rowH], "MARKER", _mute, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
private _markers = (allMapMarkers select {
    (markerShape _x) isEqualTo "ICON" && {(markerAlpha _x) > 0}
    && {(_x find "_USER_DEFINED") == 0 || {(markerText _x) isNotEqualTo ""}}
}) apply {[(getMarkerPos _x) distance2D _gunASL, _x]};
_markers sort true;
_markers = (_markers select [0, ARTY_MARKERS_MAX]) apply {_x # 1};
if (_markers isEqualTo []) then {
    [_body, [_pad + _w * 0.14, _y, _w * 0.6, _rowH], "No markers on the map.", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
} else {
    private _combo = (ctrlParent _body) ctrlCreate ["RscCombo", -1, _body];
    _combo ctrlSetPosition [_pad + _w * 0.14, _y, _w * 0.5, _rowH];
    _combo ctrlSetFontHeight (_rowH * 0.7);
    _combo ctrlCommit 0;
    _combo lbAdd "- pick a marker -";
    {
        private _label = markerText _x;
        if (_label isEqualTo "") then {_label = "marker"};
        private _i = _combo lbAdd format ["%1  -  %2  -  %3 M", toUpper _label, [getMarkerPos _x] call _fnc_grid, round ((getMarkerPos _x) distance2D _gunASL)];
        _combo lbSetData [_i, _x];
    } forEach _markers;
    _combo lbSetCurSel 0;
    _combo ctrlAddEventHandler ["LBSelChanged", {
        params ["_ctrl", "_index"];
        private _name = _ctrl lbData _index;
        if (_name isEqualTo "") exitWith {};
        GVAR(artyTarget) = AGLToASL (getMarkerPos _name);
        {["arty"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
    }];
};
_y = _y + _rowH * 1.3;

if (GVAR(artyTarget) isEqualTo []) exitWith {
    [_body, [_pad, _y, _w - 2 * _pad, _rowH], "Enter a target grid, or take the radar's last fix.", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
};

([_gun, GVAR(artyTarget)] call FUNC(artySolve)) params [["_az", 0], ["_range", 0], ["_dh", 0], ["_rows", []]];
[
    _body, [_pad, _y, _w - 2 * _pad, _rowH],
    format [
        "GRID %1  -  AZIMUTH %2 MILS (%3 DEG)  -  RANGE %4 M  -  HEIGHT %5%6 M",
        [ASLToAGL GVAR(artyTarget)] call _fnc_grid, round _az, round (_az / ARTY_MILS_PER_DEG),
        round _range, ["", "+"] select (_dh >= 0), round _dh
    ],
    _accent, TEXT_TITLE, true
] call EFUNC(tacpad,drawText);
_y = _y + _rowH * 1.3;
[_body, [_pad, _y, _w - 2 * _pad, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + _padY;

// ------------------------------------------------------- the solutions ----
private _cols = [
    ["CHARGE", 0.00, "left"], ["MV M/S", 0.30, "right"],
    ["LOW EL", 0.42, "right"], ["LOW TOF", 0.54, "right"], ["LOW DEFL", 0.64, "right"],
    ["HIGH EL", 0.76, "right"], ["HIGH TOF", 0.88, "right"]
];
private _tw = _w - 2 * _pad;
private _fnc_cell = {
    params ["_i", "_text", "_colour", "_rowY", ["_size", TEXT_BODY]];
    (_cols # _i) params ["", "_at", "_align"];
    private _next = (_cols param [_i + 1, ["", 1]]) # 1;
    [_body, [_pad + _at * _tw, _rowY, (_next - _at) * _tw - _pad, _rowH], _text, _colour, _size, true, _align] call EFUNC(tacpad,drawText);
};
{
    [_forEachIndex, _x # 0, _mute, _y, TEXT_LABEL] call _fnc_cell;
} forEach _cols;
_y = _y + _rowH;
if (_rows isEqualTo []) then {
    [_body, [_pad, _y, _tw, _rowH], "This gun carries no artillery rounds.", _dim, TEXT_BODY] call EFUNC(tacpad,drawText);
};
private _fnc_el = {params ["_v"]; ["--", str round _v] select (_v > 0)};
private _fnc_tof = {params ["_v"]; ["--", format ["%1 S", round _v]] select (_v > 0)};
{
    _x params ["_label", "_mv", "_low", "_high"];
    private _rowY = _y + _forEachIndex * _rowH;
    [0, _label, _ink, _rowY, TEXT_BODY] call _fnc_cell;
    [1, str _mv, _mute, _rowY] call _fnc_cell;
    [2, [_low # 0] call _fnc_el, _ink, _rowY, TEXT_TITLE] call _fnc_cell;
    [3, [_low # 1] call _fnc_tof, _mute, _rowY] call _fnc_cell;
    [4, [str round (_low # 2), "--"] select ((_low # 0) <= 0), _mute, _rowY] call _fnc_cell;
    [5, [_high # 0] call _fnc_el, _ink, _rowY, TEXT_TITLE] call _fnc_cell;
    [6, [_high # 1] call _fnc_tof, _mute, _rowY] call _fnc_cell;
    [_body, [_pad, _rowY + _rowH - RULE_THIN * pixelH, _tw, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);
} forEach _rows;
_y = _y + count _rows * _rowH;

// ------------------------------------------------------------- MRSI ----
// MULTIPLE ROUNDS, SIMULTANEOUS IMPACT (user, 2026-10-25): up to ARTY_MRSI_MAX
// solutions from this one gun whose times of flight differ by at least the
// reload gap, fired longest flight first, each after the delay shown, so
// they land together. A player's setting turns it off and sets the gap.
if (GVAR(artyMrsi)) then {
    private _all = [];
    {
        _x params ["_label", "", "_low", "_high"];
        if ((_low # 0) > 0) then {_all pushBack [_low # 1, _label, "LOW", _low # 0]};
        if ((_high # 0) > 0) then {_all pushBack [_high # 1, _label, "HIGH", _high # 0]};
    } forEach _rows;
    _all sort false;
    private _pick = [];
    {
        if (count _pick >= ARTY_MRSI_MAX) then {break};
        private _tof = _x # 0;
        if ((_pick findIf {abs ((_x # 0) - _tof) < GVAR(artyMrsiGap)}) < 0) then {_pick pushBack _x};
    } forEach _all;
    _y = _y + _padY;
    if (count _pick < 2) then {
        [_body, [_pad, _y, _tw, _rowH], format ["MRSI - no two solutions %1 s apart from this gun at this range.", GVAR(artyMrsiGap)], _dim, TEXT_BODY, true] call EFUNC(tacpad,drawText);
        _y = _y + _rowH;
    } else {
        [_body, [_pad, _y, _tw, _rowH], "MRSI - FIRE IN THIS ORDER, EACH AT ITS TIME", _accent, TEXT_BODY, true, "left", true] call EFUNC(tacpad,drawText);
        _y = _y + _rowH;
        private _first = (_pick # 0) # 0;
        {
            _x params ["_tof", "_label", "_angle", "_el"];
            [
                _body, [_pad, _y, _tw, _rowH],
                format ["%1.  T+%2 S  -  %3 %4  -  EL %5 MILS  -  TOF %6 S", _forEachIndex + 1, round (_first - _tof), _label, _angle, round _el, round _tof],
                _ink, TEXT_BODY, true
            ] call EFUNC(tacpad,drawText);
            _y = _y + _rowH;
        } forEach _pick;
    };
};

// ----------------------------------------------------------- the foot ----
_y = _y + _padY;
private _ace = !isNil "ace_artillerytables_fnc_calculateSolution";
private _adv = missionNamespace getVariable ["ace_artillerytables_advancedCorrections", false];
[
    _body, [_pad, _y, _tw, _rowH],
    format [
        "6400 MILS  -  %1  -  DEFL: LEFT IS MINUS  -  -- = OUT OF REACH ON THAT CHARGE",
        ["NO ACE - VACUUM ARC", ["ACE SOLVER, NO AIR FRICTION", "ACE SOLVER WITH AIR FRICTION (ADVANCED CORRECTIONS ON)"] select _adv] select _ace
    ],
    _dim, TEXT_LABEL, true, "left", true
] call EFUNC(tacpad,drawText);
