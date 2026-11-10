#include "script_component.hpp"
/*
 * Author: YonV
 * The server's answer to an attendance request (FUNC(srvAttendance)): the
 * names go into this machine's RPT and the player is told. Taken only from
 * the server (review S7: it was a CBA event any client could raise on every
 * machine). A host already printed it while answering.
 *
 * Arguments:
 * 0: Names <ARRAY of STRINGs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_names] remoteExecCall ["jmfsb_init_fnc_attendance", _owner]
 *
 * Public: No
 */

params [["_names", [], [[]]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("Attendance","refused - not from the server (machine %1)",remoteExecutedOwner);
};

if (!isServer) then {
    [_names] call EFUNC(systems,getAttendance);
};
["Attendance", format ["%1 attended players written to your RPT log.", count _names], NOTE_INFO] call JMFSBFUNC(notify,notify);
