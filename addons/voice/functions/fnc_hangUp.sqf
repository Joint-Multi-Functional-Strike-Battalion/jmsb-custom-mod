#include "script_component.hpp"
/*
 * Author: JMSB
 * The local player leaves a call (F4), or stops a dial still ringing out.
 * The call ends when one person is left.
 *
 * Arguments:
 * 0: Call id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_callId] call jmfsb_voice_fnc_hangUp
 *
 * Public: Yes
 */

params [["_callId", "", [""]]];

if (!GVAR(active)) exitWith {};
if (_callId isEqualTo "" || isNull player) exitWith {};
[QGVAR(srvLeave), [_callId, player]] call CBA_fnc_serverEvent;
