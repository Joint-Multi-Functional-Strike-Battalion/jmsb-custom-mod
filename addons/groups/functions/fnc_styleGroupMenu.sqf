#include "script_component.hpp"
/*
    Author: YonV

    Description:
        Paints and sizes the role selection screen from the player's jmfsb
        tacpad settings.

        WHY A FUNCTION AND NOT CONFIG. The colours in dialogs\groupMenu.hpp are
        the dark scheme, written once so the display never flashes a wrong
        colour on the way up. Everything a player can actually change - which of
        the seven schemes, how solid the ground is, how big the whole thing
        should be - lives in jmfsb's CBA settings, and a config file cannot read
        those. So the display opens, and the first thing it does is repaint
        itself in whatever the player picked.

        THE SCALE IS APPLIED ABOUT THE CENTRE OF THE SCREEN. Shrunk from the
        top-left corner the screen drifts toward it; shrunk about the middle it
        stays the same screen, smaller, with a margin round it.

        JMFSB MAY NOT BE LOADED. It is a mission, not an addon - so every read
        has a default and the screen still looks like itself on a bare install.

    Parameters:
        0: DISPLAY - the role menu, as its onLoad hands it over

    Returns:
        NOTHING
*/

disableSerialization;

// THE DISPLAY IS PASSED IN, not looked up. findDisplay does not necessarily
// resolve a dialog during its own onLoad, and a style pass that silently exits
// on the one call that matters is worse than no style pass.
params [["_display", displayNull, [displayNull]]];
if (isNull _display) then {_display = findDisplay 9702};
if (isNull _display) exitWith {};

// THE ONE SOURCE OF COLOUR IN THE SUITE. jmfsb_tacpad_fnc_theme returns the
// player's scheme as [ground, ink, accent, divider]; without jmfsb loaded these
// are the dark scheme it would have returned anyway.
private _theme = if (isNil "jmfsb_tacpad_fnc_theme") then {
    [[0.05, 0.05, 0.05, 1], [0.90, 0.90, 0.88, 1], [0.85, 0.28, 0.20, 1], [0.35, 0.35, 0.34, 1]]
} else {
    [] call jmfsb_tacpad_fnc_theme
};
_theme params ["_ground", "_ink", "_accent", "_line"];

// This screen covers the world completely, so a translucent one has a firefight
// showing through the loadout list. The tacpad's own opacity, given a floor.
private _opacity = ((missionNamespace getVariable ["jmfsb_tacpad_opacity", 0.92]) max 0.88) min 1;
private _scale = missionNamespace getVariable ["jmfsb_tacpad_uiScale", 1];

private _base = [_ground # 0, _ground # 1, _ground # 2, _opacity];
private _lift = [
    ((_ground # 0) * 0.82) + ((_ink # 0) * 0.18),
    ((_ground # 1) * 0.82) + ((_ink # 1) * 0.18),
    ((_ground # 2) * 0.82) + ((_ink # 2) * 0.18),
    _opacity
];
private _mute = [_ink # 0, _ink # 1, _ink # 2, 0.62];

private _inkHex = _ink call BIS_fnc_colorRGBAtoHTML;
private _muteHex = _mute call BIS_fnc_colorRGBAtoHTML;

// The theme, kept where the two functions that draw into this screen can find
// it - fn_initGroupMenu colours the tree rows and
// fn_onGroupMenuTvSelectChange writes the card.
YMF_groupMenu_theme = _theme;

// ------------------------------------------------------------------ paint --
(_display displayCtrl 9710) ctrlSetBackgroundColor _base;
(_display displayCtrl 9713) ctrlSetBackgroundColor _ink;
(_display displayCtrl 9716) ctrlSetBackgroundColor _line;

{
    private _ctrl = _display displayCtrl _x;
    if (isNull _ctrl) then {continue};
    _ctrl ctrlSetBackgroundColor _lift;
    _ctrl ctrlSetTextColor _ink;
} forEach [1500];

{
    private _ctrl = _display displayCtrl _x;
    if (isNull _ctrl) then {continue};
    _ctrl ctrlSetTextColor _ink;
    _ctrl ctrlSetActiveColor _accent;
} forEach [2];

{
    private _ctrl = _display displayCtrl _x;
    if (isNull _ctrl) then {continue};
    _ctrl ctrlSetBackgroundColor _accent;
    _ctrl ctrlSetTextColor _ground;
} forEach [2400];

(_display displayCtrl 1000) ctrlSetTextColor _mute;

// The wordmark. Written here rather than in config because a double slash in a
// config string is a preprocessor gamble; in SQF it is safe.
(_display displayCtrl 9711) ctrlSetStructuredText parseText format [
    "<t font='RobotoCondensedBold' size='1.5' color='%1'>TAC//ROLES</t>", _inkHex
];

// THE NUMBER A PLAYER OPENED THIS SCREEN TO FIND OUT. How many slots are still
// free, counted off the same YMF_dynamicGroups the tree is built from - a
// player staring at forty collapsed groups should not have to open all of them
// to learn there is nothing left.
private _open = 0;
private _total = 0;
{
    {
        _total = _total + 1;
        if (isNull _x) then {_open = _open + 1};
    } forEach (_x param [4, []]);
} forEach (missionNamespace getVariable ["YMF_dynamicGroups", []]);

(_display displayCtrl 9712) ctrlSetStructuredText parseText format [
    "<t font='RobotoCondensedBold' size='0.85' align='right' color='%1'>%2 OPEN</t><t font='RobotoCondensed' size='0.85' align='right' color='%3'>  OF %4</t>",
    ([_inkHex, _accent call BIS_fnc_colorRGBAtoHTML] select (_open isEqualTo 0)),
    _open, _muteHex, _total
];

// The two kickers. Tracked and muted - the design's micro-label, which is a
// space between every letter because Arma's structured text has no letter
// spacing at all.
{
    _x params ["_idc", "_text"];
    (_display displayCtrl _idc) ctrlSetStructuredText parseText format [
        "<t font='RobotoCondensedBold' size='0.7' color='%1'>%2</t>",
        _muteHex,
        (toUpper _text splitString "") joinString " "
    ];
} forEach [
    [9714, "GROUPS AND ROLES"],
    [9715, "ROLE"]
];

(_display displayCtrl 9717) ctrlSetStructuredText parseText format [
    "<t font='RobotoCondensed' size='0.75' align='center' color='%1'>Double-click a role to take it. A greyed role is already filled.</t>",
    _muteHex
];

// ------------------------------------------------------------------ scale --
if (_scale isEqualTo 1) exitWith {};

private _cx = safeZoneX + safeZoneW / 2;
private _cy = safeZoneY + safeZoneH / 2;
private _fontBase = 0.8 * (0.025 * safeZoneH);

{
    private _idc = ctrlIDC _x;

    // The ground is the screen and stays the screen; scaling it would leave a
    // hole round the edges with the world showing through.
    if (_idc isEqualTo 9710) then {continue};

    // THE CARD IS A CHILD OF A CONTROLS GROUP, so its coordinates are relative
    // to that group and the screen-centre transform is meaningless for it. Its
    // own handler re-lays it out on every selection anyway - see
    // fn_onGroupMenuTvSelectChange - so only its type size is set here.
    if (_idc isEqualTo 1100) then {
        _x ctrlSetFontHeight (_fontBase * _scale);
        _x ctrlCommit 0;
        continue;
    };

    (ctrlPosition _x) params ["_x0", "_y0", "_w0", "_h0"];
    _x ctrlSetPosition [
        _cx + (_x0 - _cx) * _scale,
        _cy + (_y0 - _cy) * _scale,
        _w0 * _scale,
        _h0 * _scale
    ];
    _x ctrlSetFontHeight (_fontBase * _scale);
    _x ctrlCommit 0;
} forEach (allControls _display);

// The card's width follows its group, which has just moved.
private _card = (_display displayCtrl 1205) controlsGroupCtrl 1100;
if (!isNull _card) then {
    private _groupW = (ctrlPosition (_display displayCtrl 1205)) # 2;
    (ctrlPosition _card) params ["", "", "", "_cardH"];
    _card ctrlSetPosition [0, 0, _groupW - 0.02 * safeZoneW, _cardH];
    _card ctrlCommit 0;
};
