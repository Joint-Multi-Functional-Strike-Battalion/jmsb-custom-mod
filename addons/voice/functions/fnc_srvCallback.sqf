#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a callback request from one player to another, held by the server
 * (fnc_srvCallbacks). One per pair, and at most the "Callbacks per player"
 * setting pending for either of them. Both are told, by remoteExec
 * (FUNC(note)). Reached by remoteExec from FUNC(callBack): From must be the
 * sender (jmfsb_common_fnc_senderIs).
 *
 * Arguments:
 * 0: From <OBJECT>
 * 1: To <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, _unit] remoteExecCall ["jmfsb_voice_fnc_srvCallback", 2]
 *
 * Public: No
 */

params [["_from", objNull, [objNull]], ["_to", objNull, [objNull]]];

if (!isServer || {!([_from] call EFUNC(common,senderIs))}) exitWith {};
if (isNull _from || isNull _to || _from isEqualTo _to) exitWith {};

if ((GVAR(callbacks) findIf {(_x select [0, 2]) in [[_from, _to], [_to, _from]]}) >= 0) exitWith {
    ["CALL BACK", format ["A callback with %1 is already pending.", name _to]] remoteExecCall [QFUNC(note), _from];
};

private _mine = {_from in (_x select [0, 2])} count GVAR(callbacks);
private _theirs = {_to in (_x select [0, 2])} count GVAR(callbacks);
if (_mine >= GVAR(callbacksPerPlayer) || _theirs >= GVAR(callbacksPerPlayer)) exitWith {
    ["CALL BACK", "Too many callbacks pending."] remoteExecCall [QFUNC(note), _from];
};

GVAR(callbacks) pushBack [_from, _to, CBA_missionTime, CB_WAITING];
["CALL BACK", format ["Callback to %1 pending.", name _to]] remoteExecCall [QFUNC(note), _from];
["CALL BACK", format ["%1 asked for a callback.", name _from]] remoteExecCall [QFUNC(note), _to];
[] call FUNC(srvPublish);
