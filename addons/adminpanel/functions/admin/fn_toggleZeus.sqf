/*
    Author: JohnnyShootos (Edited by TheTimidShade)

    Description:
        Creates a zeus module for the selected player unit or deletes it if player already has one

    Parameters:
        NONE
        
    Returns:
        NONE
*/

#include "\z\jmfsb\addons\adminpanel\script_component.hpp"

disableSerialization;



// colour macros // [0.98,0.69,0.25,1]
#define COL_BUTTON_TEXT_ACTIVE [1,1,1,1]
#define COL_BUTTON_TEXT_INACTIVE [1,1,1,1]
#define COL_BUTTON_ACTIVE [0.98,0.69,0.25,1]
#define COL_BUTTON_INACTIVE [0,0,0,0]

private _admp_display = uiNamespace getVariable ['admp_displayVar', displayNull];
if (isNull _admp_display) exitWith {}; // check display exists

private _admp_playerlist_listbox = _admp_display displayCtrl IDC_ADMINPANEL_PLAYERLIST_LISTBOX;
private _player = [_admp_playerlist_listbox] call admp_fnc_playerFromSelection; // get selected player

if (isNull _player) exitWith {["Admin Panel", "No target found!", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";}; // if there is no selected target exit

private _zeus_ctrl = _admp_display displayCtrl IDC_ADMINPANEL_ADMIN_ZEUS;
private _zeus_back = _admp_display displayCtrl IDC_ADMINPANEL_ADMIN_ZEUS_BACK;

private _hasZeus = !isNull(getAssignedCuratorLogic _player);

if (!_hasZeus) then { // player doesn't have zeus, create zeus module
    [_player] remoteExec ["admp_fnc_createZeusModule", 2, false];

    ["Admin Panel", format ["Promoted %1 to Zeus!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";

    if (_player != player) then { // show promoted player a message
        private _message = format ["%1 promoted you to Zeus!", name player];
        ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], _player] call EFUNC(notify,broadcast);
    };
    
    _zeus_ctrl ctrlSetTextColor COL_BUTTON_TEXT_ACTIVE;
    _zeus_back ctrlSetBackgroundColor COL_BUTTON_ACTIVE;
} else {
    deleteVehicle (getAssignedCuratorLogic _player);

    ["Admin Panel", format ["Removed %1's Zeus access!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";

    if (_player != player) then { // show promoted player a message
        private _message = format ["%1 removed your Zeus access!", name player];
        ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], _player] call EFUNC(notify,broadcast);
    };

    _zeus_ctrl ctrlSetTextColor COL_BUTTON_TEXT_INACTIVE;
    _zeus_back ctrlSetBackgroundColor COL_BUTTON_INACTIVE;
};
