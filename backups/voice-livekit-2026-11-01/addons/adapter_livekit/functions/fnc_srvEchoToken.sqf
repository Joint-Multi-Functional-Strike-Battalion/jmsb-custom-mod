#include "script_component.hpp"
/*
 * Author: YonV
 * Server: signs a player into his own echo room, echo-<his UID>, and sends the
 * voice server's address and the token to him alone (FUNC(echoAnswer)). The
 * address is this addon's CBA setting; the key and secret its settings when
 * set, else the server's environment (JMSB_LIVEKIT_KEY / JMSB_LIVEKIT_SECRET,
 * read by the extension). One token per machine per TOKEN_MIN_S.
 *
 * THE SENDER MUST BE THE UNIT'S MACHINE: nobody asks for another man's room.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player] remoteExecCall ["jmfsb_adapter_livekit_fnc_srvEchoToken", 2]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!isServer || {isNull _unit}) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _unit}) exitWith {
    WARNING_2("echo token refused: machine %1 asked for %2",remoteExecutedOwner,name _unit);
};
private _to = [owner _unit, remoteExecutedOwner] select isRemoteExecuted;
// one token per machine per TOKEN_MIN_S; more are dropped
private _at = format ["echo|%1", _to];
if (CBA_missionTime - (GVAR(tokenAt) getOrDefault [_at, -TOKEN_MIN_S]) < TOKEN_MIN_S) exitWith {
    TRACE_1("echo token: asked too soon",_to);
};
GVAR(tokenAt) set [_at, CBA_missionTime];

if (GVAR(url) isEqualTo "") exitWith {
    [false, NO_URL_TEXT] remoteExecCall [QFUNC(echoAnswer), _to];
};

// the key and secret as set, possibly empty: the extension then reads the
// server's environment (JMSB_LIVEKIT_KEY / JMSB_LIVEKIT_SECRET)
private _uid = getPlayerUID _unit;
// The setting, else the in-game secret (review R4), else the server's environment.
private _key = [GVAR(key), ["livekitKey"] call EFUNC(common,secret)] select (GVAR(key) isEqualTo "");
private _secret = [GVAR(secret), ["livekitSecret"] call EFUNC(common,secret)] select (GVAR(secret) isEqualTo "");
(["token", [_key, _secret, ECHO_ROOM_PREFIX + _uid, _uid, name _unit]] call FUNC(ext)) params ["_result", "_ok"];
if (!_ok) exitWith {
    WARNING_1("echo token: %1",_result);
    private _why = switch (true) do {
        case (_result isEqualTo ""): {NO_EXT_TEXT};
        case ((_result find NOT_SET_MARK) >= 0): {NOT_SET_TEXT};
        default {_result};
    };
    [false, _why] remoteExecCall [QFUNC(echoAnswer), _to];
};
[true, GVAR(url), _result] remoteExecCall [QFUNC(echoAnswer), _to];
