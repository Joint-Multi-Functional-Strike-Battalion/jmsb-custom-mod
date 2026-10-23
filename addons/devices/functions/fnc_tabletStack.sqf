#include "script_component.hpp"
/*
 * Author: JMSB
 * Stacks the tablet's right-hand column from the panels' real bottoms: map
 * tools under TROOPS IN CONTACT, the reader under the map tools and down to
 * the foot of the map area.
 *
 * THE FIXED PLACES ARE WHERE THE PANELS ARE BUILT, NOT WHERE THEY END. Each
 * panel then fits itself to the type size - the strip, TIC (which re-places
 * itself under the strip, jmfsb_tacpad_apps_fnc_panelTic) and the map tools all
 * grow with the text and UI scales - so fixed y values ran each one into the
 * next. On the vanilla map they sit in different screen regions and never
 * stack; on the tablet they share one column.
 *
 * Moves only what is out of place by more than a pixel, so the tick that calls
 * it costs nothing once the column has settled. The reader, which keeps the
 * height it is given, is resized through the shell's own fit and rebuilt on
 * the next frame - never inside a press.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Moved anything <BOOL>
 *
 * Example:
 * [] call jmfsb_devices_fnc_tabletStack
 *
 * Public: No
 */

private _open = missionNamespace getVariable [QEGVAR(tacpad,open), createHashMap];
if (count _open == 0) exitWith {false};

private _gap = TABLET_STACK_GAP * HOST_H;
private _moved = false;

// The column so far ends at the strip's bottom, or TIC's under it.
private _bottom = HOST_Y;
{
    (_open getOrDefault [_x, []]) params [["_group", controlNull]];
    if (isNull _group) then {continue};
    (ctrlPosition _group) params ["", "_gy", "", "_gh"];
    _bottom = _bottom max (_gy + _gh);
} forEach (TABLET_STRIP + ["tic"]);

// MAP TOOLS: moved, never resized - the panel fits its own height.
(_open getOrDefault ["tools", []]) params [["_tools", controlNull]];
if (!isNull _tools) then {
    (ctrlPosition _tools) params ["_tx", "_ty", "_tw", "_th"];
    private _want = _bottom + _gap;
    if (abs (_ty - _want) > pixelH) then {
        _tools ctrlSetPosition [_tx, _want, _tw, _th];
        _tools ctrlCommit 0;
        _moved = true;
    };
    _bottom = _want + _th;
};

// THE READER: under whatever is above it, down to the map area's foot.
(_open getOrDefault ["reader", []]) params [["_reader", controlNull]];
if (isNull _reader) exitWith {_moved};

(ctrlPosition _reader) params ["_rx", "_ry", "_rw", "_rh"];
private _want = _bottom + _gap;
private _wantH = HOST_Y + HOST_H - _gap - _want;
if (abs (_ry - _want) <= pixelH && {abs (_rh - _wantH) <= pixelH}) exitWith {_moved};

_reader ctrlSetPosition [_rx, _want, _rw, _rh];
_reader ctrlCommit 0;

// The shell's fit re-lays the ground, the outline and the body from the
// height it is handed, so the reader's height is handed over as its body: the
// whole height less the title bar, the rule under it and the two outline edges.
private _panel = EGVAR(tacpad,panels) getOrDefault ["reader", createHashMap];
private _chromeH = 2 * RULE_THICK * pixelH;
if (_panel getOrDefault ["chrome", true]) then {
    _chromeH = _chromeH + HEADER_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * HOST_H + RULE_THICK * pixelH;
};
["reader", 0, ((_wantH - _chromeH) / HOST_H) max 0] call EFUNC(tacpad,fit);
[{["reader"] call EFUNC(tacpad,rebuild)}] call CBA_fnc_execNextFrame;

true
