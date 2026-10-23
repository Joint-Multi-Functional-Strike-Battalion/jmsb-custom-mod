#include "script_component.hpp"
/*
 * Author: JMSB
 * The AiTR compass (user, 2026-10-19: "a compass on the top like DUI has, the
 * direction you're facing should match the colour scheme"). A line compass
 * across the top centre of the screen: a tick every 5 degrees, a label every
 * 15 - N, NE, E... by name, the rest as bearings - fading toward the ends, and
 * at the centre a marker and the three-digit heading in the TAC//PAD accent
 * colour.
 *
 * CONTROLS ON THE MISSION DISPLAY, like the boxes - not a cutRsc layer as DUI
 * draws it. FUNC(draw) already runs every frame and already knows whether AiTR
 * is up (FUNC(isActive), no dialog over it), so the compass is shown and hidden
 * by the same test in the same place, and its controls die with the mission as
 * the boxes' do. A layer would want its own handler and its own idea of when
 * it is on, and the two could disagree.
 *
 * The strip is not slid as a whole: each frame the ticks and labels in view are
 * placed by their offset from the heading, so the controls are only as many as
 * one half-circle needs.
 *
 * Arguments:
 * 0: Show <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [true] call jmfsb_ecoti_fnc_drawCompass
 *
 * Public: No
 */

params ["_show"];

if (!_show) exitWith {
    if (GVAR(compassShown)) then {
        GVAR(compassCtrls) params ["_marker", "_readout", "_ticks", "_labels"];
        {
            _x ctrlShow false;
        } forEach ([_marker, _readout] + _ticks + _labels);
        GVAR(compassShown) = false;
    };
};

private _display = findDisplay IDD_MISSION;
if (isNull _display) exitWith {};

// Made once. Ticks first and the marker last, so the marker lies over them.
if (GVAR(compassCtrls) isEqualTo [] || {isNull (GVAR(compassCtrls) select 0)}) then {
    private _ticks = [];
    for "_i" from 1 to COMPASS_TICKS do {
        _ticks pushBack (_display ctrlCreate [QGVAR(strip), -1]);
    };
    private _labels = [];
    for "_i" from 1 to COMPASS_LABELS do {
        _labels pushBack (_display ctrlCreate [QGVAR(compassText), -1]);
    };
    private _marker = _display ctrlCreate [QGVAR(strip), -1];
    private _readout = _display ctrlCreate [QGVAR(compassText), -1];
    _readout ctrlSetFontHeight COMPASS_GY(COMPASS_FONT_READOUT);
    GVAR(compassCtrls) = [_marker, _readout, _ticks, _labels];
};
GVAR(compassCtrls) params ["_marker", "_readout", "_ticks", "_labels"];
GVAR(compassShown) = true;

// Where the player is looking, as DUI reads it: the camera's view, not the body's.
private _view = getCameraViewDirection (call CBA_fnc_currentUnit);
private _heading = (((_view select 0) atan2 (_view select 1)) + FULL_CIRCLE) % FULL_CIRCLE;

private _degX = COMPASS_GX(COMPASS_DEG_COLS);
private _top = safeZoneY + COMPASS_GY(COMPASS_TOP);
private _tickW = COMPASS_TICK_PIXELS * pixelW;

// --- Ticks: white, full strength in the middle, gone at the ends ----------------
private _first = (ceil ((_heading - COMPASS_HALF_SPAN) / COMPASS_TICK_STEP)) * COMPASS_TICK_STEP;
{
    private _bearing = _first + _forEachIndex * COMPASS_TICK_STEP;
    private _offset = _bearing - _heading;
    private _alpha = (((COMPASS_HALF_SPAN - abs _offset) / COMPASS_FADE) min 1) max 0;
    private _rows = [COMPASS_TICK_MINOR, COMPASS_TICK_MAJOR] select ((_bearing % COMPASS_LABEL_STEP) == 0);
    private _h = COMPASS_GY(_rows);

    _x ctrlSetPosition [PIXEL_X(SCREEN_CENTRE + _offset * _degX - _tickW / 2), PIXEL_Y(_top), _tickW, PIXEL_Y(_h)];
    _x ctrlSetBackgroundColor [1, 1, 1, _alpha];
    _x ctrlShow true;
    _x ctrlCommit 0;
} forEach _ticks;

// --- Labels: a name on the 45s, a bearing on the other 15s ----------------------
private _labelW = COMPASS_GX(COMPASS_LABEL_W);
private _firstLabel = (ceil ((_heading - COMPASS_HALF_SPAN) / COMPASS_LABEL_STEP)) * COMPASS_LABEL_STEP;
{
    private _bearing = _firstLabel + _forEachIndex * COMPASS_LABEL_STEP;
    private _offset = _bearing - _heading;
    private _alpha = (((COMPASS_HALF_SPAN - abs _offset) / COMPASS_FADE) min 1) max 0;
    private _wrapped = ((_bearing % FULL_CIRCLE) + FULL_CIRCLE) % FULL_CIRCLE;

    // Text and size only when the bearing this control carries has changed.
    if (_wrapped != (_x getVariable [QGVAR(bearing), -1])) then {
        _x setVariable [QGVAR(bearing), _wrapped];
        if ((_wrapped % COMPASS_NAME_STEP) == 0) then {
            _x ctrlSetText (COMPASS_NAMES select (_wrapped / COMPASS_NAME_STEP));
            _x ctrlSetFontHeight COMPASS_GY(COMPASS_FONT_NAME);
        } else {
            _x ctrlSetText ([_wrapped, HEADING_DIGITS] call CBA_fnc_formatNumber);
            _x ctrlSetFontHeight COMPASS_GY(COMPASS_FONT_NUMBER);
        };
    };

    _x ctrlSetPosition [SCREEN_CENTRE + _offset * _degX - _labelW / 2, _top + COMPASS_GY(COMPASS_LABEL_TOP), _labelW, COMPASS_GY(COMPASS_LABEL_H)];
    _x ctrlSetTextColor [1, 1, 1, _alpha];
    _x ctrlShow true;
    _x ctrlCommit 0;
} forEach _labels;

// --- The centre: marker and heading in the scheme's accent ----------------------
// The TAC//PAD's own accent, so the compass reads as the same suite; white when
// the TAC//PAD is not loaded.
private _accent = if (isNil QEFUNC(tacpad,theme)) then {COMPASS_WHITE} else {["accent"] call EFUNC(tacpad,theme)};

private _markerW = COMPASS_MARKER_PIXELS * pixelW;
private _over = COMPASS_GY(COMPASS_MARKER_OVER);
_marker ctrlSetPosition [PIXEL_X(SCREEN_CENTRE - _markerW / 2), PIXEL_Y(_top - _over), _markerW, PIXEL_Y(COMPASS_GY(COMPASS_TICK_MAJOR) + 2 * _over)];
_marker ctrlSetBackgroundColor _accent;
_marker ctrlShow true;
_marker ctrlCommit 0;

private _readoutW = COMPASS_GX(COMPASS_READOUT_W);
_readout ctrlSetText ([(round _heading) % FULL_CIRCLE, HEADING_DIGITS] call CBA_fnc_formatNumber);
_readout ctrlSetPosition [SCREEN_CENTRE - _readoutW / 2, _top + COMPASS_GY(COMPASS_READOUT_TOP), _readoutW, COMPASS_GY(COMPASS_READOUT_H)];
_readout ctrlSetTextColor _accent;
_readout ctrlShow true;
_readout ctrlCommit 0;
