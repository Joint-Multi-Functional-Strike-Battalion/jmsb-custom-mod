#include "script_component.hpp"
/*
 * Author: YonV
 * Client: whether a man may call ALL IN aboard a support helicopter - the
 * condition of the ACE self action (user, 2026-11-02: "troop load, all in (need
 * an ace interaction while in heli for all in)") and of the scroll action
 * (2026-11-06, XEH_postInit). Offered while the helicopter
 * loads at the pickup of a lift tasked by message - it carries [thread id,
 * issuer uid] then (QGVAR(allIn), FUNC(liftTick)) - to a man inside it who is
 * the request's issuer or the leader of his group. The server asks again
 * (FUNC(srvAllIn)).
 *
 * Arguments:
 * 0: The player <OBJECT>
 * 1: The helicopter <OBJECT>
 *
 * Return Value:
 * Offered <BOOL>
 *
 * Example:
 * [player, vehicle player] call jmfsb_support_air_fnc_canAllIn
 *
 * Public: No
 */

params [["_player", objNull, [objNull]], ["_veh", objNull, [objNull]]];

private _loading = _veh getVariable [QGVAR(allIn), []];
if (_loading isEqualTo []) exitWith {false};
if !(_player in crew _veh) exitWith {false};

_loading params ["", ["_issuerUid", "", [""]]];
(getPlayerUID _player) isEqualTo _issuerUid || (leader group _player) isEqualTo _player
