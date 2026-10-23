#include "script_component.hpp"
/*
 * Author: JMSB
 * Lays a clickable, see-through button over each of the six keys printed on
 * the device frame - F1 F2 F3 F4 LEFT RIGHT - so the art is the button. Where
 * the keys are is measured off the render by tools/gen_devices.py into
 * CfgJmfsbDevices keys[] (fractions of the frame's canvas); a device whose keys
 * were not found gets no buttons rather than buttons in the wrong place.
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
    private _button = _display ctrlCreate [QGVAR(keyButton), IDC_TABLET_KEY(_forEachIndex)];
    _button ctrlSetPosition [_fx + _kx * _fw, _fy + _ky * _fh, _kw * _fw, _kh * _fh];
    _button ctrlCommit 0;
    _button setVariable [QGVAR(keyIndex), _forEachIndex];
    _button ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        [_ctrl getVariable [QGVAR(keyIndex), -1]] call FUNC(softKey);
    }];
    private _tip = if (_forEachIndex < SOFT_KEY_COUNT) then {
        private _app = _names select _forEachIndex;
        format ["F%1 (numpad %1): %2", _forEachIndex + 1, ["not set", toUpper _app] select (_app isNotEqualTo "")]
    } else {
        [
            ["Active net left (numpad 0)", "Active net right (numpad .)"],
            ["Previous app (numpad 0)", "Next app (numpad .)"]
        ] select (isNil QEFUNC(voice,stepActive)) select (_forEachIndex isEqualTo KEY_INDEX_RIGHT)
    };
    _button ctrlSetTooltip _tip;
} forEach _keys;

KEY_COUNT
