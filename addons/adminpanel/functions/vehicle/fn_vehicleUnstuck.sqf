/*
    Author: TheTimidShade

    Description:
        Finds a safe place to teleport vehicle to and flips it upright

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

private _vehicle = vehicle _player;
private _admp_usingCursortarget = false;

// if the selected player is not the one using the admin panel and are not in a vehicle, exit
if (_vehicle == _player && _player != player) exitWith {["Admin Panel", format ["%1 is not in a vehicle!", name _player], [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";};
// if the player has selected themselves and is not in a vehicle, use their crosshair to find vehicle to unstick
if (_vehicle == _player) then {
    _vehicle = cursorTarget;
    _admp_usingCursortarget = true;
};

if (isNull _vehicle || !(_vehicle isKindOf "AllVehicles")) exitWith {["Admin Panel", format ["No crosshair target found!"], [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";};

if (vectorMagnitude velocity _vehicle > 3) exitWith {["Admin Panel", format ["Vehicle must be stopped!"], [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";};

// find safe position and teleport player there if it can be found
private _safePosition = (getPos _player) findEmptyPosition [5,50, typeOf _vehicle];
if (_safePosition isEqualTo []) exitWith {["Admin Panel", format ["Unable to find safe teleport location!"], [0.831, 0.267, 0.267, 1]] call EFUNC(notify,notify); playSound "addItemFailed";};

// convert to 2D position
_safePosition = [_safePosition#0, _safePosition#1];
[_vehicle, _safePosition] remoteExec ["setPos", _vehicle, false];

if (_admp_usingCursortarget) then {
    ["Admin Panel", format ["Righted and moved target vehicle to %1!", str _safePosition], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";
    [_player, _vehicle] spawn {
        params ["_player", "_vehicle"];
        sleep 0.1; // small sleep to let position update
        _player setDir (_player getDir _vehicle); // make player face direction of vehicle so they know where it went
        _player setPosATL (getPosATL _player); // update position so that dir updates
    };
} else {
    ["Admin Panel", format ["Righted and moved %1's vehicle to %2!", name _player, str _safePosition], [0.4, 0.702, 0.4, 1]] call EFUNC(notify,notify);
    playSound "3DEN_notificationDefault";

    if (_player != player) then { // show selected player a message
        private _message = format ["%1 attempted to unstick your vehicle!", name player];
        ["Admin Panel", _message, [0.871, 0.361, 0.188, 1], _player] call EFUNC(notify,broadcast);
    };
};
