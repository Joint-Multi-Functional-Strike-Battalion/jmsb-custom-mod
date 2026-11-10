#include "script_component.hpp"
/*
 * Author: YonV
 * An AI passenger out of a transport, on the machine that owns him:
 * unassignVehicle and moveOut only take there, and a player's AI squadmates
 * live on his client. The server decides (FUNC(transportStep)) and sends it
 * by remoteExec to the unit; only the server's word is taken (review S7) -
 * this was a CBA event any client could raise to throw anyone out.
 *
 * Arguments:
 * 0: The passenger <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit] remoteExecCall ["jmfsb_support_air_fnc_putOut", _unit]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("putOut: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (!local _unit || {isPlayer _unit}) exitWith {};

unassignVehicle _unit;
moveOut _unit;
