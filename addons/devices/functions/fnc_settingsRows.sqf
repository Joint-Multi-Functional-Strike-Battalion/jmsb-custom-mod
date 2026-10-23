#include "script_component.hpp"
/*
 * Author: JMSB
 * The rows of the tablet's SETTINGS > DEVICES and SETTINGS > DEVICE KEYS
 * sections - everything about the phone and side devices a player changes,
 * since they carry no ACE menu of their own (user, 2026-10-20). Registered
 * with jmfsb_tacpad_apps' settings app in XEH_preInit and drawn by it
 * (jmfsb_tacpad_apps_fnc_appSettings), so the ranges, the soft-key list and
 * the button list stay this addon's.
 *
 * CBA settings are changed through jmfsb_tacpad_apps_fnc_setSetting /
 * settingStep / settingCycle, which go through CBA's own setter so a change
 * persists as Addon Options keeps it; a setting the server or mission forces
 * is drawn read-only (jmfsb_tacpad_apps_fnc_settingLocked). The walking view's
 * shown state and edge are not CBA settings - they are the player's profile
 * (FUNC(overlaySetShown), FUNC(overlaySetEdge)).
 *
 * Arguments:
 * 0: Section - "devices" or "devkeys" <STRING>
 *
 * Return Value:
 * Rows, each [label, value, action, down action, locked, [down glyph, up glyph]];
 * an action of {} is a line to read, not a control <ARRAY>
 *
 * Example:
 * ["devices"] call jmfsb_devices_fnc_settingsRows
 *
 * Public: No
 */

params [["_section", "devices", [""]]];

// The settings page is rebuilt to show a change that is not a CBA setting -
// next frame, because the press that made it is still running on a control
// the rebuild deletes.
private _reopen = {[{["settings"] call EFUNC(tacpad,openApp)}] call CBA_fnc_execNextFrame};

// A slider as a minus / plus pair, clamped to its range.
private _fnc_slider = {
    params ["_label", "_setting", "_min", "_max", "_step", "_decimals", "_percent"];
    private _now = missionNamespace getVariable [_setting, _min];
    private _code = {
        params ["_delta"];
        compile format ["[%1, %2, %3, %4, %5] call %6", str _setting, _delta, _min, _max, _decimals, QEFUNC(tacpad_apps,settingStep)]
    };
    [
        _label,
        [_now toFixed _decimals, format ["%1%2", round (_now * PERCENT), "%"]] select _percent,
        [_step] call _code,
        [-_step] call _code,
        [_setting] call EFUNC(tacpad_apps,settingLocked)
    ]
};

// A list as previous / next, wrapping, showing the choice's name without its
// bracketed note.
private _fnc_list = {
    params ["_label", "_setting", "_ids", "_names"];
    private _now = missionNamespace getVariable [_setting, ""];
    private _name = _names param [(_ids find _now) max 0, ""];
    private _code = {
        params ["_dir"];
        compile format ["[%1, %2, %3] call %4", str _setting, str _ids, _dir, QEFUNC(tacpad_apps,settingCycle)]
    };
    [
        _label,
        toUpper trim ((_name splitString "(") param [0, ""]),
        [1] call _code,
        [-1] call _code,
        [_setting] call EFUNC(tacpad_apps,settingLocked),
        ["<", ">"]
    ]
};

// A keybind as the player has it bound (CBA_fnc_getKeybind), so a rebound key
// reads rebound: modifiers, then the key's own name; UNBOUND for none.
private _fnc_bound = {
    params ["_action"];
    private _bind = [JMFSB_CATEGORY, _action] call CBA_fnc_getKeybind;
    if (isNil "_bind") exitWith {"--"};
    (_bind param [5, [0, []]]) params [["_dik", 0, [0]], ["_mods", [], [[]]]];
    if (_dik <= 1) exitWith {"UNBOUND"};
    private _words = [];
    {
        if (_mods param [_forEachIndex, false]) then {_words pushBack _x};
    } forEach ["SHIFT", "CTRL", "ALT"];
    _words pushBack toUpper (((keyName _dik) splitString """") joinString "");
    _words joinString "+"
};

// THE NUMPAD IS THE DEVICE'S KEY BLOCK (docs/SPEC_TACNET.json D16): each
// frame key is a keybind, the tablet's and the walking view's alike, and what
// it is bound to is shown beside it. The tablet's F1-F4 open an app; the
// walking view's do what their setting says - the voice keys by default.
if (_section isEqualTo "devkeys") exitWith {
    private _rows = [];
    {
        _x params ["_setting", "_key"];
        _rows pushBack ([format ["TABLET %1 (%2)", _key, [format ["%1_%2", QGVAR(button), _key]] call _fnc_bound], _setting, SOFT_KEY_IDS, SOFT_KEY_NAMES] call _fnc_list);
    } forEach [
        [QGVAR(keyF1), "F1"],
        [QGVAR(keyF2), "F2"],
        [QGVAR(keyF3), "F3"],
        [QGVAR(keyF4), "F4"]
    ];
    {
        private _label = BUTTON_LABELS select _forEachIndex;
        _rows pushBack ([format ["WALKING %1 (%2)", toUpper _label, [format ["%1_%2", QGVAR(button), _label]] call _fnc_bound], _x, BUTTON_IDS, BUTTON_NAMES] call _fnc_list);
    } forEach [QGVAR(buttonF1), QGVAR(buttonF2), QGVAR(buttonF3), QGVAR(buttonF4), QGVAR(buttonLeft), QGVAR(buttonRight)];
    _rows pushBack ["TABLET ARROWS", "ACTIVE NET LEFT / RIGHT", {}];
    // SELECT NET N: the number on each net chip is its key.
    for "_i" from 1 to NET_SELECT_KEYS do {
        _rows pushBack [format ["SELECT NET %1", _i], [format ["%1_%2", QGVAR(netSelect), _i]] call _fnc_bound, {}];
    };
    {
        _x params ["_label", "_actions"];
        _rows pushBack [_label, (_actions apply {[_x] call _fnc_bound}) joinString " / ", {}];
    } forEach [
        ["OPEN / CLOSE TABLET", [QGVAR(tabletKey)]],
        ["RADIO APP ON THE DEVICE", [QGVAR(radioAppKey)]],
        ["RADIO TABS", [QGVAR(tabPrev), QGVAR(tabNext)]],
        ["TROOPS IN CONTACT", [QEGVAR(tacpad_apps,ticKey)]]
    ];
    _rows pushBack ["KEYS ARE REBOUND IN", "CONFIGURE ADDONS", {}];
    _rows
};

private _worn = (createHashMapFromArray WALK_DEVICE_NAMES) getOrDefault [[] call FUNC(overlayDevice), WALK_DEVICE_NONE];
private _rings = missionNamespace getVariable [QEGVAR(bft,memberVoiceRings), false];

[
    ["DEVICE IN GPS SLOT", _worn, {}],
    ["WALKING VIEW", ["HIDDEN", "SHOWN"] select GVAR(overlayShown), compile format [
        "[] call %1; call %2", QFUNC(overlayToggle), _reopen
    ]],
    ["SIDE DEVICE EDGE", toUpper GVAR(overlayEdge), compile format [
        "[%1 select (%2 isEqualTo (%1 select 0))] call %3; call %4", str EDGES, QGVAR(overlayEdge), QFUNC(overlaySetEdge), _reopen
    ]],
    ["PHONE SIZE", QGVAR(phoneFill), PHONE_FILL_MIN, PHONE_FILL_MAX, FILL_STEP, FILL_DECIMALS, true] call _fnc_slider,
    ["SIDE DEVICE SIZE", QGVAR(sideFill), SIDE_FILL_MIN, SIDE_FILL_MAX, FILL_STEP, FILL_DECIMALS, true] call _fnc_slider,
    ["MAP ZOOM - SMALLER IS CLOSER", QGVAR(phoneZoom), ZOOM_MIN, ZOOM_MAX, ZOOM_STEP, ZOOM_DECIMALS, false] call _fnc_slider,
    ["TABLET FRAME", QGVAR(tabletFrame), TABLET_FRAME_IDS, TABLET_FRAME_NAMES] call _fnc_list,
    ["GRID READOUT", QGVAR(gridDigits), GRID_DIGIT_CHOICES, GRID_DIGIT_NAMES] call _fnc_list,
    ["DEVICE OPACITY", QGVAR(overlayOpacity), OPACITY_MIN, OPACITY_MAX, OPACITY_STEP, FILL_DECIMALS, true] call _fnc_slider,
    [
        "MEMBER VOICE RINGS", ["OFF", "ON"] select _rings,
        compile format ["[%1, !%2] call %3", str QEGVAR(bft,memberVoiceRings), QEGVAR(bft,memberVoiceRings), QEFUNC(tacpad_apps,setSetting)],
        {},
        [QEGVAR(bft,memberVoiceRings)] call EFUNC(tacpad_apps,settingLocked)
    ],
    ["SHOW / HIDE KEY", [QGVAR(overlayKey)] call _fnc_bound, {}]
]
