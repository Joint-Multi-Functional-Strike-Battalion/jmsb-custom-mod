#include "script_component.hpp"
/*
 * Author: YonV
 * Server: which voice server this mission talks to, from the voice system
 * setting (jmfsb_voice_defaultSystem) and the addresses that are set:
 *
 *   LiveKit    LiveKit when its address is set
 *   Mumble     Mumble when its address is set
 *   Automatic  Mumble when its address is set, else LiveKit when its address
 *              is set (2026-11-05: Automatic used to mean Mumble even with no
 *              Mumble address, and nobody heard anybody)
 *
 * "" = none set: the voice core then runs the game VON for the mission
 * (the adapter's "serverReady" hook, jmfsb_voice_fnc_followServer).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * SERVER_LIVEKIT, SERVER_MUMBLE or "" <STRING>
 *
 * Example:
 * [] call jmfsb_adapter_livekit_fnc_srvServerKind
 *
 * Public: No
 */

private _choice = EGVAR(voice,defaultSystem);
private _livekit = [SERVER_NONE, SERVER_LIVEKIT] select (GVAR(url) isNotEqualTo "");
private _mumble = [SERVER_NONE, SERVER_MUMBLE] select (GVAR(mumbleAddress) isNotEqualTo "");

switch (_choice) do {
    case SERVER_LIVEKIT: {_livekit};
    case SERVER_MUMBLE: {_mumble};
    default {[_mumble, _livekit] select (_mumble isEqualTo SERVER_NONE)};
}
