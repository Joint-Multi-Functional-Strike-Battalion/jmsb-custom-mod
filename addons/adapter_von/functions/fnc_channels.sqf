#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, every CHANNELS_TICK_S: who may TALK on which VON channel
 * (enableChannel, voice only - text chat is left as the mission set it):
 * - Global: logged-in admins (and the host), and a C2 member (TL, ATL, HHC) who
 *   switched it on with the tablet's GLOBAL button (FUNC(global), jmfsb_voice_fnc_canGlobal);
 * - Side and Command: nobody (Side reaches the whole side with no range and
 *   would bypass the mesh, jamming and keys; C2 replaces Command);
 * - Group and our custom channels: on, off from radio silence (cut-off
 *   level 1, fnc_block);
 * - Vehicle: the mission's, closed from level 2 (unconscious); Direct: the
 *   mission's, closed at level 3 (dead, out of air). What they were is kept
 *   and put back when the level falls.
 * Listening is not touched here: membership is the server's, volume the mesh's.
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY> (default: [])
 * 1: PFH handle <NUMBER> (default: -1)
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adapter_von_fnc_channels
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

if (!hasInterface) exitWith {};

private _admin = isServer || {(call BIS_fnc_admin) > ADMIN_NONE};
// A man who leaves C2 mid-mission drops off Global on the next tick.
private _global = GVAR(globalOn) && {[player] call EFUNC(voice,canGlobal)};
if (GVAR(globalOn) && !_global) then {[{[false] call EFUNC(voice,global)}] call CBA_fnc_execNextFrame};
private _radio = GVAR(level) < BLOCK_SILENCE;
private _want = [[CH_GLOBAL, _admin || _global], [CH_SIDE, false], [CH_COMMAND, false], [CH_GROUP, _radio]];
{
    _want pushBack [CUSTOM_BASE + (_x select 1), _radio];
} forEach GVAR(channelMap);

{
    _x params ["_ch", "_voice"];
    (channelEnabled _ch) params ["_chat", "_voiceNow"];
    if (_voiceNow isNotEqualTo _voice) then {_ch enableChannel [_chat, _voice]};
} forEach _want;

// Vehicle and Direct: closed by the cut-offs only, then put back
{
    _x params ["_ch", "_cutAt"];
    (channelEnabled _ch) params ["_chat", "_voiceNow"];
    if (GVAR(level) >= _cutAt) then {
        if !(_ch in GVAR(saved)) then {GVAR(saved) set [_ch, _voiceNow]};
        if (_voiceNow) then {_ch enableChannel [_chat, false]};
    } else {
        if (_ch in GVAR(saved)) then {
            private _was = GVAR(saved) deleteAt _ch;
            if (_was isNotEqualTo _voiceNow) then {_ch enableChannel [_chat, _was]};
        };
    };
} forEach CUT_CHANNELS;
