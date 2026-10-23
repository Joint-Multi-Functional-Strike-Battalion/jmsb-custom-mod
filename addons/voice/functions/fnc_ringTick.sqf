#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, every RING_PERIOD_S: the ring while a call or callback rings for
 * the local player, the ringback while his own dial is still ringing out.
 *
 * Arguments:
 * 0: PFH arguments (unused) <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], -1] call jmfsb_voice_fnc_ringTick
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];

if (isNull player) exitWith {};

{
    _x params ["", "_slot", "_from", "", "_ringing", "", "", "_live"];
    if (player in _ringing) then {
        ["ring", format [CALL_FORMAT, _slot]] call FUNC(playCue);
        continue;
    };
    if (!_live && _from isEqualTo player && _ringing isNotEqualTo []) then {
        ["ringback", format [CALL_FORMAT, _slot]] call FUNC(playCue);
    };
} forEach GVAR(callTable);
