#include "script_component.hpp"
/*
 * Author: YonV
 * DRONES: what is in the air, and where.
 *
 * ITS OWN TILE because it is the one readout on the HUD that means MOVE. Sharing
 * a box with the jamming percentage meant the contact bearing was a line in a
 * list; on its own it is the whole box, at a size that can be read without
 * stopping.
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
 * [_ops, _y, _w, _h] call jmfsb_hud_fnc_widgetDrones
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
private _rowH = _base min ((_h - _y - (PAD * safeZoneW)) / 3.6);
// Width caps the scale too - see the note in FUNC(widgetEw).
private _kw = (_w / (10 * (((safeZoneW / safeZoneH) min 1.2) / 40))) max 0.8;
private _k = ((_rowH / _base) min _kw) max 0.8;
private _pad = PAD * safeZoneW;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _dim = [_ink # 0, _ink # 1, _ink # 2, 0.42];

private _sweep = [] call FUNC(sweep);
if (_sweep isEqualTo []) exitWith {
    _ops pushBack [HUD_OP_TEXT, [[_pad, _y, _w - 2 * _pad, _rowH], "NO SET", _dim, (0.9 * _k), true]];
};

_sweep params [["_droneState", 0], ["_nearest", 0], ["_droneDir", 0]];
private _count = [0, _droneState] select (_droneState isEqualType 0);

_ops pushBack [HUD_OP_TEXT, [
    [_pad, _y, _w - 2 * _pad, _rowH * 1.5],
    ["CLEAR", str _count] select (_count > 0),
    ([_ink, _accent] select (_count > 0)), (1.8 * _k), true
]];

// NO CONTACTS, not "SPECTRUM CLEAR" - the spectrum is the jamming tile's word,
// and this tile counts aircraft. The sub-line names what the big CLEAR is
// clear OF, in the vocabulary of the thing being counted.
if (_count isEqualTo 0) exitWith {
    _ops pushBack [HUD_OP_TEXT, [[_pad, _y + _rowH * 1.6, _w - 2 * _pad, _rowH], "NO CONTACTS", _mute, (0.65 * _k), false, "left", true]];
};

_ops pushBack [HUD_OP_TEXT, [
    [_pad, _y + _rowH * 1.6, _w - 2 * _pad, _rowH],
    format ["BRG %1", round _droneDir], _accent, (0.95 * _k), true
]];

_ops pushBack [HUD_OP_TEXT, [
    [_pad, _y + _rowH * 2.5, _w - 2 * _pad, _rowH],
    format ["%1 KM", (round (_nearest / 100)) / 10], _ink, (0.85 * _k), true
]];
