#include "script_component.hpp"
/*
 * Author: JMSB
 * THE SEAT IS GIVEN BACK BEFORE THE AIRFRAME GOES. Recalled, shot down or out
 * of patience, FUNC(egress) says so here first - when the run ends, and again
 * before the airframe is deleted off the map edge - because a controller left
 * in the turret of a vehicle that is deleted under him is a black screen he
 * cannot get out of. Dropping the link gives the seat back first. Only the
 * machine linked to this aircraft does anything.
 *
 * Sent by the server (FUNC(egress)) by remoteExec and taken only from the
 * server (review S7: it was a global CBA event, so any client could name any
 * drone and drop another player's link to it).
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_veh] remoteExecCall ["jmfsb_cas_fnc_offStation", 0]
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("offStation: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (isNull _veh || {isNil QEFUNC(devices,uavControl)}) exitWith {};
if ((["linked"] call EFUNC(devices,uavControl)) isNotEqualTo _veh) exitWith {};

["unlink"] call EFUNC(devices,uavControl);
