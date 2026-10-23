#include "script_component.hpp"
/*
 * Author: JMSB
 * CALL BACK: asks the server to hold a callback between the local player and
 * a unit. When both reach each other on DATA and a call slot is free, both
 * phones ring. Expires after the callback expiry time; one per pair, a few
 * per player; waits while either is in a call, held while either is on
 * EMCON 3.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit] call jmfsb_voice_fnc_callBack
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (!GVAR(active)) exitWith {};
if (isNull _unit || isNull player) exitWith {};
[QGVAR(srvCallback), [player, _unit]] call CBA_fnc_serverEvent;
