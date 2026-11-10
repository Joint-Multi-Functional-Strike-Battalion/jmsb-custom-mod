#include "script_component.hpp"
/*
 * Author: YonV
 * The flight control hands a helicopter back to the AI (FUNC(heliTake),
 * FUNC(heliFrame)): the frame handler is stopped and the pilot's path given
 * back - unless it is down on the ground, where it keeps none until the next
 * order (FUNC(heliOrder)), so it stays put. One RPT line. Nothing to do when
 * the control does not hold it.
 *
 * Arguments:
 * 0: The helicopter <OBJECT>
 * 1: Why, for the RPT <STRING> (optional, default "")
 *
 * Return Value:
 * Was held <BOOL>
 *
 * Example:
 * [_veh, "a new order"] call jmfsb_support_air_fnc_heliRelease
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_why", "", [""]]];

private _st = _veh getVariable [QGVAR(flight), createHashMap];
if (count _st isEqualTo 0) exitWith {false};

private _handle = _veh getVariable [QGVAR(flightPfh), -1];
if (_handle >= 0) then {[_handle] call CBA_fnc_removePerFrameHandler};
_veh setVariable [QGVAR(flightPfh), -1];
_veh setVariable [QGVAR(flight), nil];

private _down = (_st get "phase") isEqualTo HELI_PHASE_DOWN;
private _pilot = driver _veh;
if (!_down && !isNull _pilot) then {
    _pilot enableAI "PATH";
    _pilot doFollow (leader _pilot);
};

private _where = ["in the air", "on the ground"] select _down;
private _held = round (CBA_missionTime - (_st get "took"));
INFO_5("heliRelease: '%1' hands the airframe back at %2 - %3 after %4 s, %5",typeOf _veh,mapGridPosition _veh,_why,_held,_where);
true
