/*
    Author: TheTimidShade

    Description:
        Forces the selected player out of their vehicle

    Parameters:
        NONE
        
    Returns:
        NONE
*/

#include "\z\jmfsb\addons\adminpanel\script_component.hpp"

disableSerialization;


private _admp_display = uiNamespace getVariable ['admp_displayVar', displayNull];
if (isNull _admp_display) exitWith {}; // check display exists

private _admp_playerlist_listbox = _admp_display displayCtrl IDC_ADMINPANEL_PLAYERLIST_LISTBOX;
private _player = [_admp_playerlist_listbox] call admp_fnc_playerFromSelection; // get selected player

if (isNull _player) exitWith {["Admin Panel", "No target found!", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";}; // if there is no selected target exit

if (isNull objectParent _player) exitWith {["Admin Panel", format ["%1 is not in a vehicle!", name _player], [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";};

moveOut _player;

["Admin Panel", format ["Dismounted %1!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
playSound "3DEN_notificationDefault";

if (_player != player) then { // show selected player a message
    private _message = format ["%1 dismounted you!", name player];
    ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], _player] call EFUNC(notify,broadcast);
};
