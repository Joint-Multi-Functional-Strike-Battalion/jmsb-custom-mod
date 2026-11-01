#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: attendance, asked for by the #attendance chat command, the Zeus
 * "Take attendance" module or Call Endex, by remoteExec. It was a CBA server
 * event naming its own requester (review S7), so any client could read the
 * list or have it sent to someone else. Here the sender must be an admin by
 * the server's records or hold a curator module; the list is read from the
 * server's connection log and sent back to his machine only
 * (FUNC(attendance)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] remoteExecCall ["jmfsb_init_fnc_srvAttendance", 2]
 *
 * Public: No
 */

if (!isServer) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_unit"];
if (isNull (getAssignedCuratorLogic _unit) && {!([] call EFUNC(common,senderIsAdmin))}) exitWith {
    WARNING_2("Attendance","refused - machine %1 (%2) is neither a Zeus nor an admin",_owner,_unit);
};

private _names = call EFUNC(systems,getAttendance);
[_names] remoteExecCall [QFUNC(attendance), _owner];
