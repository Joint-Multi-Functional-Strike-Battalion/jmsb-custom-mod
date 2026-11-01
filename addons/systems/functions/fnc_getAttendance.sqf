#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A -- Tinkered with by YonV tinkered with by YonV
 * Prints the names of the players that have connected to this machine's RPT.
 * The connection log lives on the server only, so the names are read there
 * and handed to the asking client, which prints them again in its own RPT.
 *
 * Arguments:
 * 0: Names to print (default: read from the server's connection log) <ARRAY of STRINGs>
 *
 * Return Value:
 * Names printed <ARRAY of STRINGs>
 *
 * Example:
 * call jmfsb_systems_fnc_getAttendance
 *
 * Public: No
 */

params [["_names", nil, [[]]]];

if (isNil "_names") then {
    // keyed by UID; the name is in each entry
    private _playerLog = missionNamespace getVariable [QEGVAR(log,players), createHashMap];
    _names = [];
    {
        _names pushBack (_y getOrDefault ["name", _x]);
    } forEach _playerLog;
};

// Rpt
["=================================================== START", "Attendance"] call EFUNC(diag,info);
[format ["Attendance (Entries: %1)", count _names], "Attendance"] call EFUNC(diag,info);
{
    [_x, "Attendance", false, false] call EFUNC(diag,info);
} forEach _names;

["=================================================== END", "Attendance"] call EFUNC(diag,info);

_names
