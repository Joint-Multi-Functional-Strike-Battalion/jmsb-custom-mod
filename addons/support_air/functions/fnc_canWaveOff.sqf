#include "script_component.hpp"
/*
 * Author: YonV
 * Whether a man aboard may WAVE OFF the insertion (user, 2026-11-08: "on
 * insertion add a wave off scroll command"): aboard a support transport on a
 * lift request's insertion leg (QGVAR(waveOff), set from ALL IN until it is
 * down on the LZ or its ropes are in), and the request's issuer or a group
 * leader. The scroll and ACE actions' condition; FUNC(srvWaveOff) checks the
 * same again on the server.
 *
 * Arguments:
 * 0: The player <OBJECT>
 * 1: The vehicle he is in <OBJECT>
 *
 * Return Value:
 * Offered <BOOL>
 *
 * Example:
 * [player, vehicle player] call jmfsb_support_air_fnc_canWaveOff
 *
 * Public: No
 */

params [["_player", objNull, [objNull]], ["_veh", objNull, [objNull]]];

private _leg = _veh getVariable [QGVAR(waveOff), []];
if (_leg isEqualTo []) exitWith {false};
if !(_player in crew _veh) exitWith {false};

_leg params ["", ["_issuerUid", "", [""]]];
(getPlayerUID _player) isEqualTo _issuerUid || (leader group _player) isEqualTo _player
