#include "script_component.hpp"
/*
 * Author: YonV
 * The rappel's ropes (user, 2026-11-08: "a simplex like repel"): one hanging
 * from each side of the airframe, RAPPEL_SIDE m out from its centre and
 * RAPPEL_ROPE_LENGTH m long, for the men to slide down (FUNC(rappel)) - or
 * taken in again. Any airframe: no FRIES, no ACE. Server.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: Out (true) or in (false) <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_veh, true] call jmfsb_support_air_fnc_rappelRopes
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_out", true, [true]]];

{ropeDestroy _x} forEach ((_veh getVariable [QGVAR(rappelRopes), []]) select {!isNull _x});
_veh setVariable [QGVAR(rappelRopes), nil, true];
if (!_out || {!alive _veh}) exitWith {};

private _ropes = [-RAPPEL_SIDE, RAPPEL_SIDE] apply {ropeCreate [_veh, [_x, 0, 0], RAPPEL_ROPE_LENGTH]};
_veh setVariable [QGVAR(rappelRopes), _ropes select {!isNull _x}, true];
