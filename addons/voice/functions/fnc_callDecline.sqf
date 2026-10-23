#include "script_component.hpp"
/*
 * Author: JMSB
 * Declines a call ringing for the local player (F4). The caller is told.
 *
 * Arguments:
 * 0: Call id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_callId] call jmfsb_voice_fnc_callDecline
 *
 * Public: Yes
 */

params [["_callId", "", [""]]];

if (!GVAR(active)) exitWith {};
if (_callId isEqualTo "" || isNull player) exitWith {};
[QGVAR(srvAnswer), [_callId, player, false]] call CBA_fnc_serverEvent;
