#include "script_component.hpp"
/*
 * Author: YonV
 * Joins the mission's room on the voice server: asks the server for a token
 * (FUNC(srvRoomToken)); the extension connects when it comes
 * (FUNC(roomAnswer)), and the room is live on the extension's "connected"
 * (FUNC(callback)). Nothing while already joining or in, while the echo test
 * has the extension's one session, or with no room named yet. Each ask is
 * numbered (GVAR(ask)): an answer to an older one, come late after this was
 * asked again, is dropped, so one join makes one connect.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Asked <BOOL>
 *
 * Example:
 * [] call jmfsb_adapter_livekit_fnc_roomJoin
 *
 * Public: No
 */

if (!hasInterface || GVAR(version) isEqualTo "" || isNil QGVAR(room) || isNull player) exitWith {false};
if (GVAR(state) in [ROOM_JOINING, ROOM_LIVE]) exitWith {false};
if (GVAR(echo) in [ECHO_JOINING, ECHO_LIVE]) exitWith {false};

GVAR(state) = ROOM_JOINING;
GVAR(since) = CBA_missionTime;
GVAR(waitS) = ROOM_ANSWER_S;
GVAR(ask) = GVAR(ask) + 1;
[player, GVAR(ask)] remoteExecCall [QFUNC(srvRoomToken), 2];
TRACE_1("room join asked",GVAR(room));
true
