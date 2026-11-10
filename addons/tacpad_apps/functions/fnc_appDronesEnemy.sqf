#include "script_component.hpp"
/*
 * Author: YonV
 * DRONES - ENEMY: what is unmanned and hostile in the air, and where. Every
 * value is EFUNC(hacking,scannerRead)'s cache - the same sweep the tile and the
 * handset read, so no two surfaces can disagree about the air. Without the
 * intrusion suite or a receiver it says which.
 *
 * A BEARING SCOPE, NOT A LIST (review 2026-11-01, decision R7: one contact was
 * drawn as a full-width key/value list). The player in the centre, a ring at
 * each of the receiver's warning distances, north up, and the contact at its
 * bearing and range with its airframe on it; the key/values beside the scope
 * (FUNC(kvRow)), its grid at the player's jmfsb_devices_gridDigits
 * (jmfsb_devices_fnc_overlayGrid). The sweep
 * reports the nearest contact, so that is the one on the scope.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel rectangle [x, y, w, h] <ARRAY>
 * 2: Board context (FUNC(appDrones)) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_body, _rect, _ctx] call jmfsb_tacpad_apps_fnc_appDronesEnemy
 *
 * Public: No
 */

params [["_body", controlNull, [controlNull]], ["_rect", [0, 0, 0, 0], [[]], 4], ["_ctx", createHashMap, [createHashMap]]];

private _rowH = _ctx get "rowH";

private _loaded = !isNil QEFUNC(hacking,scannerRead);
private _receiver = _loaded && {[player] call EFUNC(hacking,hasScanner)};
private _read = if (_receiver) then {[] call EFUNC(hacking,scannerRead)} else {[]};
_read params [["_state", 0], ["_dist", 0], ["_dir", 0], "", "", "", "", ["_tag", ""]];

([_body, _rect, "ENEMY", ["NO RECEIVER", "RECEIVER SWEEP"] select _receiver] call FUNC(appPagePanel)) params ["_left", "_top", "_w", "_h"];

private _ink = ["ink"] call EFUNC(tacpad,theme);
private _accent = ["accent"] call EFUNC(tacpad,theme);
private _line = ["line"] call EFUNC(tacpad,theme);
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _amber = ["swatchYellow"] call EFUNC(tacpad,theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

private _level = 0 max (_state min 2);
private _colour = [_ink, _amber, _accent] select _level;
private _headline = switch (true) do {
    case (!_loaded): {"INTRUSION SUITE NOT LOADED"};
    case (!_receiver): {"NO RECEIVER"};
    default {["NO AIR CONTACT", "CONTACT - INSIDE 2 KM", "CONTACT - INSIDE 1 KM"] select _level};
};
[_body, [_left + _pad, _top + _padY, _w - 2 * _pad, _rowH * 1.6], _headline, _colour, TEXT_TITLE, true] call EFUNC(tacpad,drawText);

private _y = _top + _padY * 2 + _rowH * 1.6;
[_body, [_left + _pad, _y, _w - 2 * _pad, RULE_THICK * pixelH], _ink] call EFUNC(tacpad,drawFill);
_y = _y + _padY;

if (!_receiver) exitWith {};

// ---------------------------------------------------------------- scope ---
// Square on screen: a height in y-units is that many pixels, and the width
// that matches it is the same pixels in x-units. The "N" over the top takes
// one label line; the scope is as big as the rest of the panel allows.
private _labelH = [TEXT_LABEL] call EFUNC(tacpad,textH);
private _areaH = _top + _h - _y - _labelH - _padY * 2;
private _areaW = (_w - 2 * _pad) * DRONES_SCOPE_SHARE;
private _ry = ((_areaH min (_areaW / pixelW * pixelH)) / 2) max 0;
private _rx = _ry * pixelW / pixelH;
private _cx = _left + _pad + _rx;
private _cy = _y + _labelH + _ry;

[_body, [_cx - _rx, _y, 2 * _rx, _labelH], "N", _muted, TEXT_LABEL, true, "center"] call EFUNC(tacpad,drawText);

// The cross through the player, north-south and east-west.
[_body, [_cx, _cy - _ry, RULE_THIN * pixelW, 2 * _ry], _line] call EFUNC(tacpad,drawFill);
[_body, [_cx - _rx, _cy, 2 * _rx, RULE_THIN * pixelH], _line] call EFUNC(tacpad,drawFill);

// A ring is a circle of dots - the suite draws with fills and nothing else -
// with its distance on it, just right of north.
private _dotW = DRONES_SCOPE_DOT_PX * pixelW;
private _dotH = DRONES_SCOPE_DOT_PX * pixelH;
{
    private _k = (_x / DRONES_SCOPE_RANGE_M) min 1;
    for "_i" from 0 to (DRONES_SCOPE_DOTS - 1) do {
        private _a = 360 * _i / DRONES_SCOPE_DOTS;
        [_body, [_cx + (sin _a) * _k * _rx - _dotW / 2, _cy - (cos _a) * _k * _ry - _dotH / 2, _dotW, _dotH], _muted] call EFUNC(tacpad,drawFill);
    };
    [_body, [_cx + _pad, _cy - _k * _ry, _rx, _labelH], format ["%1 KM", _x / DRONES_M_PER_KM], _muted, TEXT_LABEL] call EFUNC(tacpad,drawText);
} forEach DRONES_SCOPE_RINGS;

// The player.
private _selfW = DRONES_SCOPE_SELF_PX * pixelW;
private _selfH = DRONES_SCOPE_SELF_PX * pixelH;
[_body, [_cx - _selfW / 2, _cy - _selfH / 2, _selfW, _selfH], _ink] call EFUNC(tacpad,drawFill);

private _kvX = _cx + _rx + _pad * 2;
private _kvW = _left + _w - _pad - _kvX;

if (_state <= 0) exitWith {
    [_body, [_kvX, _y + _labelH, _kvW, KV_ROW_H], "Nothing unmanned and hostile heard.", _muted, KV_TEXT] call EFUNC(tacpad,drawText);
};

// The contact, at its bearing and range (past the edge it sits on the edge),
// with its airframe beside it - on the side away from the scope's edge, so
// a contact in the east is labelled to its left.
private _airframe = [toUpper _tag, "CONTACT"] select (_tag isEqualTo "");
private _k = (_dist / DRONES_SCOPE_RANGE_M) min 1;
private _px = _cx + (sin _dir) * _k * _rx;
private _py = _cy - (cos _dir) * _k * _ry;
private _markW = DRONES_SCOPE_CONTACT_PX * pixelW;
private _markH = DRONES_SCOPE_CONTACT_PX * pixelH;
[_body, [_px - _markW / 2, _py - _markH / 2, _markW, _markH], _colour] call EFUNC(tacpad,drawFill);

private _tagH = [KV_TEXT] call EFUNC(tacpad,textH);
private _east = (sin _dir) > 0;
private _tagW = [_left + _w - _pad - (_px + _markW), _px - _markW - _left - _pad] select _east;
private _tagX = [_px + _markW, _px - _markW - _tagW] select _east;
[_body, [_tagX, _py - _tagH / 2, _tagW max 0, _tagH], _airframe, _colour, KV_TEXT, true, ["left", "right"] select _east] call EFUNC(tacpad,drawText);

// ------------------------------------------------------------ key/values ---
// THE GRID AT THE PLAYER'S FIGURES (review 2026-11-01, DESIGN_TABLET_REVIEW
// 2.7 / 3.4: it was six here and eight in the header) - the devices' one grid
// reader, the header's own (jmfsb_devices_fnc_overlayGrid, given a position);
// the engine's square without that addon.
private _at = (getPosATL player) getPos [_dist, _dir];
private _grid = if (isNil QEFUNC(devices,overlayGrid)) then {mapGridPosition _at} else {([_at] call EFUNC(devices,overlayGrid)) select 0};

private _rows = [
    ["BEARING", format ["%1 DEG", [round _dir, DRONES_BRG_DIGITS] call CBA_fnc_formatNumber], _colour],
    ["RANGE", format ["%1 M", round _dist], _colour],
    ["GRID", _grid, _colour]
];
if (_tag isNotEqualTo "") then {_rows pushBack ["AIRFRAME", toUpper _tag, _colour]};

[_body, [_kvX, _y + _labelH, _kvW], _rows, 1] call FUNC(kvRow);
