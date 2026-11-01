#include "script_component.hpp"
/*
 * Author: JMSB
 * SQUAD: one line when the section is whole, and the casualty list the moment it
 * is not.
 *
 * QUIET UNTIL IT MATTERS. A permanent roster of eight names is eight lines of
 * screen spent telling you what you already know - and by being there always, it
 * stops being read. ALL OK is one line, and the list appearing IS the alert.
 *
 * IT ASKS ACE, NOT THE ENGINE. `damage` on a man under ACE medical is not what
 * anybody means by wounded; unconscious, bleeding and the pain state are, and
 * they are ACE's to answer. Without ACE it falls back to damage, which is the
 * honest reading of a mission not running it.
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
 * [_ops, _y, _w, _h] call jmfsb_hud_fnc_widgetSquad
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
private _rowH = _base min ((_h - _y - (PAD * safeZoneW)) / (((count units group player) + 2) max 4));
// Width caps the scale too - see the note in FUNC(widgetEw).
private _kw = (_w / (10 * (((safeZoneW / safeZoneH) min 1.2) / 40))) max 0.8;
private _k = ((_rowH / _base) min _kw) max 0.8;
private _pad = PAD * safeZoneW;
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];
private _amber = [0.85, 0.65, 0.15, 1];

private _aceMedical = !isNil "ace_medical_fnc_hasMedicalEnabled" || {!isNil "ACE_medical_fnc_setUnconscious"};

private _hurt = [];
{
    if (!alive _x) then {
        _hurt pushBack [_x, "KIA", 3];
        continue;
    };

    private _unconscious = _x getVariable ["ACE_isUnconscious", false];
    private _pain = _x getVariable ["ace_medical_pain", 0];
    private _bleeding = (_x getVariable ["ace_medical_bloodVolume", 6]) < 5.8;
    private _dmg = damage _x;

    switch (true) do {
        case (_unconscious): {_hurt pushBack [_x, "UNCONSCIOUS", 3]};
        case (_bleeding): {_hurt pushBack [_x, "BLEEDING", 2]};
        case (_pain > 0.35): {_hurt pushBack [_x, "IN PAIN", 1]};
        case (!_aceMedical && _dmg > 0.25): {_hurt pushBack [_x, format ["%1%2 HURT", round (_dmg * 100), "%"], 1]};
        default {};
    };
} forEach (units group player);

if (_hurt isEqualTo []) exitWith {
    _ops pushBack [HUD_OP_TEXT, [[_pad, _y, _w - 2 * _pad, _rowH], "ALL OK", _ink, (1 * _k), true]];
    _ops pushBack [HUD_OP_TEXT, [
        [_pad, _y + _rowH, _w - 2 * _pad, _rowH],
        format ["%1 EFFECTIVE", count (units group player)],
        _mute, (0.65 * _k), false, "left", true
    ]];
};

// WORST FIRST. A list ordered by who happens to be earliest in the group array
// buries the man who is dying under three men with grazes.
private _keyed = _hurt apply {[_x # 2, _x]};
_keyed sort false;

// How many rows are left in the box. It scrolls by DROPPING the least urgent
// rather than by growing past the frame the player positioned - a HUD that
// resizes itself is a HUD that ends up over the compass.
private _room = floor ((_h - _y - _pad) / _rowH);
private _shown = 0;

{
    (_x # 1) params ["_unit", "_state", "_rank"];
    if (_shown >= (_room - 1) && {count _keyed > _room}) exitWith {};

    private _colour = switch (_rank) do {
        case 3: {_accent};
        case 2: {_amber};
        default {_ink};
    };

    _ops pushBack [HUD_OP_TEXT, [[_pad, _y + _shown * _rowH, _w * 0.5, _rowH], [name _unit, format ["%1 (%2)", name _unit, ((_unit getVariable ["jmfsb_pac_skillTags", []]) select [0, 2]) joinString "/"]] select ((_unit getVariable ["jmfsb_pac_skillTags", []]) isNotEqualTo []), _colour, (0.8 * _k), true]];
    _ops pushBack [HUD_OP_TEXT, [[_w * 0.5, _y + _shown * _rowH, _w * 0.5 - _pad, _rowH], _state, _colour, (0.68 * _k), true, "right", true]];
    _shown = _shown + 1;
} forEach _keyed;

if (count _keyed > _shown) then {
    _ops pushBack [HUD_OP_TEXT, [
        [_pad, _y + _shown * _rowH, _w - 2 * _pad, _rowH],
        format ["+%1 MORE", count _keyed - _shown],
        _mute, (0.65 * _k), true, "left", true
    ]];
};
