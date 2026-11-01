/*
    Author: TheTimidShade

    Description:
        Rearms the selected player's vehicle

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

private _playerVehicle = vehicle _player;
if (_playerVehicle == _player) exitWith {["Admin Panel", format ["%1 is not in a vehicle!", name _player], [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";};

// Make sure all crew weapons are rearmed
{
    [(vehicle _x), 1] remoteExec ["setVehicleAmmo", _x, false];
} forEach crew _playerVehicle;

["Admin Panel", format ["Fully rearmed %1's vehicle!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
playSound "3DEN_notificationDefault";

if (_player != player) then { // show selected player a message
    private _message = format ["%1 rearmed your vehicle!", name player];
    ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], _player] call EFUNC(notify,broadcast);
};
