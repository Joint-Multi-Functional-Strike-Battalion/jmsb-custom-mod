#include "script_component.hpp"

// Everything runs only while the game's VON is the system chosen
// (jmfsb_voice_system "von"): under LiveKit - the voice (2026-10-31) - or
// "none" nothing here runs. The server waits for
// CBA_settingsInitialized (the voice core decides first, from the setting, in
// its own handler); a client for jmfsb_voice_systemReady, once it has taken
// the server's choice (jmfsb_voice_fnc_followServer).

// SERVER: the C2 and A2G custom channels, made first so they get the lowest
// free ids. CALL channels are made on their first call.
if (isServer) then {
    ["CBA_settingsInitialized", {
        if (VON_NOT_THE_SYSTEM) exitWith {};
        {
            [_x] call FUNC(ensureChannel);
        } forEach FIXED_KEYS;
        [] call FUNC(countChannels);
        // The self test's T4 reaches FUNC(testChannel) by remoteExec, which
        // checks the sender - no CBA event (review S7).
    }] call CBA_fnc_addEventHandler;
};

// CLIENT: Side and Command voice off, Global voice for admins only, the
// cut-offs - checked every second (an admin logs in). Once the mission
// display is up: the VON toggle blocked, Push To Talk and VON volume checked.
if (hasInterface) then {
    [QEGVAR(voice,systemReady), {
        if (VON_NOT_THE_SYSTEM) exitWith {};
        [FUNC(channels), CHANNELS_TICK_S] call CBA_fnc_addPerFrameHandler;
        [{!isNull (findDisplay DISPLAY_MISSION)}, {[] call FUNC(warn)}] call CBA_fnc_waitUntilAndExecute;
        // The self test's T4 answers reach FUNC(testResult) by remoteExec
        // from the server - no CBA event (review R1).

        // THE TALK KEYS, THE OPEN CHANNEL TOGGLE AND THE VOLUME KEYS (user,
        // 2026-10-24). After init, because CBA_fnc_addKeybind wants the display.
        #include "initKeybinds.inc.sqf"

        // The mic's channel follows the net switch, a call starting or ending, and
        // a short tick, so a call that connects is picked up with no key held.
        {
            [_x, {[] call FUNC(applyOpen)}] call CBA_fnc_addEventHandler;
        } forEach [QEGVAR(voice,netsChanged), QEGVAR(voice,callState), QEGVAR(voice,callRing)];
        // Voice activation only: under push to talk the channel is set on the net
        // switch and the keys, and the engine's own channel key stays the player's.
        [{if (GVAR(vad)) then {[] call FUNC(applyOpen)}}, OPEN_TICK_S, []] call CBA_fnc_addPerFrameHandler;
    }] call CBA_fnc_addEventHandler;
};
