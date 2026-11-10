/*
    Author: TheTimidShade

    Description:
        Assigns the selected player to the group that the player in the combobox belongs to

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
private _admp_player_groupcombo = _admp_display displayCtrl IDC_ADMINPANEL_PLAYER_GROUP_COMBO;

private _playerJoining = [_admp_playerlist_listbox] call admp_fnc_playerFromSelection;
private _playerToJoin = [_admp_player_groupcombo] call admp_fnc_playerFromSelection;

if (isNull _playerJoining || isNull _playerToJoin) exitWith {["Admin Panel", "No target found!", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";}; // if there is no selected target exit

if (group _playerJoining != group _playerToJoin) then {
    [_playerJoining] joinSilent (group _playerToJoin);
    ["Admin Panel", format ["Assigned %1 to %2's group!", name _playerJoining, name _playerToJoin], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";

    if (_playerJoining != player) then { // show assigned player a message
        private _message = format ["%1 assigned you to %2's group!", name player, name _playerToJoin];
        ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], _playerJoining] call EFUNC(notify,broadcast);
    };

    if (_playerToJoin != player) then { // show player asssigned to a message
        private _message = format ["%1 assigned %2 to your group!", name player, name _playerJoining];
        ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], _playerToJoin] call EFUNC(notify,broadcast);
    };
} else {
    ["Admin Panel", format ["%1 is already in %2's group!", name _playerJoining, name _playerToJoin], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "addItemFailed";
};
