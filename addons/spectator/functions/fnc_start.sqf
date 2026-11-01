#include "script_component.hpp"
/*
 * Author: 3Mydlo3
 * Function starts spectator for given player
 *
 * Arguments:
 * 0: player unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] call jmfsb_spectator_fnc_start
 *
 * Public: No
 */

params [["_player", player]];

// Another machine's say-so only from the server (review R1: it was a CBA
// event any client could raise to force everyone into spectator).
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("start: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (isNull _player) exitWith {};
if (!(local _player)) exitWith {[_player] remoteExecCall [QFUNC(start), _player]};
if (!hasInterface) exitWith {};

if (["IsInitialized"] call BIS_fnc_EGSpectator) exitWith {WARNING("Spectator already initialized!")};

// Determine spectator parameters based on player consciousness
private _unconscious = [player] call EFUNC(common,isUnconscious);

private _sides = [GVAR(sides), GVAR(sidesUnconscious)] select _unconscious;
private _civilianSide = [GVAR(civilianSide), GVAR(civilianSideUnconscious)] select _unconscious;
private _allowAI = [GVAR(allowAI), GVAR(allowAIUnconscious)] select _unconscious;
private _freeCamera = [GVAR(freeCamera), GVAR(freeCameraUnconscious)] select _unconscious;
private _TPPCamera = [GVAR(TPPCamera), GVAR(TPPCameraUnconscious)] select _unconscious;

// Determine sides available for spectating
private _whitelistedSides = switch _sides do {
    // Friendly sides spectator
    case 0: {playerSide call BIS_fnc_friendlySides};
    // Player side spectator
    case 1: {[playerSide]};
    // All sides spectator
    case 2: {[WEST, INDEPENDENT, EAST]};
    // Player group only
    case 3: {[group player]};
    // Player only
    case 4: {[player]};
    default {playerSide call BIS_fnc_friendlySides};
};

if (_civilianSide) then {
    _whitelistedSides pushBack CIVILIAN;
};

// EG spectator disables player damage on init,
// save allowDamage state to restore it after spectator is opened.
private _allowDamage = isDamageAllowed player;

// Start spectator
["Initialize", [player, _whitelistedSides, _allowAI, _freeCamera, _TPPCamera, true, true, true, true, true]] call BIS_fnc_EGSpectator;
player allowDamage _allowDamage;
WARNING("Starting spectator!");

nil
