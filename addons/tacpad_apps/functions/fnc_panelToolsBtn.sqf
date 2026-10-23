#include "script_component.hpp"
/*
 * Author: JMSB
 * The TOOLS button: shows or hides the MAP TOOLS bar.
 *
 * MAP TOOLS IS TWO ROWS OF FOUR, and that is a lot of map to give up to
 * buttons nobody is pressing. It earns its place while somebody is measuring a
 * distance or checking a profile and is in the way the rest of the time, so it
 * gets a switch of its own rather than living or dying with the master HIDE.
 *
 * IT WORKS THROUGH THE PANEL'S CONDITION, not by deleting anything. Every panel
 * is asked on each map open whether it wants to be there - see
 * EFUNC(tacpad,open) - so the switch is a variable the tools panel's condition
 * reads, and the suite rebuilds itself the way it already knows how.
 *
 * Shaped on FUNC(panelHide): a chromeless one-cell strip whose whole body is the
 * hit area, because hunting for the live part of a bar this size is not an
 * interaction.
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

// SHOWN IS THE DEFAULT, so a mission that has never touched this looks exactly
// as it did before the button existed.
private _shown = missionNamespace getVariable [QGVAR(toolsShown), true];

// Accent when the bar is OFF, matching HIDE ALL - the coloured state is the
// unusual one, so a glance down the row says which switches are thrown.
[_body, [_cellX, _cellY, _cellW, _cellH], ([_accent, _ink] select _shown), RULE_THICK] call EFUNC(tacpad,drawFrame);
[
    _body, [_cellX + _pad, _cellY, _cellW - 2 * _pad, _cellH],
    "TOOLS",
    ([_accent, _ink] select _shown),
    _labelSize, true, "center"
] call EFUNC(tacpad,drawText);

[_body, [_cellX, 0, _w - _cellX, _cellH + 3 * _padY], {
    GVAR(toolsShown) = !(missionNamespace getVariable [QGVAR(toolsShown), true]);
    {[] call EFUNC(tacpad,open)} call CBA_fnc_execNextFrame;
}] call EFUNC(tacpad,drawHit);

[_id, 0, (_cellH + 3 * _padY) / HOST_H] call EFUNC(tacpad,fit);
