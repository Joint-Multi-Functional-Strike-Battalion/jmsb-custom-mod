#include "script_component.hpp"
/*
 * Author: JMSB
 * The local player's calls. members are the people in the call (not those
 * still ringing); startedAt is CBA_missionTime.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[callId, state "ringing"|"live"|"outgoing", members, priority, startedAt, owner], ...] <ARRAY>
 *   owner is who started the call (or who it passed to) - only he invites.
 *
 * Example:
 * [] call jmfsb_voice_fnc_calls
 *
 * Public: Yes
 */

if (!GVAR(active)) exitWith {[]};
if (isNull player) exitWith {[]};

(GVAR(callTable) select {player in (_x select 3) || player in (_x select 4)}) apply {
    _x params ["_id", "", ["_from", objNull], "_members", "", "_priority", "_startedAt", "", "", ["_owner", objNull]];
    if (isNull _owner) then {_owner = _from};
    [_id, (GVAR(myCalls) getOrDefault [_id, [STATE_RINGING]]) select 0, +_members, _priority, _startedAt, _owner]
}
