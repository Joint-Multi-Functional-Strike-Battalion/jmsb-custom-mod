#include "script_component.hpp"
/*
 * Author: JMSB
 * The + MARKER list: the map's markers with their grids, one press sends the
 * name and the grid into the thread as a free-text reply. Half of what gets
 * typed into a thread is somebody reading a grid off the map and typing it
 * back in, which is where a digit gets dropped - the marker already knows both.
 *
 * THE LIST OPENS UPWARDS, over the spine rather than under the fold, on its own
 * opaque ground - a translucent dropdown over a thread is two texts in one
 * place. The caller draws it after the replies so it is on top of them.
 *
 * Arguments:
 * 0: Content group <CONTROL>
 * 1: [x of the + MARKER button, y of its top edge, list width, line height] <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_root, [_markerX, _y, _w, _lineH]] call jmfsb_tacpad_fnc_readerMarkers
 *
 * Public: No
 */

#define MARKERS_SHOWN 8

params [["_root", controlNull, [controlNull]], ["_at", [0, 0, 0, 0], [[]], 4]];

if (isNull _root) exitWith {};

_at params ["_mx", "_buttonY", "_listW", "_lineH"];

([] call FUNC(theme)) params ["_ground", "_ink", "", "_line"];
private _muted = ["muted"] call FUNC(theme);
private _dim = ["dim"] call FUNC(theme);

private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

private _markers = [MARKERS_SHOWN] call FUNC(markerGrids);
private _listH = _lineH * (1 + (1 max count _markers)) + _padY * 2;
private _listY = _buttonY - _listH - _padY;
private _solid = [_ground # 0, _ground # 1, _ground # 2, 1];

[_root, [_mx, _listY, _listW, _listH], _solid] call FUNC(drawFill);
[_root, [_mx, _listY, _listW, _listH], _ink, RULE_THICK] call FUNC(drawFrame);
[_root, [_mx + _pad * 2, _listY + _padY, _listW - _pad * 4, _lineH], "SEND A MARKER", _muted, READER_K_SIZE, true, "left", true] call FUNC(drawText);

if (_markers isEqualTo []) exitWith {
    [_root, [_mx + _pad * 2, _listY + _padY + _lineH, _listW - _pad * 4, _lineH], "NO MAP MARKERS", _dim, READER_BODY_SIZE] call FUNC(drawText);
};

private _freeKey = ((["freetext"] call EFUNC(messaging,template)) getOrDefault ["order", []]) param [0, "Text.A"];

{
    _x params ["_label", "_pos"];
    private _my = _listY + _padY + _lineH * (1 + _forEachIndex);

    [_root, [_mx + _pad * 2, _my, _listW * 0.6 - _pad * 2, _lineH], _label, _ink, READER_BODY_SIZE] call FUNC(drawText);
    [_root, [_mx + _listW * 0.6, _my, _listW * 0.4 - _pad * 2, _lineH], mapGridPosition _pos, _muted, READER_BODY_SIZE, false, "right"] call FUNC(drawText);
    [_root, [_mx + _pad * 2, _my + _lineH - RULE_THIN * pixelH, _listW - _pad * 4, RULE_THIN * pixelH], _line] call FUNC(drawFill);

    private _hit = [_root, [_mx, _my, _listW, _lineH], {
        params ["_ctrl"];
        private _text = _ctrl getVariable [QGVAR(markerLine), ""];
        if (_text isEqualTo "") exitWith {};

        GVAR(readerMarkers) = false;
        ["freetext", [[_ctrl getVariable [QGVAR(quickKey), ""], _text]], [], GVAR(readerThread)] call EFUNC(messaging,submit);
        {[] call FUNC(readerDraw)} call CBA_fnc_execNextFrame;
    }] call FUNC(drawHit);

    // The name AND the grid, because a call sign nobody else has on their map
    // is not a location.
    _hit setVariable [QGVAR(markerLine), format ["%1 - %2", _label, mapGridPosition _pos]];
    _hit setVariable [QGVAR(quickKey), _freeKey];
} forEach _markers;
