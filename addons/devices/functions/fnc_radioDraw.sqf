#include "script_component.hpp"
/*
 * Author: JMSB
 * Draws the small devices' RADIO app over the walking view's map, squad list
 * and net row (docs/DESIGN_VOICE.md, "Phone and side RADIO app"; the
 * voice_phone_app_* and voice_side_app_* images): the tab strip, the header
 * line, the rows with the cursor's row outlined, the group chips on CALLS, and
 * the four soft keys - along the bottom on the phone, a 2 x 2 grid on the side
 * devices, whose rows stack onto two lines.
 *
 * A TITLE LAYER TAKES NO MOUSE, so this is keys only: numpad 0 / . move the
 * cursor, the device keys F1-F4 are the soft keys, numpad 7 / 8 the tabs
 * (FUNC(radioKey)). Controls are made fresh on each draw and the last draw's
 * removed, as the rows of the walking view are redrawn whole each tick.
 *
 * Arguments:
 * 0: The walking view's display <DISPLAY>
 * 1: Its rows (FUNC(overlayRows)) <HASHMAP>
 *
 * Return Value:
 * Drawn - the app is open <BOOL>
 *
 * Example:
 * [_display, _rows] call jmfsb_devices_fnc_radioDraw
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]], ["_rows", createHashMap, [createHashMap]]];

if (isNull _display) exitWith {false};
{ctrlDelete _x} forEach (_display getVariable [QGVAR(radioCtrls), []]);
_display setVariable [QGVAR(radioCtrls), []];
if (!GVAR(radioOpen) || {isNil QEFUNC(voice,netState)}) exitWith {false};

private _view = [] call FUNC(radioRows);
([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];
private _muted = ["muted"] call EFUNC(tacpad,theme);
private _tint = ["accentTint"] call EFUNC(tacpad,theme);
private _solid = [_ground # 0, _ground # 1, _ground # 2, 1];
private _tones = createHashMapFromArray [["ink", _ink], ["dim", _muted], ["ok", COLOUR_NET_OK], ["alert", COLOUR_ALERT], ["warn", COLOUR_WARN]];

private _portrait = _rows get "portrait";
(_rows get "map") params ["_ax", "_ay", "_aw"];
(_rows get "nets") params ["", "_ny", "", "_nh"];
private _ah = _ny + _nh - _ay;
private _gapX = _rows get "gapX";
private _gapY = _rows get "gapY";
private _textH = _rows get "textH";
private _lineH = _rows get "lineH";
private _fade = 1 - (GVAR(overlayOpacity) max 0 min 1);
private _made = [];

private _fnc_box = {
    params ["_rect", "_colour"];
    private _c = _display ctrlCreate ["RscText", -1];
    _c ctrlSetText "";
    _c ctrlSetBackgroundColor _colour;
    _c ctrlSetPosition _rect;
    _c ctrlSetFade _fade;
    _c ctrlCommit 0;
    _made pushBack _c;
};
private _fnc_frame = {
    params ["_rect", "_colour"];
    _rect params ["_fx", "_fy", "_fw", "_fh"];
    private _ew = NET_EDGE_PX * pixelW;
    private _eh = NET_EDGE_PX * pixelH;
    {[_x, _colour] call _fnc_box} forEach [[_fx, _fy, _fw, _eh], [_fx, _fy + _fh - _eh, _fw, _eh], [_fx, _fy, _ew, _fh], [_fx + _fw - _ew, _fy, _ew, _fh]];
};
private _fnc_text = {
    params ["_rect", "_markup", ["_align", "left", [""]]];
    private _c = _display ctrlCreate ["RscStructuredText", -1];
    _c ctrlSetBackgroundColor [0, 0, 0, 0];
    _c ctrlSetPosition _rect;
    _c ctrlSetFontHeight _textH;
    _c ctrlSetStructuredText parseText format ["<t align='%1' shadow='0'>%2</t>", _align, _markup];
    _c ctrlSetFade _fade;
    _c ctrlCommit 0;
    _made pushBack _c;
};
private _fnc_t = {
    params ["_text", "_colour", ["_bold", false, [false]]];
    format ["<t font='%1' color='%2'>%3</t>", ["RobotoCondensed", "RobotoCondensedBold"] select _bold, _colour call BIS_fnc_colorRGBAtoHTML, [_text] call EFUNC(tacpad,xmlSafe)]
};

[[_ax, _ay, _aw, _ah], _solid] call _fnc_box;

// ------------------------------------------------------------ tabs ----
private _stripH = _lineH * 1.3;
private _tabW = (_aw - 2 * _gapX) / (count RADIO_APP_TABS + 1);
[[_ax + _gapX, _ay, _tabW, _stripH], ["RADIO", _ink, true] call _fnc_t] call _fnc_text;
{
    private _on = _x isEqualTo GVAR(radioTab);
    private _tx = _ax + _gapX + (_forEachIndex + 1) * _tabW;
    [[_tx, _ay, _tabW, _stripH], [toUpper _x, [_muted, _ink] select _on, _on] call _fnc_t] call _fnc_text;
    if (_on) then {[[_tx, _ay + _stripH - _gapY, _tabW * 0.8, _gapY * 0.6], _accent] call _fnc_box};
} forEach RADIO_APP_TABS;
[[_ax, _ay + _stripH, _aw, NET_EDGE_PX * pixelH], _ink] call _fnc_box;

private _y = _ay + _stripH + _gapY;
private _header = _view get "header";
if (_header isNotEqualTo "") then {
    [[_ax + _gapX, _y, _aw - 2 * _gapX, _lineH], [_header, _ink, true] call _fnc_t] call _fnc_text;
    _y = _y + _lineH * 1.2;
};
if (!_portrait) then {
    {
        _x params ["_label", "_at"];
        [[_ax + _gapX + _at * (_aw - 2 * _gapX), _y, (_aw - 2 * _gapX) * 0.3, _lineH], [_label, _muted] call _fnc_t] call _fnc_text;
    } forEach (_view get "heads");
    _y = _y + _lineH;
};

// ------------------------------------------------- keys, then chips ----
private _keysH = [_nh, _nh + _lineH] select _portrait;
private _keysY = _ay + _ah - _keysH;
private _chips = _view get "chips";
private _chipsH = [0, _lineH * 1.4] select (_chips isNotEqualTo []);
private _rowsBottom = _keysY - _chipsH;

// ------------------------------------------------------------ rows ----
private _list = _view get "rows";
private _rowH = _lineH * ([1.35, 2.3] select _portrait);
private _fits = floor ((_rowsBottom - _y) / _rowH) max 1;
private _cursor = GVAR(radioCursor) min ((count _list - 1) max 0);
private _start = [(_cursor - _fits + 1) max 0, 0] select GVAR(radioGroupMode);
private _calls = GVAR(radioTab) isEqualTo "calls";

if (_list isEqualTo []) then {
    [[_ax + _gapX, _y, _aw - 2 * _gapX, _lineH], [["Nothing here.", "Nobody to call."] select _calls, _muted] call _fnc_t] call _fnc_text;
};
{
    _x params ["_name", "_tag", "_cols"];
    private _index = _start + _forEachIndex;
    private _ry = _y + _forEachIndex * _rowH;
    private _rect = [_ax, _ry, _aw, _rowH];
    if (_index isEqualTo _cursor && !GVAR(radioGroupMode)) then {
        [_rect, _tint] call _fnc_box;
        [_rect, _accent] call _fnc_frame;
    };
    private _first = format ["%1 %2", [_name, _ink, true] call _fnc_t, [_tag, _muted] call _fnc_t];
    private _innerW = _aw - 2 * _gapX;
    if (_portrait) then {
        [[_ax + _gapX, _ry + _gapY, _innerW, _lineH], _first] call _fnc_text;
        private _second = +_cols;
        if (_calls && {_cols isNotEqualTo []}) then {
            (_cols select -1) params ["_text", "_tone"];
            [[_ax + _gapX, _ry + _gapY, _innerW, _lineH], [_text, _tones getOrDefault [_tone, _ink], true] call _fnc_t, "right"] call _fnc_text;
            _second deleteAt (count _second - 1);
        };
        private _parts = (_second select {(_x select 0) isNotEqualTo ""}) apply {[_x select 0, _tones getOrDefault [_x select 1, _ink], true] call _fnc_t};
        [[_ax + _gapX, _ry + _gapY + _lineH, _innerW, _lineH], _parts joinString "  "] call _fnc_text;
    } else {
        [[_ax + _gapX, _ry + _gapY, _innerW * 0.5, _lineH], _first] call _fnc_text;
        {
            _x params ["_text", "_tone", "_at"];
            [[_ax + _gapX + _at * _innerW, _ry + _gapY, _innerW * 0.3, _lineH], [_text, _tones getOrDefault [_tone, _ink], true] call _fnc_t] call _fnc_text;
        } forEach _cols;
    };
    [[_ax, _ry + _rowH - pixelH, _aw, pixelH], _line] call _fnc_box;
} forEach (_list select [_start, _fits]);

// ----------------------------------------------------------- chips ----
if (_chipsH > 0) then {
    private _chipW = (_aw - (count _chips + 1) * _gapX) / count _chips;
    {
        private _on = GVAR(radioGroupMode) && _forEachIndex isEqualTo GVAR(radioCursor);
        private _rect = [_ax + _gapX + _forEachIndex * (_chipW + _gapX), _rowsBottom + _gapY, _chipW, _lineH * 1.1];
        if (_on) then {[_rect, _tint] call _fnc_box};
        [_rect, [_ink, _accent] select _on] call _fnc_frame;
        [_rect, [_x, _ink, true] call _fnc_t, "center"] call _fnc_text;
    } forEach _chips;
};

// ------------------------------------------------------------ keys ----
[[_ax, _keysY, _aw, _keysH], COLOUR_BAR] call _fnc_box;
private _hint = format ["0 %1 cursor %2 .", ARROW_UP_TEXT, ARROW_DOWN_TEXT];
private _cells = [];
if (_portrait) then {
    private _cw = (_aw - 3 * _gapX) / 2;
    private _ch = (_keysH - _lineH - 3 * _gapY) / 2;
    for "_i" from 0 to (SOFT_KEY_COUNT - 1) do {
        _cells pushBack [_ax + _gapX + (_i mod 2) * (_cw + _gapX), _keysY + _gapY + (floor (_i / 2)) * (_ch + _gapY), _cw, _ch];
    };
    [[_ax, _keysY + _keysH - _lineH, _aw, _lineH], [_hint, COLOUR_DIM] call _fnc_t, "center"] call _fnc_text;
} else {
    private _sideW = _aw * 0.04;
    private _cw = (_aw - 2 * _sideW - (SOFT_KEY_COUNT + 1) * _gapX) / SOFT_KEY_COUNT;
    for "_i" from 0 to (SOFT_KEY_COUNT - 1) do {
        _cells pushBack [_ax + _sideW + _gapX + _i * (_cw + _gapX), _keysY + _gapY, _cw, _keysH - 2 * _gapY];
    };
    [[_ax, _keysY + _gapY, _sideW, _lineH], [format ["0 %1", ARROW_UP_TEXT], COLOUR_DIM] call _fnc_t, "center"] call _fnc_text;
    [[_ax + _aw - _sideW, _keysY + _gapY, _sideW, _lineH], [format ["%1 .", ARROW_DOWN_TEXT], COLOUR_DIM] call _fnc_t, "center"] call _fnc_text;
};
{
    _x params ["_label", "_live"];
    if (_label isEqualTo "") then {continue};
    private _rect = _cells select _forEachIndex;
    [_rect, COLOUR_DIM] call _fnc_frame;
    _rect params ["_kx", "_ky", "_kw", "_kh"];
    [
        [_kx, _ky + ((_kh - _lineH) / 2 max 0), _kw, _lineH],
        format ["%1 %2", [format ["F%1", _forEachIndex + 1], COLOUR_DIM] call _fnc_t, [_label, [COLOUR_DIM, COLOUR_TEXT] select _live, true] call _fnc_t],
        "center"
    ] call _fnc_text;
} forEach (_view get "keys");

_display setVariable [QGVAR(radioCtrls), _made];
true
