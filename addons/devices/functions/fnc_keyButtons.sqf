#include "script_component.hpp"
/*
 * Author: YonV
 * Lays a clickable, see-through button over each of the six keys printed on
 * the device frame - F1 F2 F3 F4 LEFT RIGHT - so the art is the button. Where
 * the keys are is measured off the render by tools/gen_devices.py into
 * CfgJmfsbDevices keys[] (fractions of the frame's canvas); a device whose keys
 * were not found gets no buttons rather than buttons in the wrong place.
 *
 * THE ART'S F1-F4 AND ARROWS SHOW; THE BIND IS ON HOVER (user, 2026-11-01:
 * "way too small, put the F1 F2 etc back, then the keybind on hover" - R3
 * changed after seeing it). The caps that wrote the bind over each key are
 * gone; the tooltip names the key's CBA bind the way RADIO > Nets > KEYS
 * writes it (FUNC(keyLabel)) - a rebind shows the new key the next time the
 * tablet opens.
 *
 * Arguments:
 * 0: The device dialog <DISPLAY>
 * 1: Device class in CfgJmfsbDevices <STRING>
 * 2: Frame position [x, y, w, h] - the canvas, as FUNC(layout) placed it <ARRAY>
 *
 * Return Value:
 * Number of buttons laid <NUMBER>
 *
 * Example:
 * [_display, "large", _framePos] call jmfsb_devices_fnc_keyButtons
 *
 * Public: No
 */

params [["_display", displayNull, [displayNull]], ["_device", "", [""]], ["_framePos", [], [[]], 4]];
if (isNull _display) exitWith {0};

private _keys = getArray (configFile >> "CfgJmfsbDevices" >> _device >> "keys");
if (count _keys != KEY_COUNT) exitWith {0};
_framePos params ["_fx", "_fy", "_fw", "_fh"];

private _names = [GVAR(keyF1), GVAR(keyF2), GVAR(keyF3), GVAR(keyF4)];
{
    _x params ["_kx", "_ky", "_kw", "_kh"];
    private _label = [format ["%1_%2", QGVAR(button), BUTTON_LABELS select _forEachIndex]] call FUNC(keyLabel);

    private _button = _display ctrlCreate [QGVAR(keyButton), IDC_TABLET_KEY(_forEachIndex)];
    _button ctrlSetPosition [_fx + _kx * _fw, _fy + _ky * _fh, _kw * _fw, _kh * _fh];
    _button ctrlCommit 0;
    _button setVariable [QGVAR(keyIndex), _forEachIndex];
    _button ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        [_ctrl getVariable [QGVAR(keyIndex), -1]] call FUNC(softKey);
    }];
    // The tooltip names the printed key and its bind, not a numpad digit it
    // may not be on.
    private _tip = if (_forEachIndex < SOFT_KEY_COUNT) then {
        private _app = _names select _forEachIndex;
        format ["F%1 (%2): %3", _forEachIndex + 1, _label, ["not set", toUpper _app] select (_app isNotEqualTo "")]
    } else {
        format ["%1 (%2)", TABLET_ARROW_TIPS select (_forEachIndex isEqualTo KEY_INDEX_RIGHT), _label]
    };
    _button ctrlSetTooltip _tip;
} forEach _keys;

KEY_COUNT
