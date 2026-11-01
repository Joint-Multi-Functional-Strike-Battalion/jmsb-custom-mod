#include "script_component.hpp"
/*
 * Author: JMSB
 * JAMMING: which of the three services is down, and how hard.
 *
 * ONE ROW PER DOMAIN - RADIO, DATA, GPS (user, 2026-08-31). This was one big
 * percentage and one bar, which stopped meaning anything the moment a terminal
 * could take the voice net without touching TAC//MSG: the player read 60% and
 * could not tell what they had lost. All three are always drawn, so "what still
 * works" is one glance rather than three experiments.
 *
 * The numbers come off FUNC(sweep) - one read for the whole HUD - at the
 * indices EFUNC(hacking,scannerRead) appends them to, so this cannot disagree
 * with the tacpad JAM app or with what the radios are actually doing.
 *
 * Arguments:
 * 0: Draw ops, appended to - see FUNC(paint) <ARRAY>
 * 1: Y to start at <NUMBER>
 * 2: Slot width <NUMBER>
 * 3: Slot height <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_ops, _y, _w, _h] call jmfsb_hud_fnc_widgetJamming
 *
 * Public: No
 */

params [["_ops", [], [[]]], ["_y", 0, [0]], ["_w", 0, [0]], ["_h", 0, [0]]];

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent", "_line"];

private _base = ROW_H * EGVAR(tacpad,textScale) * EGVAR(tacpad,uiScale) * safeZoneH;
// A ROW IS THE SUITE'S OWN ROW, AND IT ONLY EVER SHRINKS. Rows used to be the
// slot's whole box divided by however many of them there were, so a slot at its
// default size - the vanilla Custom Info panel's size - spread three lines down
// the whole panel with holes between them, at type twice the size the rest of
// the suite sets. The design's row height is the row height here too: a slot the
// player has made too SHORT for its rows squeezes them, and one made taller
// simply has air under the readout.
private _rowH = _base min ((_h - _y - (PAD * safeZoneW)) / 4);
// Width caps the scale too - see the note in FUNC(widgetEw).
private _kw = (_w / (10 * (((safeZoneW / safeZoneH) min 1.2) / 40))) max 0.8;
private _k = ((_rowH / _base) min _kw) max 0.8;
private _pad = PAD * safeZoneW;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];
private _amber = [0.85, 0.65, 0.15, 1];

private _sweep = [] call FUNC(sweep);
if (_sweep isEqualTo []) exitWith {
    _ops pushBack [HUD_OP_TEXT, [[_pad, _y, _w - 2 * _pad, _rowH], "NO SET", _dim, (0.9 * _k), true]];
};

_sweep params ["", "", "", ["_jam", 0], "", "", "", "",
    ["_jamRadio", 0], ["_jamData", 0], ["_jamGps", 0]];

// Older scannerRead builds had no per-domain figures. Rather than draw three
// empty rows, fall back to the aggregate on the RADIO row - it is what the
// single bar always meant.
if (_jamRadio + _jamData + _jamGps <= 0 && _jam > 0) then { _jamRadio = _jam };

private _rows = [["RADIO", _jamRadio], ["DATA", _jamData], ["GPS", _jamGps]];

{
    _x params ["_name", "_f"];

    private _pct = round (_f * 100);
    private _state = switch (true) do {
        case (_pct >= 75): {2};
        case (_pct > 0): {1};
        default {0};
    };
    private _colour = [_mute, _amber, _accent] select _state;

    private _top = _y + _rowH * _forEachIndex;

    // Name and figure on the left in a fixed column, so the three bars line up
    // under each other and the block reads as one instrument.
    _ops pushBack [HUD_OP_TEXT, [
        [_pad, _top, _w * 0.46, _rowH],
        format ["%1 %2%3", _name, _pct, "%"],
        _colour, (0.78 * _k), true, "left", true
    ]];

    // A BAR, because a percentage is a number and a bar is a glance. The one
    // thing this readout is for is knowing whether to bother transmitting.
    private _barX = _pad + _w * 0.5;
    private _barW = (_w - _barX - _pad) max 0;
    private _barY = _top + _rowH * 0.34;
    private _barH = _rowH * 0.32;
    _ops pushBack [HUD_OP_FILL, [[_barX, _barY, _barW, _barH], _line]];
    if (_pct > 0) then {
        _ops pushBack [HUD_OP_FILL, [[_barX, _barY, _barW * (_pct / 100), _barH], _colour]];
    };
} forEach _rows;
