#include "script_component.hpp"
/*
 * Author: YonV
 * The support threads' LZs and DZs in the AiTR (user, 2026-11-02: "in AiTR lz
 * and drop zones need to be highlighted"): each zone FUNC(updateZones) picked a
 * ring of dots on the ground, its radius round its centre, and under it its
 * label in the AiTR style - LZ | PICKUP | RAVEN | 1.2 km - all in the TAC//PAD
 * accent, as the compass's heading.
 *
 * A NAV AID, NOT A SIGHTING: at any range and through anything, no line of
 * sight. It keeps the boxes' other rules - drawn while they could be (FUNC(draw):
 * AiTR on, no dialog, map or Zeus), each dot and the label inside the round
 * window only unless full screen, nothing off the screen.
 *
 * CONTROLS ON THE MISSION DISPLAY, like the boxes: per zone ZONE_RING_DOTS
 * pixel-snapped squares and a label, pooled - made the first time that many
 * zones are drawn, then moved - and hidden when not needed. Only projected
 * here: the rings were worked out when the list came.
 *
 * Arguments:
 * 0: Show <BOOL>
 * 1: The window, screen heights from the centre <NUMBER> (optional, default 0)
 *
 * Return Value:
 * None
 *
 * Example:
 * [true, 0.375] call jmfsb_ecoti_fnc_drawZones
 *
 * Public: No
 */

params ["_show", ["_window", 0]];

private _zones = [[], GVAR(zoneDraw)] select _show;

private _display = findDisplay IDD_MISSION;
if (_zones isNotEqualTo [] && isNull _display) exitWith {};

private _dotW = GVAR(lineWidth) * ZONE_DOT_SCALE * pixelW;
private _dotH = GVAR(lineWidth) * ZONE_DOT_SCALE * pixelH;
private _labelH = LABEL_PIXELS * pixelH;
private _colour = GVAR(zoneAccent);

{
    _x params ["_centre", "_ring", "_words"];

    if (_forEachIndex >= count GVAR(zonePool)) then {
        private _dots = [];
        for "_i" from 1 to ZONE_RING_DOTS do {
            _dots pushBack (_display ctrlCreate [QGVAR(strip), -1]);
        };
        private _labelCtrl = _display ctrlCreate [QGVAR(compassText), -1];
        _labelCtrl ctrlSetFontHeight _labelH;
        GVAR(zonePool) pushBack [_dots, _labelCtrl];
    };
    (GVAR(zonePool) select _forEachIndex) params ["_dots", "_labelCtrl"];

    // The ring: each dot on its own, inside the window and on the screen.
    private _lowest = -1;
    {
        private _scr = worldToScreen _x;
        private _in = ON_SCREEN(_scr);
        if (_in) then {_in = SCREEN_DIST(_scr) <= _window};
        private _dot = _dots select _forEachIndex;
        if (_in) then {
            _scr params ["_sx", "_sy"];
            _dot ctrlSetPosition [PIXEL_X(_sx - _dotW / 2), PIXEL_Y(_sy - _dotH / 2), _dotW, _dotH];
            _dot ctrlSetBackgroundColor _colour;
            _dot ctrlShow true;
            _dot ctrlCommit 0;
            _lowest = _lowest max _sy;
        } else {
            _dot ctrlShow false;
        };
    } forEach _ring;

    // The label: while the centre is in view, under the ring's lowest dot.
    private _centreScr = worldToScreen _centre;
    private _centreIn = ON_SCREEN(_centreScr);
    if (_centreIn) then {_centreIn = SCREEN_DIST(_centreScr) <= _window};
    if (_centreIn) then {
        _centreScr params ["_cx", "_cy"];
        private _text = _words + ([player distance2D _centre] call FUNC(rangeText));
        if (_text isNotEqualTo (_labelCtrl getVariable [QGVAR(text), ""])) then {
            _labelCtrl ctrlSetText _text;
            _labelCtrl setVariable [QGVAR(text), _text];
        };
        _labelCtrl ctrlSetPosition [_cx - LABEL_WIDTH / 2, (_cy max _lowest) + _dotH, LABEL_WIDTH, _labelH * LABEL_LINE_SPACING];
        _labelCtrl ctrlSetTextColor _colour;
        _labelCtrl ctrlShow true;
        _labelCtrl ctrlCommit 0;
    } else {
        _labelCtrl ctrlShow false;
    };
} forEach _zones;

// Hide what was shown last frame and is not needed now.
for "_i" from (count _zones) to (GVAR(zonesShown) - 1) do {
    (GVAR(zonePool) select _i) params ["_dots", "_labelCtrl"];
    {
        _x ctrlShow false;
    } forEach (_dots + [_labelCtrl]);
};
GVAR(zonesShown) = count _zones;
