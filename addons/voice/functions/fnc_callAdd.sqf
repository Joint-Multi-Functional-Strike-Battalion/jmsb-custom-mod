#include "script_component.hpp"
/*
 * Author: JMSB
 * Adds people to a call the local player is in (+ ADD, group adds, F2 quick
 * add). They ring until they accept. People out of reach on DATA or busy are
 * skipped (and he is told); the adds stop at 8 in the call.
 *
 * Arguments:
 * 0: Call id <STRING>
 * 1: Units <ARRAY of OBJECTs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_callId, [_unit]] call jmfsb_voice_fnc_callAdd
 *
 * Public: Yes
 */

params [["_callId", "", [""]], ["_units", [], [[]]]];

if (!GVAR(active)) exitWith {};
if (_callId isEqualTo "" || isNull player) exitWith {};
[QGVAR(srvAdd), [_callId, _units, player]] call CBA_fnc_serverEvent;
