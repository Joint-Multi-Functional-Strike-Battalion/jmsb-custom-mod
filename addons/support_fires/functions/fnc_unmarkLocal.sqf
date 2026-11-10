#include "script_component.hpp"
/*
 * Author: YonV
 * Takes a mission's target markers off this map. Sent by the server
 * (FUNC(unmark)) by remoteExec and taken only from it (review S7).
 *
 * Arguments:
 * 0: The asset's id <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [0] remoteExecCall ["jmfsb_support_fires_fnc_unmarkLocal", 0]
 *
 * Public: No
 */

params [["_id", -1, [0]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("unmarkLocal: refused - not from the server (machine %1)",remoteExecutedOwner);
};

deleteMarkerLocal format ["%1_mark_%2", QUOTE(ADDON), _id];
deleteMarkerLocal format ["%1_area_%2", QUOTE(ADDON), _id];
