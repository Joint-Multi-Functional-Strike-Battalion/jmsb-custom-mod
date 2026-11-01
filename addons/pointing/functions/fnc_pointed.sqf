#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: a crewmate points (FUNC(srvPoint)); DUI's radar shows the finger.
 * Taken only from the server (review R1).
 *
 * Arguments:
 * 0: Who points <OBJECT>
 * 1: Pointed position ASL <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, _posASL] remoteExecCall ["jmfsb_pointing_fnc_pointed", crew vehicle _unit]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_posASL", [], [[]], 3]];

if (!hasInterface || {isNull _unit} || {_posASL isEqualTo []}) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("pointed: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if !(IS_MOD_LOADED(diwako_dui_radar)) exitWith {};

[_unit, _posASL] call diwako_dui_radar_fnc_incomingFinger;
