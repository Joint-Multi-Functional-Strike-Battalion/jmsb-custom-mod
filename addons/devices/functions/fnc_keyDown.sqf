#include "script_component.hpp"
/*
 * Author: JMSB
 * The keyboard while the tablet is up: the numpad block of docs/SPEC_TACNET.json
 * D16 (user, 2026-10-20: "we are not using keyboard F1-F4, we are using
 * numpad"), passed through to the device.
 *
 * CBA'S KEYS DO NOT REACH THE MISSION DISPLAY UNDER A DIALOG, so every JMSB key
 * that means something on the tablet is matched here against the player's own
 * binding (CBA_fnc_getKeybind - a rebound key works rebound):
 *
 *   device keys F1-F4 (ctrl+num 1-4) the frame's F1-F4: the app each is set to
 *   select net 1-9 (numpad 1-4)      that net chip becomes the active net
 *   device arrows (numpad 0 / .)     the active net left / right (FUNC(softKey))
 *   tablet key (numpad 5)            closes the tablet
 *   radio app key (numpad 6)         opens or closes the tablet's RADIO app
 *   tab keys (numpad 7 / 8)          RADIO's previous / next tab while it is open
 *   TIC key (numpad 9)               TROOPS IN CONTACT
 *
 * THE KEYBOARD'S ARROWS AND F1-F4 ARE NOT TAKEN. The old app ring on the arrow
 * keys is gone: the arrows are the device's numpad 0 / . now.
 *
 * TYPING COMES FIRST. TAC//MSG, TAC//PAC and RADIO's search draw text boxes on
 * this dialog, so while a text box has focus every key is the box's - numpad
 * digits included.
 *
 * ENTER NEVER CLOSES THE DEVICE. A dialog with no default button closes on
 * Enter, which closed the whole tablet from a one-line text box. Enter is
 * swallowed here, except in a multi-line box, where it is a new line.
 *
 * Hung on the dialog by FUNC(onLoad), so it is only ever live while a device is
 * up. Consumed when acted on, so the dialog does not also see the press.
 *
 * Arguments (display KeyDown):
 * 0: Display <DISPLAY>
 * 1: DIK code <NUMBER>
 * 2: Shift <BOOL>
 * 3: Ctrl <BOOL>
 * 4: Alt <BOOL>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * _display displayAddEventHandler ["KeyDown", {_this call jmfsb_devices_fnc_keyDown}]
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]], ["_key", 0, [0]], ["_shift", false, [false]], ["_ctrl", false, [false]], ["_alt", false, [false]]];

private _focus = focusedCtrl _display;
private _typing = !isNull _focus && {ctrlType _focus isEqualTo CT_EDIT};

if (_key in [DIK_RETURN, DIK_NUMPADENTER]) exitWith {
    !(_typing && {(ctrlStyle _focus) % (2 * ST_MULTI) >= ST_MULTI})
};
if (_typing) exitWith {false};

private _pressed = [_key, [_shift, _ctrl, _alt]];
private _fnc_bound = {
    params ["_action"];
    private _bind = [JMFSB_CATEGORY, _action] call CBA_fnc_getKeybind;
    !isNil "_bind" && {_pressed in (_bind param [8, [], [[]]])}
};

private _radioOpen = (uiNamespace getVariable [QEGVAR(tacpad,appCurrent), ""]) isEqualTo "radio";
private _handled = false;
{
    _x params ["_action", "_code"];
    if ([_action] call _fnc_bound) exitWith {
        _handled = [_radioOpen] call _code;
    };
} forEach [
    [QGVAR(button_F1), {[0] call FUNC(softKey)}],
    [QGVAR(button_F2), {[1] call FUNC(softKey)}],
    [QGVAR(button_F3), {[2] call FUNC(softKey)}],
    [QGVAR(button_F4), {[3] call FUNC(softKey)}],
    [QGVAR(button_left), {[KEY_INDEX_LEFT] call FUNC(softKey)}],
    [QGVAR(button_right), {[KEY_INDEX_RIGHT] call FUNC(softKey)}],
    [QGVAR(tabletKey), {[] call FUNC(close)}],
    [QGVAR(radioAppKey), {
        params ["_open"];
        if (_open) then {[] call EFUNC(tacpad,appClose)} else {["radio", [], true] call EFUNC(tacpad,openApp)};
        true
    }],
    [QGVAR(tabPrev), {
        params ["_open"];
        _open && {[-1] call FUNC(tabletRadioTab)}
    }],
    [QGVAR(tabNext), {
        params ["_open"];
        _open && {[1] call FUNC(tabletRadioTab)}
    }],
    [QEGVAR(tacpad_apps,ticKey), {
        if (isNil QEFUNC(tacpad_apps,ticSend)) exitWith {false};
        [true] call EFUNC(tacpad_apps,ticSend);
        true
    }]
];
if (_handled) exitWith {true};

// SELECT NET 1-9, the numbers on the tablet's net row.
for "_i" from 1 to NET_SELECT_KEYS do {
    if ([format ["%1_%2", QGVAR(netSelect), _i]] call _fnc_bound) exitWith {
        _handled = [_i] call FUNC(netSelect);
    };
};

_handled
