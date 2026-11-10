#include "script_component.hpp"
/*
 * Author: YonV
 * Pops a small text-entry dialog asking the player to name the patrol base.
 * Self-contained (built at runtime on RscDisplayEmpty - no config dialog class).
 *
 * Arguments:
 * 0: Callback <CODE> - called with [_name]; _name is "" if cancelled.
 *
 * Return Value: None
 *
 * Example:
 * [{ params ["_name"]; systemChat _name }] call jmfsb_patrol_base_fnc_promptName
 *
 * Public: No
 */

params [["_onConfirm", {}, [{}]]];
if !(hasInterface) exitWith {};

disableSerialization;
private _display = findDisplay 46 createDisplay "RscDisplayEmpty";
if (isNull _display) exitWith { [""] call _onConfirm; };

#define EDIT_IDC 47001
_display setVariable [QGVAR(cb), _onConfirm];

private _w = 0.42 * safeZoneW;
private _h = 0.20 * safeZoneH;
private _x = safeZoneX + (safeZoneW - _w) / 2;
private _y = safeZoneY + (safeZoneH - _h) / 2;
private _pad = 0.01 * safeZoneW;
private _row = 0.045 * safeZoneH;

private _bg = _display ctrlCreate ["RscText", -1];
_bg ctrlSetPosition [_x, _y, _w, _h];
_bg ctrlSetBackgroundColor [0, 0, 0, 0.85];
_bg ctrlCommit 0;

private _title = _display ctrlCreate ["RscText", -1];
_title ctrlSetPosition [_x + _pad, _y + _pad, _w - 2 * _pad, _row];
_title ctrlSetText "Name this patrol base:";
_title ctrlCommit 0;

private _edit = _display ctrlCreate ["RscEdit", EDIT_IDC];
_edit ctrlSetPosition [_x + _pad, _y + _pad + _row, _w - 2 * _pad, _row];
_edit ctrlSetBackgroundColor [1, 1, 1, 0.1];
_edit ctrlSetText format ["Patrol Base %1", (count (missionNamespace getVariable [QGVAR(bases), []])) + 1];
_edit ctrlCommit 0;
ctrlSetFocus _edit;

private _ok = _display ctrlCreate ["RscButtonMenu", -1];
_ok ctrlSetPosition [_x + _w - 2 * (0.10 * safeZoneW) - 2 * _pad, _y + _h - _row - _pad, 0.10 * safeZoneW, _row];
_ok ctrlSetText "Confirm";
_ok ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _dlg = ctrlParent _ctrl;
    private _name = ctrlText (_dlg displayCtrl EDIT_IDC);
    private _cb = _dlg getVariable [QGVAR(cb), {}];
    _dlg closeDisplay 1;
    [_name] call _cb;
}];
_ok ctrlCommit 0;

private _cancel = _display ctrlCreate ["RscButtonMenu", -1];
_cancel ctrlSetPosition [_x + _w - (0.10 * safeZoneW) - _pad, _y + _h - _row - _pad, 0.10 * safeZoneW, _row];
_cancel ctrlSetText "Cancel";
_cancel ctrlAddEventHandler ["ButtonClick", {
    params ["_ctrl"];
    private _dlg = ctrlParent _ctrl;
    private _cb = _dlg getVariable [QGVAR(cb), {}];
    _dlg closeDisplay 2;
    [""] call _cb;
}];
_cancel ctrlCommit 0;
