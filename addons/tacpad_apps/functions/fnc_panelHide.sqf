#include "script_component.hpp"
/*
 * Author: JMSB
 * HIDE ALL, and the SHOW ALL that undoes it. The one panel the master switch
 * does not take with it.
 *
 * IT IS ITS OWN PANEL BECAUSE OF WHAT IT SURVIVES. It was a cell in the settings
 * strip, and the strip had to be pinned for it - so hiding the suite left a
 * settings button on the map with nothing left to configure, and the one thing
 * a player wanted off screen was the thing that stayed. Split, HIDE ALL takes
 * the gear with everything else and leaves exactly one control behind.
 *
 * SHOW ALL is drawn in the accent, because when it is the only thing on the map
 * it has to be found without hunting.
 *
 * NO TITLE BAR. The panel is registered chromeless, so what is on screen is the
 * cell and its outline - a header reading PANELS over a cell reading HIDE ALL
 * was a label for a label, and on a strip this short the bar was half of it.
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

params [["_body", controlNull, [controlNull]], ["_id", "", [""]]];

if (isNull _body) exitWith {};

{ctrlDelete _x} forEach (allControls (ctrlParent _body) select {(ctrlParentControlsGroup _x) isEqualTo _body});

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _pos = ctrlPosition _body;
private _w = _pos # 2;
private _pad = PAD * HOST_W;
private _padY = PAD * HOST_H;

private _labelSize = TEXT_BODY;
private _cellH = ([_labelSize] call EFUNC(tacpad,textH)) + 2 * _padY;
private _cellY = _padY * 1.5;
private _cellX = _pad;
private _cellW = _w - _cellX - _pad;

private _hidden = EGVAR(tacpad,hideAll);

[_body, [_cellX, _cellY, _cellW, _cellH], ([_ink, _accent] select _hidden), RULE_THICK] call EFUNC(tacpad,drawFrame);
[
    _body, [_cellX + _pad, _cellY, _cellW - 2 * _pad, _cellH],
    ["HIDE ALL", "SHOW ALL"] select _hidden,
    ([_ink, _accent] select _hidden),
    _labelSize, true, "center"
] call EFUNC(tacpad,drawText);

// THE WHOLE PANEL IS THE BUTTON. A one-cell strip has nothing else in it to
// press, and hunting for the live part of a bar the size of a bootlace is not
// an interaction - so the hit covers the body edge to edge, margins included.
// Sized to what EFUNC(tacpad,fit) is about to make the body, not to what it is
// now - the panel is still whatever height it was placed at on this line.
[_body, [_cellX, 0, _w - _cellX, _cellH + 3 * _padY], {
    EGVAR(tacpad,hideAll) = !EGVAR(tacpad,hideAll);
    {[] call EFUNC(tacpad,open)} call CBA_fnc_execNextFrame;
}] call EFUNC(tacpad,drawHit);

[_id, 0, (_cellH + 3 * _padY) / HOST_H] call EFUNC(tacpad,fit);
