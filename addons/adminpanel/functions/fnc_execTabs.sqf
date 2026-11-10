#include "script_component.hpp"
/*
 * Author: YonV
 * Repaints the EXECUTE strip so the chosen machine is the filled one.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_execTabs
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable ["admp_displayVar", displayNull];
if (isNull _display) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent"];

private _target = missionNamespace getVariable [QGVAR(execTarget), 1];

{
    _x params ["_idc", "_backIdc", "_value"];

    private _ctrl = _display displayCtrl _idc;
    private _back = _display displayCtrl _backIdc;
    private _on = _value isEqualTo _target;

    if (!isNull _back) then {
        _back ctrlSetBackgroundColor ([[0, 0, 0, 0], _ink] select _on);
    };
    if (!isNull _ctrl) then {
        _ctrl ctrlSetTextColor ([_ink, _ground] select _on);
        _ctrl ctrlSetActiveColor ([_accent, _ground] select _on);
    };
} forEach [
    [IDC_ADMINPANEL_REMOTEEXEC_SERVEREXEC, IDC_ADMINPANEL_REMOTEEXEC_SERVEREXEC_BACK, 1],
    [IDC_ADMINPANEL_REMOTEEXEC_LOCALEXEC, IDC_ADMINPANEL_REMOTEEXEC_LOCALEXEC_BACK, 2],
    [IDC_ADMINPANEL_REMOTEEXEC_EXECBUTTON, IDC_ADMINPANEL_REMOTEEXEC_EXECBUTTON_BACK, 0]
];

// Who REMOTE would send to, right now. Read off the list rather than remembered,
// because the selection changes under this strip constantly.
private _remote = _display displayCtrl IDC_ADMINPANEL_REMOTEEXEC_EXECBUTTON;
if (!isNull _remote) then {
    private _player = [_display displayCtrl IDC_ADMINPANEL_PLAYERLIST_LISTBOX] call admp_fnc_playerFromSelection;
    _remote ctrlSetText format ["REMOTE  %1", [toUpper (name _player), "NONE"] select (isNull _player)];
};
