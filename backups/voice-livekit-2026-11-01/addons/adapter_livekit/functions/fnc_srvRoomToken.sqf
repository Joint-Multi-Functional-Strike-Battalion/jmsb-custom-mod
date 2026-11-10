#include "script_component.hpp"
/*
 * Author: YonV
 * Server: signs a player into the mission's room (GVAR(room)) and sends the
 * voice server's address and the token to him alone (FUNC(roomAnswer)). The
 * address is this addon's CBA setting; the key and secret its settings when
 * set, else the server's environment (JMSB_LIVEKIT_KEY / JMSB_LIVEKIT_SECRET,
 * read by the extension - the secret should never be a CBA setting, which
 * every client receives). The identity is his
 * UID, which is how every client names him in the mix (FUNC(speaker)).
 * THE SENDER MUST BE THE UNIT'S MACHINE: nobody asks for another man's token.
 * One token per machine per TOKEN_MIN_S: more are dropped. The ask's number
 * goes back with the answer, so the client uses only its last ask's.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: The client's ask number <NUMBER> (default: -1)
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, 1] remoteExecCall ["jmfsb_adapter_livekit_fnc_srvRoomToken", 2]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_ask", -1, [0]]];

if (!isServer || {isNull _unit}) exitWith {};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo owner _unit}) exitWith {
    WARNING_2("room token refused: machine %1 asked for %2",remoteExecutedOwner,name _unit);
};
private _to = [owner _unit, remoteExecutedOwner] select isRemoteExecuted;
private _at = format ["room|%1", _to];
if (CBA_missionTime - (GVAR(tokenAt) getOrDefault [_at, -TOKEN_MIN_S]) < TOKEN_MIN_S) exitWith {
    TRACE_1("room token: asked too soon",_to);
};
GVAR(tokenAt) set [_at, CBA_missionTime];

if (GVAR(url) isEqualTo "") exitWith {
    [false, NO_URL_TEXT, "", _ask] remoteExecCall [QFUNC(roomAnswer), _to];
};

// the key and secret as set, possibly empty: the extension then reads the
// server's environment (JMSB_LIVEKIT_KEY / JMSB_LIVEKIT_SECRET)
private _uid = getPlayerUID _unit;
// The key and secret: the setting, else what an admin entered in game (kept in
// the server's profile, review R4), else "" - the extension then reads the
// server's environment (JMSB_LIVEKIT_KEY / JMSB_LIVEKIT_SECRET).
private _key = [GVAR(key), ["livekitKey"] call EFUNC(common,secret)] select (GVAR(key) isEqualTo "");
private _secret = [GVAR(secret), ["livekitSecret"] call EFUNC(common,secret)] select (GVAR(secret) isEqualTo "");
(["token", [_key, _secret, GVAR(room), _uid, name _unit]] call FUNC(ext)) params ["_result", "_ok"];
if (!_ok) exitWith {
    WARNING_1("room token: %1",_result);
    private _why = switch (true) do {
        case (_result isEqualTo ""): {NO_EXT_TEXT};
        case ((_result find NOT_SET_MARK) >= 0): {NOT_SET_TEXT};
        default {_result};
    };
    [false, _why, "", _ask] remoteExecCall [QFUNC(roomAnswer), _to];
};
[true, GVAR(url), _result, _ask] remoteExecCall [QFUNC(roomAnswer), _to];
