#include "script_component.hpp"
/*
 * Author: YonV
 * Voice hook "selfTest" (jmfsb_voice_fnc_selfTest) for the voice server: one
 * RPT line each, tagged "VOICE SERVER" - the extension's version, the room
 * and where the join stands, the microphone, the speakers this machine
 * receives and how many players are in the game. The echo test (RADIO >
 * CALLS > ECHO TEST) is the by-ear check; this says where it stops.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adapter_livekit_fnc_selfTest
 *
 * Public: No
 */

if (!hasInterface) exitWith {};

private _version = [GVAR(version), "NOT LOADED"] select (GVAR(version) isEqualTo "");
private _room = missionNamespace getVariable [QGVAR(room), "none yet"];
private _for = round (CBA_missionTime - GVAR(since));
private _others = (count allPlayers - 1) max 0;
INFO_2("VOICE SERVER extension %1, room %2",_version,_room);
INFO_3("VOICE SERVER join %1 for %2 s, ask %3",GVAR(state),_for,GVAR(ask));
INFO_2("VOICE SERVER microphone open %1, active net %2",GVAR(mic),GVAR(activeNet));
INFO_2("VOICE SERVER receiving %1 of %2 other players",count GVAR(subs),_others);
if (GVAR(state) isNotEqualTo ROOM_LIVE) then {
    WARNING("VOICE SERVER not in the room: see the 'voice server' lines above for why, and jmsb_voice.log in the Arma 3 folder under AppData Local");
};
