#include "script_component.hpp"
/*
    Author: YonV

    Description:
        Switches the role screen to one platoon tab: repaints the row so the
        pressed tab is the lit one, and refills the tree behind it.

        THE SELECTED TAB'S LABEL IS THE ACCENT (user, 2026-09-01), the rest are
        the same words at a muted ink. Every tab keeps the lift the rail is drawn
        on, so the row reads as one strip of chips with a single lit name in it -
        the accent as ink rather than as a block of fill, which is quieter beside
        the tree below and still the only thing on that row worth reading.

        THIS FUNCTION WRITES THE TEXT, NOT JUST THE COLOUR. A tab is structured
        text now (two lines - see script_component.hpp) and structured text
        carries its colour inside its own markup, so there is nothing for a
        ctrlSetTextColor to change. fn_initGroupMenu therefore sets no labels of
        its own and ends by calling this, which is the only place the row is
        drawn - one function, so a tab painted by a click is painted exactly the
        way the opening draw painted it.

    Parameters:
        0: NUMBER - which tab, zero-based

    Returns:
        NOTHING
*/

disableSerialization;

params [["_index", 0, [0]]];

private _display = findDisplay 9702;
if (isNull _display) exitWith {};

private _tabs = missionNamespace getVariable [QGVAR(platoonTabs), []];
if (_tabs isEqualTo []) exitWith {};
if (_index < 0 || {_index >= count _tabs}) exitWith {};

GVAR(platoon) = _index;

(missionNamespace getVariable ["YMF_groupMenu_theme", [[0.05,0.05,0.05,1],[0.90,0.90,0.88,1],[0.85,0.28,0.20,1],[0.35,0.35,0.34,1]]]) params ["_ground","_ink","_accent"];

// The chip's ground, and the same chip under the pointer. Kept where
// FUNC(hoverTab) can find them - it fires on a mouse handler and has no theme
// of its own to mix, and mixing one per pointer move would be work for nothing.
private _fnc_mix = {
    params ["_a", "_b", "_t"];
    [
        ((_a # 0) * (1 - _t)) + ((_b # 0) * _t),
        ((_a # 1) * (1 - _t)) + ((_b # 1) * _t),
        ((_a # 2) * (1 - _t)) + ((_b # 2) * _t),
        _a # 3
    ]
};

GVAR(tabLift) = [_ground, _ink, 0.18] call _fnc_mix;
GVAR(tabHover) = [_ground, _ink, 0.30] call _fnc_mix;

private _accentHex = _accent call BIS_fnc_colorRGBAtoHTML;
private _typeHex = ([_ink # 0, _ink # 1, _ink # 2, 0.40]) call BIS_fnc_colorRGBAtoHTML;
private _nameHex = ([_ink # 0, _ink # 1, _ink # 2, 0.62]) call BIS_fnc_colorRGBAtoHTML;
private _typeOnHex = ([_accent # 0, _accent # 1, _accent # 2, 0.70]) call BIS_fnc_colorRGBAtoHTML;

// The row is MAX_PLT_TABS controls whatever the mission declared - see gui.hpp.
// The ones past the last tab were hidden when the screen opened and stay hidden.
for "_i" from 0 to (MAX_PLT_TABS - 1) do {
    private _ctrl = _display displayCtrl (IDC_PLT_TAB + _i);
    if (isNull _ctrl) then {continue};
    if (_i >= count _tabs) then {continue};

    (_tabs select _i) params ["_label", "_squads", ["_callsign", ""]];

    private _on = _i isEqualTo _index;

    // ONE LINE WHEN THERE IS ONLY ONE. A mission that declares no callsign gets
    // the row it had before there were two lines in it, centred on its own.
    private _text = if (_callsign isEqualTo "") then {
        format [
            "<t align='center' size='0.68' font='RobotoCondensedBold' color='%1'>%2</t>",
            ([_nameHex, _accentHex] select _on), _label
        ]
    } else {
        format [
            "<t align='center' size='0.54' font='RobotoCondensed' color='%1'>%3</t><br/><t align='center' size='0.80' font='RobotoCondensedBold' color='%2'>%4</t>",
            ([_typeHex, _typeOnHex] select _on),
            ([_nameHex, _accentHex] select _on),
            _label,
            _callsign
        ]
    };

    _ctrl ctrlSetStructuredText parseText _text;
    _ctrl ctrlSetBackgroundColor GVAR(tabLift);
};

private _tree = _display displayCtrl 1500;
[_tree, (_tabs select _index) select 1] call FUNC(fillRoleTree);

// The card beside the tree belongs to whatever row is now selected; without
// this it keeps describing a role on the tab you just left. Passed its two
// arguments rather than called bare - it is a tree handler and reads them.
[_tree, tvCurSel _tree] call FUNC(onGroupMenuTvSelectChange);
