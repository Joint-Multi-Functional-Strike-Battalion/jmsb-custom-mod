#include "script_component.hpp"
/*
 * Author: JMSB
 * Shows this frame's boxes as UI controls on the mission display: each box
 * four strips laid INSIDE its pixel-snapped rectangle, edge to edge, so the
 * corners meet exactly, and its AiTR label (and net card) centred under it. Controls are
 * pooled - created the first time that many boxes are needed, then moved and
 * recoloured - and the ones not needed this frame are hidden.
 *
 * Arguments:
 * 0: Boxes - [rect, colour RGBA, [structured text, lines]]... <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[[[0.4, 0.4, 0.05, 0.1], [1, 0, 0, 1], ["PERSON | ARMED | 240 m", 1]]]] call jmfsb_ecoti_fnc_drawBoxes
 *
 * Public: No
 */

params ["_boxes"];

private _display = findDisplay IDD_MISSION;
if (isNull _display) exitWith {};

private _lineX = GVAR(lineWidth) * pixelW;
private _lineY = GVAR(lineWidth) * pixelH;
private _labelH = LABEL_PIXELS * pixelH;

{
    _x params ["_rect", "_colour", "_label"];
    _rect params ["_left", "_top", "_w", "_h"];

    if (_forEachIndex >= count GVAR(pool)) then {
        private _set = [QGVAR(strip), QGVAR(strip), QGVAR(strip), QGVAR(strip), QGVAR(label)] apply {_display ctrlCreate [_x, -1]};
        GVAR(pool) pushBack _set;
    };
    (GVAR(pool) select _forEachIndex) params ["_topCtrl", "_bottomCtrl", "_leftCtrl", "_rightCtrl", "_labelCtrl"];

    {
        _x params ["_ctrl", "_pos"];
        _ctrl ctrlSetPosition _pos;
        _ctrl ctrlSetBackgroundColor _colour;
        _ctrl ctrlShow true;
        _ctrl ctrlCommit 0;
    } forEach [
        [_topCtrl, [_left, _top, _w, _lineY]],
        [_bottomCtrl, [_left, _top + _h - _lineY, _w, _lineY]],
        [_leftCtrl, [_left, _top, _lineX, _h]],
        [_rightCtrl, [_left + _w - _lineX, _top, _lineX, _h]]
    ];

    _label params ["_text", "_lines"];
    if (_text isEqualTo "") then {
        _labelCtrl ctrlShow false;
    } else {
        // Parsed only when it changed - the range ticks over, the rest rarely does.
        if (_text isNotEqualTo (_labelCtrl getVariable [QGVAR(text), ""])) then {
            _labelCtrl ctrlSetStructuredText parseText _text;
            _labelCtrl setVariable [QGVAR(text), _text];
        };
        _labelCtrl ctrlSetFade (1 - (_colour select 3));
        _labelCtrl ctrlSetPosition [_left + _w / 2 - LABEL_WIDTH / 2, _top + _h + _lineY, LABEL_WIDTH, _labelH * _lines * LABEL_LINE_SPACING];
        _labelCtrl ctrlShow true;
        _labelCtrl ctrlCommit 0;
    };
} forEach _boxes;

// Hide what was shown last frame and is not needed now.
for "_i" from (count _boxes) to (GVAR(shown) - 1) do {
    {
        _x ctrlShow false;
    } forEach (GVAR(pool) select _i);
};
GVAR(shown) = count _boxes;
