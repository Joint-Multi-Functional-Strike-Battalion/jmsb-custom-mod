#include "script_component.hpp"
/*
 * Author: JMSB
 * Makes an aircraft on the map THE asset of a module that flies a synced
 * aircraft: the module's own airframe from here on, its loss counted on the
 * server. Called for the aircraft synced in Eden (FUNC(register)) and for
 * every replacement built on its stand (FUNC(respawn)).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh] call jmfsb_support_air_fnc_adopt
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]]];

if (isNull _logic || {isNull _veh}) exitWith {};

_logic setVariable [QGVAR(synced), _veh, true];
_logic setVariable [QGVAR(vehicle), _veh, true];
_veh setVariable [QGVAR(owner), _logic, true];

// A replacement transport that may fast-rope carries ACE's rope item, as the
// first one did (FUNC(stockRopes) - a no-op for anything else, and for the
// first adoption, which comes before the module knows its tasks).
[_logic, _veh] call FUNC(stockRopes);

// MPKilled, counted on the server: Killed fires only where the aircraft is
// local, and a player flying it moves it to his client.
_veh addMPEventHandler ["MPKilled", {
    params ["_veh", "_killer"];
    if (!isServer) exitWith {};
    [_veh getVariable [QGVAR(owner), objNull], _veh, _killer] call FUNC(lost);
}];
