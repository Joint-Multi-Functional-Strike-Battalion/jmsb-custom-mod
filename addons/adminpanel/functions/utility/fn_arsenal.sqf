/*
    Author: JohnnyShootos (Edited by TheTimidShade)

    Description:
        Opens BI/ACE arsenal on selected unit

    Parameters:
        0: BOOL - Whether shift button was held when clicking
        
    Returns:
        NONE
*/

#include "\z\jmfsb\addons\adminpanel\script_component.hpp"

disableSerialization;

params ["_shift"];


private _admp_display = uiNamespace getVariable ['admp_displayVar', displayNull];
if (isNull _admp_display) exitWith {}; // check display exists

private _admp_playerlist_listbox = _admp_display displayCtrl IDC_ADMINPANEL_PLAYERLIST_LISTBOX;
private _player = [_admp_playerlist_listbox] call admp_fnc_playerFromSelection; // get selected player

if (isNull _player) exitWith {["Admin Panel", "No target found!", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";}; // if there is no selected target exit

if (_shift) then { // check which arsenal to open
    [2] remoteExec ["closeDialog", _player, false]; // if the player has dialog open close it
    [_player, "EXTERNAL"] remoteExec ["switchCamera", _player, false]; // force 3rd person view
    ["Open", [true]] remoteExec ["BIS_fnc_arsenal", _player, false];
    ["Admin Panel", format ["Opened BI arsenal on %1!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";
} else {
    [2] remoteExec ["closeDialog", _player, false];
    [_player, "EXTERNAL"] remoteExec ["switchCamera", _player, false]; // force 3rd person view
    [_player, _player, true] remoteExec ["ace_arsenal_fnc_openBox", _player, false];
    ["Admin Panel", format ["Opened ACE arsenal on %1!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";
};

if (_player != player) then { // show selected player a message
    private _message = format ["%1 opened arsenal for you!", name player];
    [QEGVAR(notify,post), ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], sideUnknown], _player] call CBA_fnc_targetEvent;
};

if (_player == player) then {(uiNamespace getVariable ['admp_displayVar', displayNull]) closeDisplay 2;}; // close the admin panel if arsenal was opened on local client
