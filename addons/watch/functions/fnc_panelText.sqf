#include "script_component.hpp"
/*
 * Author: YonV
 * The watch panel's text, the same on every surface it is drawn on - the
 * walking view of the side device or phone (FUNC(screen)) and the tablets'
 * panel (FUNC(panel)), the vehicle tablet's included:
 *
 *     header     profile name, slots used / max, the context prompt
 *                ("9: ADD TO MEDICAL" while the player looks at a valid
 *                target, prompt mode full)
 *     each slot  a cell: 1  name / state / two values; * marks a pinned
 *                slot - or the squad view while F4 has it up (FUNC(squadView))
 *     key hints  F1 REPORT  F2 SHARE  F3 ALL OFF  F4 SQUAD  F5 F6 SELECT -
 *                the keys as bound, a key with nothing to do dimmed;
 *                reduced mode icons only
 *
 * The parts come back too, so the device can set the slots side by side
 * (user, 2026-11-08: "3 across", FUNC(screen)); the tablets' panel draws the
 * whole text in one column.
 *
 * Arguments:
 * 0: Profile id <STRING>
 *
 * Return Value:
 * [whole text, its lines, header text, header lines, slot cells (texts),
 * lines per cell, hints text, squad view up, the profile's slots (tiles),
 * the picked slot (FUNC(selected))] <ARRAY>
 *
 * Example:
 * ["medical"] call jmfsb_watch_fnc_panelText
 *
 * Public: No
 */

params [["_id", "", [""]]];

private _spec = GVAR(profiles) get _id;
private _slots = GVAR(slots) get _id;
private _hex = {_this call BIS_fnc_colorRGBAtoHTML};
private _full = GVAR(prompt) isEqualTo "full";

// header (the profile's icon, name, slots used) and the context prompt
private _icon = _spec getOrDefault ["icon", ""];
private _head = format ["<t color='%1'>%2%3  %4 / %5</t>", COLOUR_INK call _hex,
    ["", format ["<img image='%1'/> ", _icon]] select (_icon isNotEqualTo ""),
    toUpper (_spec getOrDefault ["name", _id]), count _slots, _spec getOrDefault ["slots", SLOTS_PER_PROFILE]];
private _look = [] call FUNC(lookTarget);
if (_full && {!isNull _look}) then {
    private _watched = (_slots findIf {(_x # 0) isEqualTo _look}) >= 0;
    private _for = [[_look] call FUNC(profileFor), _id] select _watched;
    if (_for isNotEqualTo "") then {
        // the action key as bound - F9, or numpad 9 in the numpad layout
        private _key = if (isNil QEFUNC(devices,keyLabel)) then {"9"} else {[QGVAR(action)] call EFUNC(devices,keyLabel)};
        _head = _head + format ["   <t color='%1'>%2: %3 %4</t>", COLOUR_AMBER call _hex, _key, ["ADD TO", "REMOVE FROM"] select _watched,
            toUpper ((GVAR(profiles) get _for) getOrDefault ["name", _for])];
    };
};
// a profile's own line under the header (engineer: his own charges)
private _extra = [] call (_spec getOrDefault ["header", {""}]);
if (_extra isNotEqualTo "") then {_head = _head + format ["<br/><t color='%1'>%2</t>", COLOUR_AMBER call _hex, _extra]};
private _headLines = 1 + parseNumber (_extra isNotEqualTo "");

// the slots, one cell each: number and name, state, the values - or the
// squad view while F4 has it up (FUNC(squadView)), one wide cell
private _squad = ["text"] call FUNC(squadView);
private _wide = _squad isNotEqualTo "";
private _row = _spec getOrDefault ["row", {[]}];
private _cells = [];
private _cellLines = 0;
if (_wide) then {
    _cells pushBack _squad;
    _cellLines = 1 + count units group player;
} else {
    _cellLines = 1 + PANEL_LINES;
    {
        _x params ["_target", "_pinned"];
        ([_target] call _row) params [["_name", ""], ["_word", ""], ["_colour", COLOUR_INK], ["_values", []], ["_live", true]];
        private _cell = format ["<t color='%1'>%2%3  %4</t><br/><t color='%1'>%5</t>", _colour call _hex, _forEachIndex + 1, ["", "*"] select _pinned, _name, _word];
        {
            _cell = _cell + format ["<br/><t color='%1'>%2</t>", ([COLOUR_GREY, COLOUR_INK] select _live) call _hex, _x];
        } forEach (_values select [0, PANEL_LINES - 1]);
        _cells pushBack _cell;
    } forEach _slots;
};

// key hints
private _hints = [];
{
    private _can = switch (_forEachIndex) do {
        case KEY_REPORT: {(_spec getOrDefault ["report", {}]) isNotEqualTo {} && {_slots isNotEqualTo []}};
        case KEY_SHARE: {(_spec getOrDefault ["share", {}]) isNotEqualTo {} && {_slots isNotEqualTo []}};
        case KEY_SQUAD: {
            (values GVAR(profiles)) findIf {(_x getOrDefault ["squad", {}]) isNotEqualTo {} && {[player] call (_x getOrDefault ["gate", {false}])}} >= 0
        };
        default {true};
    };
    // the key as the player has it bound - the hint follows a rebind
    private _key = if (isNil QEFUNC(devices,keyLabel)) then {str (_forEachIndex + 1)} else {
        [format ["%1_F%2", QEGVAR(devices,button), _forEachIndex + 1]] call EFUNC(devices,keyLabel)
    };
    // KEY HINT ICONS (design keys.key_hints): the report key's icon is the
    // profile's (med kit, binoculars...); full mode adds the key and the word,
    // reduced mode is the icon alone
    private _img = [HINT_ICONS # _forEachIndex, [_icon, HINT_ICONS # 0] select (_icon isEqualTo "")] select (_forEachIndex isEqualTo KEY_REPORT);
    _hints pushBack format ["<t color='%1'><img image='%2'/>%3</t>", ([COLOUR_GREY, COLOUR_INK] select _can) call _hex, _img,
        ["", format [" %1 %2", _key, _x]] select _full];
} forEach KEY_HINT_WORDS;
// the arrows pick the slot the keys act on - full mode, two slots or more
if (_full && {count _slots > 1}) then {
    private _arrows = if (isNil QEFUNC(devices,keyLabel)) then {"< >"} else {
        format ["%1 %2", [QEGVAR(devices,button_left)] call EFUNC(devices,keyLabel), [QEGVAR(devices,button_right)] call EFUNC(devices,keyLabel)]
    };
    _hints pushBack format ["<t color='%1'>%2 %3</t>", COLOUR_INK call _hex, _arrows, KEY_SELECT_WORD];
};
private _hintText = _hints joinString "   ";

// the whole text, one column (the tablets' panel)
private _text = _head;
{_text = _text + "<br/>" + _x} forEach _cells;
_text = _text + "<br/>" + _hintText;

[_text, _headLines + 1 + count _cells * _cellLines, _head, _headLines, _cells, _cellLines, _hintText, _wide,
    _spec getOrDefault ["slots", SLOTS_PER_PROFILE], [_id] call FUNC(selected)]
