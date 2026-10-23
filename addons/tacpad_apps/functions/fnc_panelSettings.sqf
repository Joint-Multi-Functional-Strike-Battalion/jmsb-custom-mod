#include "script_component.hpp"
/*
 * Author: JMSB
 * The gear, directly under the message reader. One cell, one job: open the
 * settings app.
 *
 * It sits here rather than in a menu because settings for the suite belong
 * where the suite is. A player who wants the panel colours changed is looking
 * at the panels when they decide that, and sending them to Options > Addon
 * Options > scroll is how a setting stops being used.
 *
 * THE WHOLE STRIP IS THE BUTTON. It shared the strip with HIDE ALL, which left
 * the gear an icon and a clipped word squeezed into two thirds of a narrow
 * panel - a button that looked like a decoration. Hiding is its own panel now
 * (see FUNC(panelHide)) and this cell spans the frame it is drawn in.
 *
 * AND THERE IS NO TITLE BAR OVER IT. The panel is registered chromeless, so what
 * is on screen is the cell and its outline and nothing else - see
 * EFUNC(tacpad,register). The label came down to one word at the same time: the
 * strip is a third of the reader's width now that ADMIN sits beside it, and
 * DISPLAY - COLOUR SCHEME was two thirds of a sentence in a button.
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

// A REAL MARGIN, not a centring calculation. The strip was fitted to exactly one
// row, so the cell filled the body edge to edge and there was no space between
// the title bar and it to centre into. The panel is sized to the cell PLUS the
// margin, and the cell sits at the margin.
//
private _cellY = _padY * 1.5;
private _cellX = _pad;
private _cellW = _w - _cellX - _pad;

[_body, [_cellX, _cellY, _cellW, _cellH], _ink, RULE_THICK] call EFUNC(tacpad,drawFrame);

// A gear alone is recognisable; a gear with the word beside it is unmissable.
//
// TIGHT TO THE GEAR, AND THE FULL CELL AFTER IT. The word had three paddings
// spent on it - one before the icon, one after it and one at the right edge -
// and on a strip a quarter of the reader wide that is about a letter's worth
// of room. Structured text wraps rather than clips, so SETTINGS came out as
// SETTING with a lone S on a second line under it. The gear sits on the
// cell's own margin now and the label starts half a padding after it, which
// buys the letter back.
private _iconH = _cellH * 0.62;
private _iconW = _iconH * pixelW / pixelH;
private _iconX = _cellX + _pad * 0.5;
[_body, [_iconX, _cellY + (_cellH - _iconH) * 0.5, _iconH], "\A3\ui_f\data\gui\rsc\rscdisplaymain\menu_options_ca.paa", _ink] call EFUNC(tacpad,drawIcon);

private _labelX = _iconX + _iconW + _pad * 0.5;
[
    _body, [_labelX, _cellY, _cellX + _cellW - _labelX - _pad * 0.5, _cellH],
    "SETTINGS", _ink, _labelSize, true
] call EFUNC(tacpad,drawText);

// THE WHOLE PANEL IS THE BUTTON. A one-cell strip has nothing else in it to
// press, and hunting for the live part of a bar the size of a bootlace is not
// an interaction - so the hit covers the body edge to edge, margins included.
// Sized to what EFUNC(tacpad,fit) is about to make the body, not to what it is
// now - the panel is still whatever height it was placed at on this line.
[_body, [_cellX, 0, _w - _cellX, _cellH + 3 * _padY], {["settings", [], true] call EFUNC(tacpad,openApp)}] call EFUNC(tacpad,drawHit);

[_id, 0, (_cellH + 3 * _padY) / HOST_H] call EFUNC(tacpad,fit);
