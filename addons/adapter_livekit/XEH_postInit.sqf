#include "script_component.hpp"

// SERVER: the room's name, one per mission start, for every client that joins
// (publicVariable reaches JIP too). Tokens are signed on request
// (FUNC(srvRoomToken), FUNC(srvEchoToken)) with the server's own extension.
if (isServer) then {
    GVAR(room) = format ["%1%2-%3", ROOM_PREFIX, toLower missionName, floor random ROOM_ID_MAX];
    publicVariable QGVAR(room);
    if (GVAR(version) isEqualTo "") then {
        WARNING("jmsb_voice extension not loaded on the server - it cannot sign anyone into the voice server");
    };
};

if (!hasInterface) exitWith {};

// GAME VON OFF on every channel while LiveKit carries the voice (FUNC(vonOff)):
// at once, every VON_OFF_TICK_S and on his respawn. Also on a machine left
// with no voice ("none": the server runs the voice server, this machine's
// extension did not load) - its game VON would reach players who hear only
// the voice server, and nobody would know where it came from.
[QEGVAR(voice,systemReady), {
    params [["_system", "", [""]]];
    private _server = missionNamespace getVariable [QEGVAR(voice,serverSystem), ""];
    if !(_system isEqualTo ADAPTER_ID || {_system isEqualTo SYSTEM_NONE && _server isEqualTo ADAPTER_ID}) exitWith {};
    [] call FUNC(vonOff);
    [FUNC(vonOff), VON_OFF_TICK_S] call CBA_fnc_addPerFrameHandler;
    addMissionEventHandler ["EntityRespawned", {
        params ["_unit"];
        if (_unit isEqualTo player) then {[] call FUNC(vonOff)};
    }];
}] call CBA_fnc_addEventHandler;

// Without the extension (Linux, or BattlEye without the whitelist) this
// machine has no voice server and no echo test; the voice core has fallen
// back to the game's VON for it (jmfsb_voice_fnc_selectSystem).
if (GVAR(version) isEqualTo "") exitWith {INFO("jmsb_voice extension not loaded - no voice server, no echo test; game VON is the fallback")};
GVAR(echo) = ECHO_IDLE;
INFO_1("jmsb_voice extension %1",GVAR(version));

// The extension outlives the mission: drop a session a previous one left.
["disconnect"] call FUNC(ext);

// This machine's microphones and speakers, by name, so the player can name
// his in the settings. His choice is applied by the settings' own scripts:
// at settings init and on every change (FUNC(applyDevices)).
INFO_1("voice devices (microphones, speakers): %1",(["devices"] call FUNC(ext)) select 0);

addMissionEventHandler ["ExtensionCallback", {
    params ["_name", "_function", "_data"];
    if (_name isNotEqualTo VOICE_EXT) exitWith {};
    [_function, _data] call FUNC(callback);
}];

// Leaving the mission closes the microphone and the room: scripts stop with
// the mission display, so no tick can do it.
[{!isNull findDisplay IDD_MISSION}, {
    (findDisplay IDD_MISSION) displayAddEventHandler ["Unload", {["disconnect"] call FUNC(ext)}];
}] call CBA_fnc_waitUntilAndExecute;

// THE VOICE (user, 2026-10-31: "livekit was to be the VON", "no in-game
// VON"). While LiveKit is the system chosen - the server's choice, which this
// machine has taken by jmfsb_voice_systemReady (jmfsb_voice_fnc_followServer)
// - this machine joins the
// mission's room once the server has named it (FUNC(roomJoin)), keys its mic
// from the talk keys (initKeybinds.inc.sqf, FUNC(mic)), and mixes every
// speaker by what the voice core says of him (FUNC(tick)). The mic is asked
// again on a net switch and a call's start or end, as a held key's net may
// have moved.
[QEGVAR(voice,systemReady), {
    if ((missionNamespace getVariable [QEGVAR(voice,system), ""]) isNotEqualTo ADAPTER_ID) exitWith {};
    #include "initKeybinds.inc.sqf"
    [{!isNil QGVAR(room) && {!isNull player}}, {[] call FUNC(roomJoin)}] call CBA_fnc_waitUntilAndExecute;
    GVAR(pfh) = [FUNC(tick), TICK_S] call CBA_fnc_addPerFrameHandler;
    {
        [_x, {[] call FUNC(mic)}] call CBA_fnc_addEventHandler;
    } forEach [QEGVAR(voice,netsChanged), QEGVAR(voice,callState)];
}] call CBA_fnc_addEventHandler;
