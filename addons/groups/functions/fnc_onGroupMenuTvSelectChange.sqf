#include "script_component.hpp"
/*
    Author: YMF (restyled to the jmfsb suite)

    Description:
        Writes the role card in the right pane of the role selection screen.

        THE MARKUP IS THE SUITE'S, NOT PURISTA'S. It was PuristaBold/PuristaLight
        at 1.6 with the loadout as eight hard-coded <br/> pairs, which is the
        vanilla team-switch look. It is the same card the tacpad and TAC//ADMIN
        draw: a subject line, a muted detail line, a tracked kicker over a block,
        and label-left value-right rows in two weights.

        COLOURS COME FROM THE THEME, not from hex literals - see
        jmfsb_groups_fnc_styleGroupMenu, which leaves the player's scheme in
        YMF_groupMenu_theme. A card that ignored the scheme would be the one
        white rectangle in a Night Olive screen.

    Parameters:
        0: CONTROL - the tree
        1: ARRAY   - selection path

    Returns:
        NOTHING
*/

params [
    ["_control",controlNull,[controlNull]],
    ["_selectionPath",[],[[]]]
];

private _display = findDisplay 9702;
private _textBox = _display displayCtrl 1100;
private _button = _display displayCtrl 2400;

(missionNamespace getVariable ["YMF_groupMenu_theme", [[0.05,0.05,0.05,1],[0.90,0.90,0.88,1],[0.85,0.28,0.20,1],[0.35,0.35,0.34,1]]]) params ["_ground","_ink","_accent"];

private _inkHex = _ink call BIS_fnc_colorRGBAtoHTML;
private _accentHex = _accent call BIS_fnc_colorRGBAtoHTML;
private _muteHex = [_ink#0, _ink#1, _ink#2, 0.62] call BIS_fnc_colorRGBAtoHTML;

// NOTHING SELECTED. The tree fires this with an empty path when its selection
// clears (a refresh of the list), and an undefined group index made the param
// below throw "Type Any, expected Number" (2026-10-17 RPT). No card, no button.
if (_selectionPath isEqualTo []) exitWith {
    _button ctrlEnable false;
    _textBox ctrlSetStructuredText parseText "";
};

_selectionPath params ["_groupIndex",["_unitIndex",-1]];

// A group heading rather than a role: the card names the group and says to pick
// something inside it. Nothing to take, so the button goes dead.
if (_unitIndex isEqualTo -1) exitWith {
    _button ctrlEnable false;

    // THE ROW MAY NOT BE THERE AT ALL. Until the ORBAT has been applied the
    // table is empty, and reading element 4 of a row that does not exist put
    // the word "scalar" on screen where the slot count belongs - "0 OF scalar
    // SLOTS FILLED" (seen in game 2026-09-09, while the database was still
    // being read). Say what is actually true instead.
    private _row = YMF_dynamicGroups param [_groupIndex, []];
    private _groupName = _row param [0, ""];
    private _slots = _row param [4, []];
    if !(_slots isEqualType []) then {_slots = []};
    private _filled = 0;
    {if (!isNull _x) then {_filled = _filled + 1}} forEach _slots;

    _textBox ctrlSetStructuredText parseText format ["
        <t font='RobotoCondensedBold' size='1.6' color='%1'>%2</t>
        <br/>
        <t font='RobotoCondensed' size='0.9' color='%3'>%4</t>
    ",
        _inkHex, toUpper _groupName,
        _muteHex,
        [
            format ["%1 OF %2 SLOTS FILLED  -  PICK A ROLE FROM THE LIST", _filled, count _slots],
            "NO SLOTS YET - the unit's order of battle is still being read from the database"
        ] select (_slots isEqualTo [])
    ];

    (ctrlPosition _textBox) params ["_x0","_y0","_w0"];
    _textBox ctrlSetPosition [_x0, _y0, _w0, ctrlTextHeight _textBox];
    _textBox ctrlCommit 0;
};

(parseSimpleArray (_control tvData _selectionPath)) params ["_unitNetID","_selectedRole"];
private _unit = objectFromNetId _unitNetID;

_button ctrlEnable (isNull _unit);

// THE ROLE, from wherever the unit keeps it - the database, the profile or
// the mission's Dynamic_Roles - see FUNC(role).
private _roleData = [_selectedRole] call FUNC(role);
private _roleName = _roleData getOrDefault ["name", _selectedRole];
private _roleDesc = _roleData getOrDefault ["description", ""];

private _defaultLoadout = _roleData getOrDefault ["defaultLoadout", []];
if !(_defaultLoadout isEqualType []) then {_defaultLoadout = []};
private _defaultLoadoutText = [];

for "_i" from 0 to 5 do {
    private _array = _defaultLoadout param [_i, []];
    if !(_array isEqualType []) then {_array = []};
    _array params [["_className",""]];
    if (_className isEqualTo "") then {
        _defaultLoadoutText pushBack "-";
    } else {
        if (_i isEqualTo 5) then {
            _defaultLoadoutText pushBack (getText(configFile >> "CfgVehicles" >> _className >> "displayName"));
        } else {
            _defaultLoadoutText pushBack (getText(configFile >> "CfgWeapons" >> _className >> "displayName"));
        };
    };
};

private _helmetClass = _defaultLoadout param [6, ""];
if !(_helmetClass isEqualType "") then {_helmetClass = ""};
if (_helmetClass isEqualTo "") then {
    _defaultLoadoutText pushBack "-";
} else {
    _defaultLoadoutText pushBack (getText(configFile >> "CfgWeapons" >> _helmetClass >> "displayName"));
};

// ONE ROW, BUILT ONCE. Eight copies of the same six-line format block was how
// the old card managed to have three different amounts of air between its rows.
private _rows = "";
{
    _x params ["_label","_value"];
    _rows = _rows + format ["
        <t font='RobotoCondensed' size='0.85' align='left' color='%1'>%2</t><t font='RobotoCondensedBold' size='0.85' align='right' color='%3'>%4</t>
        <br/>
    ",
        _muteHex, toUpper _label,
        ([_inkHex, _muteHex] select (_value isEqualTo "-")), _value
    ];
} forEach [
    [localize "STR_A3_RSCDISPLAYGEAR_FILTERS_PRIMARY0",      _defaultLoadoutText # 0],
    [localize "STR_A3_RSCDISPLAYARSENAL_TAB_SECONDARYWEAPON", _defaultLoadoutText # 1],
    [localize "STR_A3_RSCDISPLAYGEAR_FILTERS_SECONDARY0",     _defaultLoadoutText # 2],
    [localize "STR_A3_RSCDISPLAYARSENAL_TAB_UNIFORM",         _defaultLoadoutText # 3],
    [localize "STR_A3_RSCDISPLAYARSENAL_TAB_VEST",            _defaultLoadoutText # 4],
    [localize "STR_A3_RSCDISPLAYARSENAL_TAB_BACKPACK",        _defaultLoadoutText # 5],
    [localize "STR_A3_RSCDISPLAYARSENAL_TAB_HEADGEAR",        _defaultLoadoutText # 6]
];

// WHO HAS IT, said on the card rather than only as a greyed row in the tree.
// The tree dims a taken role; it does not say the name, and "who is our medic"
// is the question this screen is opened to answer half the time.
private _status = if (isNull _unit) then {
    format ["<t font='RobotoCondensedBold' size='0.9' color='%1'>OPEN</t>", _accentHex]
} else {
    format ["<t font='RobotoCondensed' size='0.9' color='%1'>TAKEN BY </t><t font='RobotoCondensedBold' size='0.9' color='%2'>%3</t>",
        _muteHex, _inkHex, name _unit]
};

_textBox ctrlSetStructuredText parseText format ["
    <t font='RobotoCondensedBold' size='1.6' color='%1'>%2</t>
    <br/>
    %3
    <br/><br/>
    <t font='RobotoCondensed' size='0.95' color='%4'>%5</t>
    <br/><br/><br/>
    <t font='RobotoCondensedBold' size='0.7' color='%6'>%7</t>
    <br/>
    %8
",
    _inkHex, toUpper _roleName,
    _status,
    _muteHex, _roleDesc,
    _muteHex, ("DEFAULT LOADOUT" splitString "") joinString " ",
    _rows
];

(ctrlPosition _textBox) params ["_xPos","_yPos","_width"];
_textBox ctrlSetPosition [_xPos,_yPos,_width,ctrlTextHeight _textBox];
_textBox ctrlCommit 0;
