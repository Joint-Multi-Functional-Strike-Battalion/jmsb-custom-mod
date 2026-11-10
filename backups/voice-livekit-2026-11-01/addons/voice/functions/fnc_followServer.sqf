#include "script_component.hpp"
/*
 * Author: YonV
 * THE SERVER PICKS THE VOICE SYSTEM FOR EVERYONE (2026-10-31,
 * PLAN_VOICE_EW_PLAY V1; RECOMMENDATIONS R13). Called at
 * CBA_settingsInitialized, after FUNC(selectSystem) has made this machine's
 * own choice from the setting.
 * - Server: its choice is the mission's, published (GVAR(serverSystem),
 *   publicVariable reaches JIP too).
 * - Client: waits for the server's choice and takes it when it can run it
 *   (game VON always can; LiveKit when its extension loaded here). When it
 *   cannot - the server runs the voice server and this machine's extension
 *   did not load - it is "none": VOICE UNAVAILABLE, said once in the
 *   upper-right notification, rather than alone on the game VON where nobody
 *   hears him. No answer in SERVER_SYSTEM_WAIT_S: its own choice stands.
 * Either way jmfsb_voice_systemReady [system] is raised once, locally: every
 * client-side start of every system waits for it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_voice_fnc_followServer
 *
 * Public: No
 */

if (isServer) exitWith {
    GVAR(serverSystem) = GVAR(system);
    publicVariable QGVAR(serverSystem);
    [QGVAR(systemReady), [GVAR(system)]] call CBA_fnc_localEvent;
};

[{!isNil QGVAR(serverSystem)}, {
    private _server = GVAR(serverSystem);
    private _system = [SYSTEM_NONE, _server] select (_server isEqualTo SYSTEM_VON || {_server in GVAR(loaded)});
    if (_system isNotEqualTo GVAR(system)) then {
        INFO_2("voice: the server's system is %1 - this machine had %2",_server,GVAR(system));
        [_system] call FUNC(selectSystem);
    };
    if (_system isEqualTo SYSTEM_NONE) then {
        private _name = [toUpper _server, LIVEKIT_NAME] select (_server isEqualTo SYSTEM_LIVEKIT);
        [UNAVAILABLE_TITLE, format [UNAVAILABLE_TEXT, _name]] call EFUNC(notify,notify);
    };
    [QGVAR(systemReady), [GVAR(system)]] call CBA_fnc_localEvent;
}, [], SERVER_SYSTEM_WAIT_S, {
    WARNING_2("voice: no system from the server in %1 s - keeping this machine's own (%2)",SERVER_SYSTEM_WAIT_S,GVAR(system));
    [QGVAR(systemReady), [GVAR(system)]] call CBA_fnc_localEvent;
}] call CBA_fnc_waitUntilAndExecute;
