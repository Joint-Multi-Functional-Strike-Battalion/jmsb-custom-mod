/*
    Author: JohnnyShootos (Edited by TheTimidShade)

    Description:
        Enables god mode on selected unit (disables damage)

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

private _godmode_ctrl = _admp_display displayCtrl IDC_ADMINPANEL_UTILITIES_GODMODE;
private _godmode_back = _admp_display displayCtrl IDC_ADMINPANEL_UTILITIES_GODMODE_BACK;

//private _godmode = !(_player getVariable ["admp_damageEnabled", false]);
private _godmode = _player in admp_utilities_godmode_enabledUnits;

if (!_godmode) then {
    [_player, false] remoteExec ["allowDamage", 0, false];
    admp_utilities_godmode_enabledUnits pushBackUnique _player;
    
    ["Admin Panel", format ["Made %1 invulnerable!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";
    
    _godmode_ctrl ctrlSetTextColor COL_BUTTON_TEXT_ACTIVE;
    _godmode_back ctrlSetBackgroundColor COL_BUTTON_ACTIVE;

    if (_player != player) then { // show selected player a message
        private _message = format ["%1 enabled godmode on you!", name player];
        ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], _player] call EFUNC(notify,broadcast);
    };
} else {
    [_player, true] remoteExec ["allowDamage", 0, false];
    admp_utilities_godmode_enabledUnits deleteAt (admp_utilities_godmode_enabledUnits find _player);
    
    ["Admin Panel", format ["Disabled invulnerability for %1!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";
    
    _godmode_ctrl ctrlSetTextColor COL_BUTTON_TEXT_INACTIVE;
    _godmode_back ctrlSetBackgroundColor COL_BUTTON_INACTIVE;

    if (_player != player) then { // show selected player a message
        private _message = format ["%1 disabled godmode on you!", name player];
        ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], _player] call EFUNC(notify,broadcast);
    };
};

publicVariable "admp_utilities_godmode_enabledUnits";
