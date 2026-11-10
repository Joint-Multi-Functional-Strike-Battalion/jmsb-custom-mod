#include "script_component.hpp"
/*
 * Author: YonV
 * The watch panel on the device (overlay): inside the walking view's screen -
 * the side device's, or the phone's when that is the device carried - while a
 * profile is on, over the top of its map so the map stays in sight. Called
 * every tick through jmfsb_devices' overlayScreens hook. The template:
 *
 *     header     profile name, slots used / max, the context prompt
 *                ("F9: ADD TO MEDICAL" while the player looks at a valid
 *                target, prompt mode full)
 *     tiles      ONE PER SLOT, 3 WIDE BY 2 TALL (user, 2026-11-08: "6 tiles 3
 *                wide by 2 tall"): number and name / state / two values, an
 *                empty slot an empty tile, the one the arrows picked lit
 *                (FUNC(selected)). The squad view takes the full width.
 *     key hints  ALWAYS ON THE BOTTOM (user, 2026-11-08) of the screen, on
 *                their own strip: F1 REPORT  F2 SHARE  F3 ALL OFF  F4 SQUAD
 *                F5 F6 SELECT - a key with nothing to do dimmed
 *
 * The type is PANEL_FONT_SCALE of the device's row height (user, 2026-11-08:
 * "font to big").
 *
 * Arguments:
 * 0: The walking view's display <DISPLAY>
 * 1: Its rows (jmfsb_devices_fnc_overlayRows) <HASHMAP>
 * 2: Allowed to take the screen <BOOL>
 *
 * Return Value:
 * Drawn <BOOL>
 *
 * Example:
 * [_display, _rows, true] call jmfsb_watch_fnc_screen
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]], ["_rows", createHashMap, [createHashMap]], ["_allowed", false, [false]]];

if (isNull _display) exitWith {false};
private _id = [] call FUNC(current);
private _ctrls = _display getVariable [QGVAR(screenCtrls), []];
if (!_allowed || _id isEqualTo "") exitWith {
    {ctrlDelete _x} forEach _ctrls;
    _display setVariable [QGVAR(screenCtrls), []];
    false
};

// SIDE 2 SHOWS A SECOND PROFILE (design core.multi_profile): the first other
// profile with slots, when there is one - the current one stays on the side
// device, the phone and the tablets.
if (!isNil QEFUNC(devices,overlayDevice) && {([] call EFUNC(devices,overlayDevice)) isEqualTo SIDE2_DEVICE}) then {
    private _others = (keys GVAR(slots)) select {_x isNotEqualTo _id && {(GVAR(slots) get _x) isNotEqualTo []}};
    _others sort true;
    if (_others isNotEqualTo []) then {_id = _others # 0};
};
([_id] call FUNC(panelText)) params ["", "", "_head", "_headLines", "_cells", "_cellLines", "_hints", "_wide", "_max", "_picked"];

// the tiles: one per slot the profile has, or the squad view's one wide cell
private _tiles = [_max max 1, 1] select _wide;

// the controls: backdrop, header, hints, then a backdrop and a text a tile -
// made as needed, the ones no longer used deleted
private _fnc_make = {
    params ["_class"];
    private _ctrl = _display ctrlCreate [_class, -1];
    _ctrls pushBack _ctrl;
    _ctrl
};
if ((_ctrls findIf {isNull _x}) >= 0) then {
    {ctrlDelete _x} forEach _ctrls;
    _ctrls = [];
};
if (_ctrls isEqualTo []) then {
    ["RscText"] call _fnc_make;
    ["RscStructuredText"] call _fnc_make;
    ["RscStructuredText"] call _fnc_make;
};
while {count _ctrls < PANEL_FIXED_CTRLS + 2 * _tiles} do {
    ["RscText"] call _fnc_make;
    ["RscStructuredText"] call _fnc_make;
};
while {count _ctrls > PANEL_FIXED_CTRLS + 2 * _tiles} do {ctrlDelete (_ctrls deleteAt (count _ctrls - 1))};
_display setVariable [QGVAR(screenCtrls), _ctrls];
_ctrls params ["_back", "_headCtrl", "_hintCtrl"];

(_rows getOrDefault ["map", [0, 0, 0, 0]]) params ["_x0", "_y0", "_w", "_h"];
// THE WHOLE SCREEN UNDER THE TOP BAR (user, 2026-11-08: "why did you not use
// the full screen"): from the map's top down to the bottom of the screen's
// inside, over the nets and the call strip, edge to edge.
(_rows getOrDefault ["content", []]) params ["_cx", "_cy", "_cw", "_ch"];
if (!isNil "_ch") then {
    _x0 = _cx;
    _w = _cw;
    _h = _cy + _ch - _y0;
};
private _fontH = (_rows getOrDefault ["lineH", _h / PANEL_LINES_FALLBACK]) * PANEL_FONT_SCALE;
private _rowH = _fontH * PANEL_LINE_PAD;
private _cols = [PANEL_COLUMNS, 1] select _wide;
private _tileW = _w / _cols;
// THE TILES FILL THE SCREEN (user, 2026-11-08: "why did you not use the full
// screen"): every row of tiles shares what is left between the header and the
// hint strip; never shorter than its lines.
private _tileRows = ceil (_tiles / _cols);
private _gapY = TILE_GAP_PIXELS * pixelH;
private _tileH = ((_h - (_headLines + 1) * _rowH) / _tileRows - _gapY) max (_cellLines * _rowH);
private _gapX = TILE_GAP_PIXELS * pixelW;

private _fnc_text = {
    params ["_ctrl", "_pos", "_text"];
    _ctrl ctrlSetPosition _pos;
    _ctrl ctrlSetFontHeight _fontH;
    _ctrl ctrlSetStructuredText parseText _text;
    _ctrl ctrlCommit 0;
};
private _fnc_fill = {
    params ["_ctrl", "_pos", "_colour"];
    _ctrl ctrlSetPosition _pos;
    _ctrl ctrlSetBackgroundColor _colour;
    _ctrl ctrlCommit 0;
};

private _y = _y0;
[_headCtrl, [_x0, _y, _w, _headLines * _rowH], _head] call _fnc_text;
_y = _y + _headLines * _rowH;
for "_i" from 0 to _tiles - 1 do {
    private _left = _x0 + (_i mod _cols) * _tileW;
    private _top = _y + floor (_i / _cols) * (_tileH + _gapY);
    [_ctrls select (PANEL_FIXED_CTRLS + 2 * _i), [_left + _gapX, _top, _tileW - 2 * _gapX, _tileH],
        [COLOUR_TILE, COLOUR_TILE_PICKED] select (!_wide && _i isEqualTo _picked)] call _fnc_fill;
    [_ctrls select (PANEL_FIXED_CTRLS + 2 * _i + 1), [_left + 2 * _gapX, _top, _tileW - 4 * _gapX, _tileH], _cells param [_i, ""]] call _fnc_text;
};

[_back, [_x0, _y0, _w, _h], COLOUR_PANEL] call _fnc_fill;

// the key hints on the bottom of the screen, their own strip
[_hintCtrl, [_x0, _y0 + _h - _rowH, _w, _rowH], _hints] call _fnc_text;
_hintCtrl ctrlSetBackgroundColor COLOUR_PANEL;
_hintCtrl ctrlCommit 0;
true
