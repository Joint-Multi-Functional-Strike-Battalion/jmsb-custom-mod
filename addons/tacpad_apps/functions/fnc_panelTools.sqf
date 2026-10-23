#include "script_component.hpp"
/*
 * Author: JMSB
 * The MAP TOOLS strip: the front end for jmfsb_maptools, on the vanilla map and
 * on the tablet's screen alike. A four-across grid of outlined cells.
 *
 * THE TOOLS ARE OURS. Ruler, protractor, mark, grid, viewshed and route are
 * jmfsb_maptools' (see its README); this panel only starts and stops them, and
 * hangs them on the host's map (EFUNC(maptools,attach)) so they draw and take
 * clicks on whichever map the suite is on. There is no other mod behind it,
 * so there is no dimmed state: the panel exists when the addon does - see the
 * registration in XEH_preInit.
 *
 * Six cells are TOGGLES - press to start, press again to stop, and the running
 * one inverts to an ink fill so the strip says what is on. Two are momentary:
 * CENTRE puts the map back on the player and leaves the running tool alone,
 * and CLEAR, the one accent-outlined cell, wipes what the tools drew. CANCEL on
 * the title bar stops the running tool without the player having to know which
 * one it was.
 *
 * CENTRE IS FIRST because it is the one pressed most. A man looking at his own
 * map has usually panned away from himself.
 *
 * Arguments:
 * 0: Body <CONTROL>
 * 1: Panel id <STRING>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

// The two momentary cells' ids. Everything else is a jmfsb_maptools tool id.
#define TOOLS_CENTRE "centre"
#define TOOLS_CLEAR "clear"

params [["_body", controlNull, [controlNull]], ["_id", "", [""]]];

if (isNull _body) exitWith {};

{ctrlDelete _x} forEach (allControls (ctrlParent _body) select {(ctrlParentControlsGroup _x) isEqualTo _body});

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

// Wherever the strip is drawn is the map the tools work on. Once per control.
[(ctrlParent _body) displayCtrl IDC_HOST_MAP] call EFUNC(maptools,attach);

private _w = (ctrlPosition _body) # 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

// [label, id]. Two rows of four.
private _tools = [
    ["CENTRE", TOOLS_CENTRE],
    ["RULER", "ruler"],
    ["PROTRACTOR", "protractor"],
    ["ROUTE", "route"],
    ["MARK", "mark"],
    ["GRID", "grid"],
    ["VIEWSHED", "viewshed"],
    ["CLEAR", TOOLS_CLEAR]
];

// CANCEL LIVES ON THE TITLE BAR - the user's ask: it had a grid row to itself
// once. Drawn into the GROUP's header, over the meta slot the strip never uses
// for a readout.
private _entry = (missionNamespace getVariable [QEGVAR(tacpad,open), createHashMap]) getOrDefault [_id, []];
_entry params [["_group", controlNull]];
if (!isNull _group) then {
    (ctrlPosition _group) params ["", "", "_gw"];
    private _headerH = HEADER_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H;
    private _offW = _gw * 0.18;
    private _offX = _gw - _offW - _pad - RULE_THICK * pixelW;
    private _offRect = [_offX, RULE_THICK * pixelH + _padY * 0.3, _offW, _headerH - _padY * 0.6];

    [_group, _offRect, _accent, RULE_THICK] call EFUNC(tacpad,drawFrame);
    [_group, _offRect, "CANCEL", _accent, TEXT_BODY, true, "center"] call EFUNC(tacpad,drawText);
    [_group, _offRect, {
        [] call EFUNC(maptools,stop);
        {["tools"] call EFUNC(tacpad,rebuild)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
};

private _cols = 4;
private _rows = ceil (count _tools / _cols);
private _cellW = (_w - 2 * _pad) / _cols;

// SIZED OFF THE LABEL, not off a row. A fixed fraction of ROW_H is a gamble on
// the player's UI scale: at anything above the default the label was taller than
// the cell and the cell's own bottom edge was drawn straight through the middle
// of the word. The box is the line plus a pad, so it fits at any scale.
private _labelSize = TEXT_BODY;
private _cellH = ([_labelSize] call EFUNC(tacpad,textH)) + 2 * _padY;

private _runningTool = missionNamespace getVariable [QEGVAR(maptools,tool), ""];

{
    _x params ["_label", "_tool"];

    private _clear = _tool isEqualTo TOOLS_CLEAR;
    private _running = _tool isEqualTo _runningTool;

    private _cx = _pad + (_forEachIndex mod _cols) * _cellW;
    private _cy = _padY + floor (_forEachIndex / _cols) * (_cellH + _padY);

    // Cells sit in the grid with a gap, so the outlines never double up into a
    // 4px rule where two of them meet.
    private _boxW = _cellW - _pad;

    // The running tool is the one filled cell - the design's pressed state, held
    // rather than momentary, because the tool is still on the map.
    if (_running) then {
        [_body, [_cx, _cy, _boxW, _cellH], _ink] call EFUNC(tacpad,drawFill);
    } else {
        [_body, [_cx, _cy, _boxW, _cellH], [_ink, _accent] select _clear, RULE_THICK] call EFUNC(tacpad,drawFrame);
    };

    private _labelInk = switch (true) do {
        case (_running): {_ground};
        case (_clear): {_accent};
        default {_ink};
    };
    [_body, [_cx + _pad, _cy, _boxW - 2 * _pad, _cellH], _label, _labelInk, _labelSize, true] call EFUNC(tacpad,drawText);

    private _hit = [_body, [_cx, _cy, _boxW, _cellH], {
        params ["_ctrl"];

        private _tool = _ctrl getVariable [QGVAR(tool), ""];
        private _map = (ctrlParent _ctrl) displayCtrl IDC_HOST_MAP;

        switch (_tool) do {
            case TOOLS_CENTRE: {[_map] call EFUNC(maptools,centre)};
            case TOOLS_CLEAR: {[] call EFUNC(maptools,clear)};
            default {[_tool] call EFUNC(maptools,start)};
        };

        // Next frame: the rebuild deletes this very button, so it is deferred
        // out of its own handler rather than pulled out from under it.
        {["tools"] call EFUNC(tacpad,rebuild)} call CBA_fnc_execNextFrame;
    }] call EFUNC(tacpad,drawHit);
    _hit setVariable [QGVAR(tool), _tool];
} forEach _tools;

[_id, 0, (_rows * (_cellH + _padY) + 2 * _padY) / HOST_H] call EFUNC(tacpad,fit);
