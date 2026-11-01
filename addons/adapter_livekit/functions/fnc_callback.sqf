#include "script_component.hpp"
/*
 * Author: JMSB
 * What the jmsb_voice extension reports (its ExtensionCallback, XEH_postInit).
 * The extension has one session, the echo test's while that runs
 * (GVAR(echo) joining or live), the mission's room otherwise:
 *   connected          the room is live: the mic may open
 *   joined [id]        a speaker joined (silent and not received until the
 *                      mix says otherwise); the echo bot answered
 *   left [id]          a speaker left; the echo bot left: the test ends
 *   speaking [ids]     who the server hears now - not used: who talks on
 *                      which net is the key events' (FUNC(keyed))
 *   disconnected [why] the voice server dropped us (not when we left): the
 *                      room is rejoined after ROOM_RETRY_S
 *   nomic [text]       no microphone (none, or Windows' privacy settings):
 *                      the room stays, he hears; said once
 *   error [text]       joining failed: tried again after GVAR(retryS),
 *                      doubling to ROOM_RETRY_SLOW_S, said once until it works
 *
 * Arguments:
 * 0: Function <STRING>
 * 1: Data <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["joined", "echo"] call jmfsb_adapter_livekit_fnc_callback
 *
 * Public: No
 */

params [["_function", "", [""]], ["_data", "", [""]]];

private _echo = GVAR(echo) in [ECHO_JOINING, ECHO_LIVE];
TRACE_3("callback",_function,_data,_echo);

switch (_function) do {
    case "connected": {
        if (_echo || GVAR(state) isNotEqualTo ROOM_JOINING) exitWith {};
        GVAR(state) = ROOM_LIVE;
        // a new session: nobody set, nobody received
        GVAR(sent) = createHashMap;
        GVAR(subs) = createHashMap;
        GVAR(retryS) = ROOM_RETRY_S;
        GVAR(toldError) = false;
        INFO_1("voice server: in the room %1",GVAR(room));
        [VOICE_TITLE, "On the voice server."] call EFUNC(notify,notify);
        [] call FUNC(mic);
    };
    case "joined": {
        if (_echo) exitWith {
            if (_data isNotEqualTo ECHO_BOT || GVAR(echo) isNotEqualTo ECHO_JOINING) exitWith {};
            GVAR(echo) = ECHO_LIVE;
            GVAR(echoSince) = CBA_missionTime;
            // the extension receives nobody and plays nobody until told
            ["subscribe", [ECHO_BOT, true]] call FUNC(ext);
            ["speaker", [ECHO_BOT, 1, 0]] call FUNC(ext);
            ["talk", [true]] call FUNC(ext);
            [ECHO_TITLE, "Talk, then pause: you hear it back. Hang up on the phone or the tablet."] call EFUNC(notify,notify);
            [QGVAR(echo), [GVAR(echo)]] call CBA_fnc_localEvent;
        };
        ["speaker", [_data, 0, 0]] call FUNC(ext);
        GVAR(sent) set [_data, [0, 0]];
    };
    case "left": {
        if (_echo) exitWith {
            if (_data isEqualTo ECHO_BOT && GVAR(echo) isEqualTo ECHO_LIVE) then {
                [false, "The echo bot left."] call FUNC(echo);
            };
        };
        // the extension forgot his gain and ear: sent again on the next tick
        GVAR(sent) deleteAt _data;
    };
    case "nomic": {
        WARNING_1("voice server: no microphone (%1) - listening only",_data);
        if (_echo) exitWith {
            [false, format ["No microphone: %1.", _data]] call FUNC(echo);
        };
        if (!GVAR(toldNoMic)) then {
            GVAR(toldNoMic) = true;
            [VOICE_TITLE, format ["No microphone (%1): you hear the nets but cannot talk. Check Windows' microphone privacy settings, or the Microphone setting (JMSB - Voice (Built-in)).", _data]] call EFUNC(notify,notify);
        };
    };
    case "disconnected": {
        if (_echo) exitWith {
            // Our own leaving reports ClientInitiated, after the test ended.
            if (_data isEqualTo DROP_BY_US || GVAR(echo) isEqualTo ECHO_IDLE) exitWith {};
            [false, format ["The voice server dropped the call (%1).", _data]] call FUNC(echo);
        };
        if (_data isEqualTo DROP_BY_US || !(GVAR(state) in [ROOM_JOINING, ROOM_LIVE])) exitWith {};
        GVAR(state) = ROOM_IDLE;
        GVAR(mic) = false;
        WARNING_2("voice server dropped us (%1) - rejoining in %2 s",_data,ROOM_RETRY_S);
        [VOICE_TITLE, format ["The voice server dropped you (%1). Rejoining.", _data]] call EFUNC(notify,notify);
        [FUNC(roomJoin), [], ROOM_RETRY_S] call CBA_fnc_waitAndExecute;
    };
    case "error": {
        WARNING_1("jmsb_voice: %1",_data);
        if (_echo) exitWith {
            [false, format ["Voice: %1", _data]] call FUNC(echo);
        };
        if (GVAR(state) isEqualTo ROOM_JOINING) then {
            GVAR(state) = ROOM_IDLE;
            if (!GVAR(toldError)) then {
                GVAR(toldError) = true;
                [VOICE_TITLE, format ["Voice: %1. Trying again.", _data]] call EFUNC(notify,notify);
            };
            [FUNC(roomJoin), [], GVAR(retryS)] call CBA_fnc_waitAndExecute;
            GVAR(retryS) = (2 * GVAR(retryS)) min ROOM_RETRY_SLOW_S;
        };
    };
};
