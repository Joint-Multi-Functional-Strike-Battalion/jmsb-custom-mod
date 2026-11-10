#include "script_component.hpp"
/*
 * Author: YonV
 * Repaints the four map tabs so the active one is filled.
 *
 * A tab strip where nothing says which tab you are on is four buttons.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_mapTabs
 *
 * Public: No
 */

disableSerialization;

private _display = uiNamespace getVariable ["admp_displayVar", displayNull];
if (isNull _display) exitWith {};

([] call EFUNC(tacpad,theme)) params ["_ground", "_ink", "_accent"];

private _active = missionNamespace getVariable [QGVAR(mapFilter), "players"];

{
    _x params ["_idc", "_id"];

    private _ctrl = _display displayCtrl _idc;
    if (isNull _ctrl) then {continue};

    private _on = _id isEqualTo _active;
    _ctrl ctrlSetBackgroundColor ([[0, 0, 0, 0], _ink] select _on);
    _ctrl ctrlSetTextColor ([_ink, _ground] select _on);
    _ctrl ctrlSetActiveColor ([_accent, _ground] select _on);
} forEach [
    [IDC_ADMINPANEL_MAP_TAB_PLAYERS, "players"],
    [IDC_ADMINPANEL_MAP_TAB_VEHICLES, "vehicles"],
    [IDC_ADMINPANEL_MAP_TAB_AI, "ai"],
    [IDC_ADMINPANEL_MAP_TAB_MARKERS, "markers"]
];
