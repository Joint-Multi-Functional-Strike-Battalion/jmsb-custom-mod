#include "script_component.hpp"
/*
 * Author: JMSB
 * Accepts a call ringing for the local player (F1). It becomes his active net
 * when it goes live.
 *
 * Arguments:
 * 0: Call id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_callId] call jmfsb_voice_fnc_callAccept
 *
 * Public: Yes
 */

params [["_callId", "", [""]]];

if (!GVAR(active)) exitWith {};
if (_callId isEqualTo "" || isNull player) exitWith {};
[QGVAR(srvAnswer), [_callId, player, true]] call CBA_fnc_serverEvent;
