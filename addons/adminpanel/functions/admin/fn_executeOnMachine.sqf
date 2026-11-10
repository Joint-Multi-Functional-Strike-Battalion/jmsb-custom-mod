/*
    Author: JohnnyShootos (Edited by TheTimidShade)

    Description:
        Executes code from admin panel code box on the selected player's client

    Parameters:
        0: NUMBER - Exec type, 0 for selected client, 1 for server, 2 for local        
    Returns:
        NONE
*/

#include "\z\jmfsb\addons\adminpanel\script_component.hpp"

params ["_execType"];


private _admp_display = uiNamespace getVariable ['admp_displayVar', displayNull];
if (isNull _admp_display) exitWith {}; // check display exists

private _edit_box = _admp_display displayCtrl IDC_ADMINPANEL_REMOTEEXEC_EDITBOX;
private _admp_playerlist_listbox = _admp_display displayCtrl IDC_ADMINPANEL_PLAYERLIST_LISTBOX;
private _player = [_admp_playerlist_listbox] call admp_fnc_playerFromSelection; // get selected player

private _code = ctrlText _edit_box;
admp_debug_previousCode pushBack _code;
admp_debug_codeIndex = (count admp_debug_previousCode-1); // set index to be most recent code

switch (_execType) do {
    case 0: { // use selected client
        if (isNull _player) exitWith {["Admin Panel", "No target found!", [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";};
        // through the server, which checks the admin and forwards (review S3)
        [_code, clientOwner, _player] remoteExec ["admp_fnc_compileAndExec", 2, false];
        [format ["> remote exec  %1", name _player]] call FUNC(execLog);
        ["Admin Panel", format ["Executed code on %1's client!", name _player], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
        playSound "3DEN_notificationDefault";
    };
    case 1: { // use server client
        [_code, clientOwner] remoteExec ["admp_fnc_compileAndExec", 2, false];
        ["> server exec"] call FUNC(execLog);
        ["Admin Panel", "Executed code on server!", [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
        playSound "3DEN_notificationDefault";
    }; 
    case 2: { // use local client
        [_code, clientOwner] spawn admp_fnc_compileAndExec;
        ["> local exec"] call FUNC(execLog);
        ["Admin Panel", "Executed code on local client!", [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
        playSound "3DEN_notificationDefault";
    }; 
};
