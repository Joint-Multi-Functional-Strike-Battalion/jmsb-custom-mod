#include "script_component.hpp"
/*
 * Author: YonV
 * Shows this frame's world panels (FUNC(draw)) as UI controls on the mission
 * display (user, 2026-11-08: "center and put some shading behind it"): each a
 * shaded backdrop centred on its point, the lines centred on it, and under
 * them, on a full panel with a profile trace, the EKG (FUNC(trace)) as one
 * strip per column, the pleth under it. Sizes are 1080-line pixels scaled to
 * the screen (REF_X / REF_Y), snapped to whole pixels - the
 * ecoti boxes' way; none while a dialog (the tablet) or the map is up.
 * Controls are pooled: made the first time that many
 * panels (or trace columns) are needed, then moved and recoloured; the ones
 * not needed this frame are hidden.
 *
 * Arguments:
 * 0: Panels - [screen centre [x, y], lines [[text, RGBA]...], tag <BOOL>,
 *    trace (FUNC(trace)) or []]... <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[[[0.5, 0.5], [["1  DOE - T2", [1, 1, 1, 1]]], true, []]]] call jmfsb_watch_fnc_hudDraw
 *
 * Public: No
 */

params [["_panels", [], [[]]]];

// NOT THROUGH THE TABLET (user, 2026-11-08: "hud showing through tablet ...
// a big no"): nothing while a dialog or the map is up, as the ecoti boxes.
if (dialog || {visibleMap}) then {_panels = []};

private _display = findDisplay HUD_DISPLAY;
if (isNull _display) exitWith {};
// a pool from a display gone (a mission restarted) starts again
if (GVAR(hudPool) isNotEqualTo [] && {isNull ((GVAR(hudPool) # 0) # 0)}) then {
    GVAR(hudPool) = [];
    GVAR(hudShown) = 0;
};

private _pad = REF_Y(HUD_PAD_PIXELS);
private _padX = REF_X(HUD_PAD_PIXELS);
private _traceH = REF_Y(TRACE_PIXELS);
private _plethH = REF_Y(PLETH_PIXELS);
private _lineMin = PIXEL_Y(REF_Y(TRACE_LINE_PIXELS)) max pixelH;

{
    _x params ["_screen", "_lines", "_tag", "_wave"];
    _screen params ["_cx", "_cy"];

    if (_forEachIndex >= count GVAR(hudPool)) then {
        GVAR(hudPool) pushBack [_display ctrlCreate ["RscText", -1], _display ctrlCreate ["RscStructuredText", -1], []];
    };
    (GVAR(hudPool) # _forEachIndex) params ["_back", "_textCtrl", "_strips"];

    private _fontH = [HUD_TEXT_PIXELS, HUD_TAG_PIXELS] select _tag;
    _fontH = REF_Y(_fontH);
    private _textH = count _lines * _fontH * HUD_LINE_SPACING;
    private _w = [HUD_WIDTH_PIXELS, HUD_TAG_WIDTH_PIXELS] select _tag;
    _w = REF_X(_w);
    _w = PIXEL_X(_w);
    private _h = [0, _traceH + _plethH + _pad * 2] select (_wave isNotEqualTo []);
    _h = PIXEL_Y(_pad * 2 + _textH + _h);
    private _left = PIXEL_X(_cx - _w / 2);
    private _top = PIXEL_Y(_cy - _h / 2);

    _back ctrlSetPosition [_left, _top, _w, _h];
    _back ctrlSetBackgroundColor COLOUR_HUD_BACK;
    _back ctrlShow true;
    _back ctrlCommit 0;

    private _text = (_lines apply {
        _x params ["_line", "_rgba"];
        format ["<t align='center' font='%1' color='%2'>%3</t>", HUD_FONT, _rgba call BIS_fnc_colorRGBAtoHTML, _line]
    }) joinString "<br/>";
    // parsed only when it changed - the values tick over, not every frame
    if (_text isNotEqualTo (_textCtrl getVariable [QGVAR(text), ""])) then {
        _textCtrl ctrlSetStructuredText parseText _text;
        _textCtrl setVariable [QGVAR(text), _text];
    };
    _textCtrl ctrlSetFontHeight _fontH;
    _textCtrl ctrlSetPosition [_left, _top + _pad, _w, _textH];
    _textCtrl ctrlShow true;
    _textCtrl ctrlCommit 0;

    // the traces: a strip per column, from its low to its high - the EKG,
    // then the pleth under it
    private _used = 0;
    private _fnc_strips = {
        params ["_columns", "_colour", "_base", "_scale"];
        private _colW = (_w - _padX * 2) / count _columns;
        {
            _x params ["_lo", "_hi"];
            if (_used >= count _strips) then {_strips pushBack (_display ctrlCreate ["RscText", -1])};
            private _strip = _strips # _used;
            _used = _used + 1;
            private _y0 = PIXEL_Y(_base - _hi * _scale - _lineMin / 2);
            private _x0 = PIXEL_X(_left + _padX + _forEachIndex * _colW);
            _strip ctrlSetPosition [_x0, _y0, (PIXEL_X(_left + _padX + (_forEachIndex + 1) * _colW) - _x0) max pixelW,
                (PIXEL_Y((_hi - _lo) * _scale + _lineMin)) max _lineMin];
            _strip ctrlSetBackgroundColor _colour;
            _strip ctrlShow true;
            _strip ctrlCommit 0;
        } forEach _columns;
    };
    if (_wave isNotEqualTo []) then {
        _wave params ["_ekg", "_colour", ["_pleth", []]];
        private _ekgTop = _top + _pad + _textH + _pad;
        [_ekg, _colour, _ekgTop + _traceH * TRACE_BASELINE, _traceH * TRACE_SCALE] call _fnc_strips;
        if (_pleth isNotEqualTo []) then {
            [_pleth, PLETH_CYAN, _ekgTop + _traceH + _pad + _plethH, _plethH] call _fnc_strips;
        };
    };
    for "_i" from _used to (count _strips - 1) do {(_strips # _i) ctrlShow false};
} forEach _panels;

// Hide what was shown last frame and is not needed now.
for "_i" from (count _panels) to (GVAR(hudShown) - 1) do {
    (GVAR(hudPool) # _i) params ["_back", "_textCtrl", "_strips"];
    _back ctrlShow false;
    _textCtrl ctrlShow false;
    {_x ctrlShow false} forEach _strips;
};
GVAR(hudShown) = count _panels;
