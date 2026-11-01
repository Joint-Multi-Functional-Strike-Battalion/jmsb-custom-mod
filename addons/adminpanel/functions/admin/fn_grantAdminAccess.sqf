/*
    Author: TheTimidShade

    Description:
        Toggle's the selected player's access to the admin panel

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

if (call BIS_fnc_admin != 2) exitWith {["Admin Panel", "You must be the currently logged in admin to perform this action!", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";};

if ((getPlayerUID _player) in admp_authorisedIDs) then {
    // make sure the player cannot un-admin themselves
    if (_player == player) exitWith {["Admin Panel", "You cannot remove access from yourself!", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";};

    private _message = format ["Are you sure you want to remove admin panel access from %1?", name _player];
    private _confirm = [_message, "CONFIRM REMOVE ACCESS", "CONFIRM", "CANCEL", _admp_display] call BIS_fnc_guiMessage;

    // THE SERVER CHANGES ITS LIST AND ANSWERS (review S2, FUNC(adminGrant)).
    if (_confirm) then {
        [getPlayerUID _player, false] remoteExecCall [QFUNC(adminGrant), 2];
        playSound "3DEN_notificationDefault";
    };
} else {
    private _message = format ["Are you sure you want to give admin panel access to %1?", name _player];
    private _confirm = [_message, "CONFIRM ADMIN ACCESS", "CONFIRM", "CANCEL", _admp_display] call BIS_fnc_guiMessage;

    if (_confirm) then {
        [getPlayerUID _player, true] remoteExecCall [QFUNC(adminGrant), 2];
        playSound "3DEN_notificationDefault";
    };
};
