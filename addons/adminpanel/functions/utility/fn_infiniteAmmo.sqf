/*
    Author: JohnnyShootos (Edited by TheTimidShade)

    Description:
        Enables infinite ammo on selected unit

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

private _ammo_ctrl = _admp_display displayCtrl IDC_ADMINPANEL_UTILITIES_INFAMMO;
private _ammo_back = _admp_display displayCtrl IDC_ADMINPANEL_UTILITIES_INFAMMO_BACK;

[clientOwner] remoteExec ["admp_fnc_toggleLocalFiredEH", _player, false]; // toggle EH on player's client, send client ID so client can return message

waitUntil {admp_returnValue != -1}; // wait until returnValue has been set

if (admp_returnValue == 1) then { // EH was created
    ["Admin Panel", format ["Gave %1 infinite ammo!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";
    
    _ammo_ctrl ctrlSetTextColor COL_BUTTON_TEXT_ACTIVE;
    _ammo_back ctrlSetBackgroundColor COL_BUTTON_ACTIVE;

    if (_player != player) then { // show selected player a message
        private _message = format ["%1 enabled infinite ammo on you!", name player];
        ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], _player] call EFUNC(notify,broadcast);
    };
} else {
    ["Admin Panel", format ["Removed %1's infinite ammo!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";
    
    _ammo_ctrl ctrlSetTextColor COL_BUTTON_TEXT_INACTIVE;
    _ammo_back ctrlSetBackgroundColor COL_BUTTON_INACTIVE;

    if (_player != player) then { // show selected player a message
        private _message = format ["%1 disabled infinite ammo on you!", name player];
        ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], _player] call EFUNC(notify,broadcast);
    };
};

admp_returnValue = -1; // reset return value
