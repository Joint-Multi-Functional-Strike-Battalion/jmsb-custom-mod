#include "script_component.hpp"
/*
 * Author: YonV
 * Server: signs a player into his own echo room, echo-<his UID>, and sends the
 * voice server's address and the token to him alone (FUNC(echoAnswer)). The
 * address is this addon's CBA setting; the key and secret its settings when
 * set, else the server's environment (JMSB_LIVEKIT_KEY / JMSB_LIVEKIT_SECRET,
 * read by the extension). One token per machine per TOKEN_MIN_S. On Mumble
 * (jmfsb_voice_defaultSystem) the answer is the Mumble address marked for the server's
 * loopback (MUMBLE_ECHO_FORMAT) and the password.
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
private _uid = getPlayerUID _unit;

// MUMBLE (2026-11-01): the server's own loopback plays his voice back to him
// alone, as the echo bot does on LiveKit; the token is the password.
if (([] call FUNC(srvServerKind)) isNotEqualTo SERVER_LIVEKIT) exitWith {
    if (GVAR(mumbleAddress) isEqualTo "") exitWith {
        [false, NO_MUMBLE_TEXT] remoteExecCall [QFUNC(echoAnswer), _to];
    };
    private _mumble = format [MUMBLE_ECHO_FORMAT, _uid, GVAR(mumbleAddress)];
    [true, _mumble, GVAR(mumblePassword)] remoteExecCall [QFUNC(echoAnswer), _to];
};

if (GVAR(url) isEqualTo "") exitWith {
    [false, NO_URL_TEXT] remoteExecCall [QFUNC(echoAnswer), _to];
};
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
