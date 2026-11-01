#include "script_component.hpp"
/*
 * Author: JMSB
 * The net a PTT key talks on (the MPU5's Dual PTT, four keys here). PTT 1 is
 * the active net. PTT 2-4 are the net the RADIO app set for that key
 * (FUNC(pttKey)), or with none set the net in that place of his list
 * (FUNC(netState): PTT 2 = net 2). A set net he is no longer on falls back to
 * that place too. A key set OFF talks on nothing.
 *
 * Arguments:
 * 0: PTT key 1..4 <NUMBER>
 *
 * Return Value:
 * Net id, "" when the key talks on nothing <STRING>
 *
 * Example:
 * [2] call jmfsb_voice_fnc_pttNet
 *
 * Public: Yes
 */

params [["_key", PTT_ACTIVE, [0]]];

if (_key < PTT_ACTIVE || _key > PTT_KEYS) exitWith {""};
if (_key isEqualTo PTT_ACTIVE) exitWith {[] call FUNC(activeNet)};

private _set = GVAR(pttNets) getOrDefault [_key, ""];
if (_set isEqualTo PTT_OFF) exitWith {""};

private _nets = ([] call FUNC(netState)) apply {_x select 0};
if (_set in _nets) exitWith {_set};
_nets param [_key - 1, ""]
