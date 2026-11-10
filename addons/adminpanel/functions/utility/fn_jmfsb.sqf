/*
    Author: JohnnyShootos (Edited by TheTimidShade)

    Description:
        Enables jmfsb mode on selected unit (hides model and disables collision)

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

private _jmfsb_ctrl = _admp_display displayCtrl IDC_ADMINPANEL_UTILITIES_JMFSB;
private _jmfsb_back = _admp_display displayCtrl IDC_ADMINPANEL_UTILITIES_JMFSB_BACK;

//private _jmfsb = !(_player getVariable ["admp_isVisible", false]);
private _jmfsb = _player in admp_utilities_jmfsb_enabledUnits;

if (!_jmfsb) then {
    [_player, true] remoteExec ["hideObjectGlobal", 2, false];
    _player setCaptive true;
    admp_utilities_jmfsb_enabledUnits pushBackUnique _player;
    
    ["Admin Panel", format ["Enabled ghosting for %1!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";
    
    _jmfsb_ctrl ctrlSetTextColor COL_BUTTON_TEXT_ACTIVE;
    _jmfsb_back ctrlSetBackgroundColor COL_BUTTON_ACTIVE;

    if (_player != player) then { // show selected player a message
        private _message = format ["%1 enabled ghosting on you!", name player];
        ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], _player] call EFUNC(notify,broadcast);
    };
} else {
    [_player, false] remoteExec ["hideObjectGlobal", 2, false];
    _player setCaptive false;
    admp_utilities_jmfsb_enabledUnits deleteAt (admp_utilities_jmfsb_enabledUnits find _player);
    
    ["Admin Panel", format ["Disabled ghosting for %1!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";
    
    _jmfsb_ctrl ctrlSetTextColor COL_BUTTON_TEXT_INACTIVE;
    _jmfsb_back ctrlSetBackgroundColor COL_BUTTON_INACTIVE;

    if (_player != player) then { // show selected player a message
        private _message = format ["%1 disabled ghosting on you!", name player];
        ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], _player] call EFUNC(notify,broadcast);
    };
};

publicVariable "admp_utilities_jmfsb_enabledUnits";
