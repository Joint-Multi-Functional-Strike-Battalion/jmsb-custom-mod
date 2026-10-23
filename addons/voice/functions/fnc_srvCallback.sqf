#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a callback request from one player to another, held by the server
 * (fnc_srvCallbacks). One per pair, and at most the "Callbacks per player"
 * setting pending for either of them. Both are told.
 *
 * Arguments:
 * 0: From <OBJECT>
 * 1: To <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, _unit] call jmfsb_voice_fnc_srvCallback
 *
 * Public: No
 */

params [["_from", objNull, [objNull]], ["_to", objNull, [objNull]]];

if (isNull _from || isNull _to || _from isEqualTo _to) exitWith {};

if ((GVAR(callbacks) findIf {(_x select [0, 2]) in [[_from, _to], [_to, _from]]}) >= 0) exitWith {
    [QGVAR(note), ["CALL BACK", format ["A callback with %1 is already pending.", name _to]], _from] call CBA_fnc_targetEvent;
};

private _mine = {_from in (_x select [0, 2])} count GVAR(callbacks);
private _theirs = {_to in (_x select [0, 2])} count GVAR(callbacks);
if (_mine >= GVAR(callbacksPerPlayer) || _theirs >= GVAR(callbacksPerPlayer)) exitWith {
    [QGVAR(note), ["CALL BACK", "Too many callbacks pending."], _from] call CBA_fnc_targetEvent;
};

GVAR(callbacks) pushBack [_from, _to, CBA_missionTime, CB_WAITING];
[QGVAR(note), ["CALL BACK", format ["Callback to %1 pending.", name _to]], _from] call CBA_fnc_targetEvent;
[QGVAR(note), ["CALL BACK", format ["%1 asked for a callback.", name _from]], _to] call CBA_fnc_targetEvent;
[] call FUNC(srvPublish);
