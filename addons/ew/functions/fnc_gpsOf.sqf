#include "script_component.hpp"
/*
 * Author: JMSB
 * Any man's GPS as the network carries it - what a BFT dot of him is drawn
 * from. The local player is FUNC(gpsState) (his slice, metre-exact, and his
 * own denial). Anyone else is what the server hung on him: his spoof state
 * and offset (QGVAR(gps), set by FUNC(spoof) on change, on a 10 m grid) and
 * the denial his own client reported (QGVAR(gpsDenied), FUNC(gpsWatch)).
 *
 * States as FUNC(gpsState): GOOD, SPOOFED, SUSPECT, NO FIX.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * [state, [dx, dy] m, GPS position ASL] <ARRAY>
 *
 * Example:
 * ([_member] call jmfsb_ew_fnc_gpsOf) params ["_state", "_offset"]
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {[GPS_NOFIX, [0, 0], [0, 0, 0]]};
if (hasInterface && _unit isEqualTo player) exitWith {[] call FUNC(gpsState)};

(_unit getVariable [QGVAR(gps), [GPS_GOOD, [0, 0]]]) params [["_state", GPS_GOOD], ["_offset", [0, 0]]];
if (_unit getVariable [QGVAR(gpsDenied), false]) then {_state = GPS_NOFIX};
[_state, _offset, (getPosASL _unit) vectorAdd [_offset select 0, _offset select 1, 0]]
