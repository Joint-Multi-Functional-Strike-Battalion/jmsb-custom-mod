#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "selfTest" (jmfsb_voice_fnc_selfTest): the five "Tests to run
 * first" of docs/DESIGN_VOICE.md, as an in-game diagnostic. Every line goes
 * to the RPT with a "VON Tn" tag. T1 and T5 are immediate; T2, T3 and T4 run
 * for TEST_WINDOW_S (fnc_selfTestFrame) and log their results at the end.
 * - T1 setPlayerVoNVolume per listener per speaker: set, read back, restore.
 * - T2 enableChannel voice off still hears: Group voice off for the window.
 *   The cut-offs and radio silence rely on it (a script-only VON radio we
 *   reviewed keeps channel voice off except while the key is held, and its
 *   listeners hear): expected to pass.
 * - T3 getPlayerChannel speed: PTT press to own channel change, in ms and
 *   frames; every remote change seen; the speakers' pushed key events
 *   received. getPlayerChannel is now only the fallback.
 * - T4 add / remove delay on custom channels: the server takes him off C2
 *   and puts him back; when each shows on this client.
 * - T5 Vehicle channel crew only: what script can see and set. Gating it
 *   with enableChannel on get in / get out works, but opens it for everyone
 *   aboard, passengers too; crew-only stays by volume. His current channel
 *   is put back after the setCurrentChannel probe.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adapter_von_fnc_selfTest
 *
 * Public: No
 */

if (!hasInterface || isNull player) exitWith {};
if (count GVAR(test) > 0) exitWith {INFO("VON self test already running")};

// T1
private _others = allPlayers select {_x isKindOf "CAManBase" && _x isNotEqualTo player};
if (_others isEqualTo []) then {
    INFO("VON T1 setPlayerVoNVolume: SKIPPED, needs a second player");
};
{
    private _was = getPlayerVoNVolume _x;
    _x setPlayerVoNVolume TEST_VOLUME;
    private _read = getPlayerVoNVolume _x;
    _x setPlayerVoNVolume _was;
    INFO_4("VON T1 setPlayerVoNVolume %1: was %2, set %3, read %4 (PASS when read = set). By ear: have him talk on Group, C2 and Direct while one listener lowers him",name _x,_was,TEST_VOLUME,_read);
} forEach _others;

// T2
(channelEnabled CH_GROUP) params ["_chat", "_voice"];
CH_GROUP enableChannel [_chat, false];
INFO_3("VON T2 enableChannel: Group voice off for %1 s (chat %2, voice was %3). Have a group member talk on Group now: if you hear him, listen-only works (the cut-offs rely on it)",TEST_WINDOW_S,_chat,_voice);

// T3
INFO_1("VON T3 getPlayerChannel: press your push-to-talk a few times within %1 s; others talking are counted, both by getPlayerChannel (now the fallback) and by their pushed key events",TEST_WINDOW_S);

// T4
private _c2 = GVAR(channelMap) findIf {(_x select 0) isEqualTo KEY_C2};
private _c2Id = if (_c2 < 0) then {CUSTOM_NONE} else {(GVAR(channelMap) select _c2) select 1};
if (_c2Id > CUSTOM_NONE) then {
    [QGVAR(testChannel), [player]] call CBA_fnc_serverEvent;
    INFO_2("VON T4 custom channel: server takes you off C2 (custom %1) and back on after %2 s",_c2Id,TEST_READD_S);
} else {
    INFO("VON T4 custom channel: SKIPPED, no C2 channel published");
};

// T5
private _vehicle = vehicle player;
private _crew = [player] call EFUNC(voice,crewOf);
private _current = currentChannel;
private _took = setCurrentChannel CH_VEHICLE;
setCurrentChannel _current;
INFO_4("VON T5 Vehicle channel: in vehicle %1, crew %2, channelEnabled 4 = %3, setCurrentChannel 4 = %4 (current channel put back)",_vehicle isNotEqualTo player,!isNull _crew,channelEnabled CH_VEHICLE,_took);
INFO("VON T5 Vehicle channel: no script command sets its members. enableChannel on get in / get out gates it, but opens it for everyone aboard, passengers too; so passengers are muted by volume (fnc_applyVolume), and the cut-offs close it while unconscious. By ear: crew talks on Vehicle, a passenger listens");

GVAR(test) = createHashMapFromArray [
    ["start", diag_tickTime],
    ["group", [_chat, _voice]],
    ["c2", _c2Id],
    ["pttAt", -1],
    ["pttFrame", -1],
    ["ownCh", CH_NONE],
    ["latency", []],
    ["remote", 0],
    ["keyed", 0],
    ["heardGroup", []],
    ["member", []]
];
[FUNC(selfTestFrame), 0, []] call CBA_fnc_addPerFrameHandler;
