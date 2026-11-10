#include "script_component.hpp"
/*
 * Author: YonV
 * Server: moves the air asset's support thread (EFUNC(support,state)) under
 * the module's call sign - one line at each of the sortie's natural points:
 * launched (IN_PROGRESS), never launched (DECLINED), sortie over (CLOSED),
 * aircraft lost (CLOSED, or DECLINED when it was not yet flying the task).
 * An asset nobody filed a thread to says nothing (2026-11-01).
 *
 * WHICH THREAD (2026-11-01, DESIGN_SUPPORT_MESSAGING 1.1). The one named;
 * else every thread the sortie is answering - a strike flown from station
 * (FUNC(casJob)) and the thread the sortie was launched for (FUNC(srvThread):
 * the REQUEST ON STATION, a helicopter's strike) - so a sortie that ends
 * closes both; else, for a sortie the board launched, the asset's open thread.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: State - "IN_PROGRESS", "CLOSED", "DECLINED" <STRING>
 * 2: What the asset says, without the call sign <STRING> (optional, default "")
 * 3: The thread, "" for the sortie's own <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "DECLINED", "could not launch"] call jmfsb_support_air_fnc_threadState
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_state", "", [""]], ["_said", "", [""]], ["_threadId", "", [""]]];

if (!isServer || {isNull _logic}) exitWith {};

private _ids = [_threadId];
if (_threadId isEqualTo "") then {
    _ids = [
        (_logic getVariable [QGVAR(job), createHashMap]) getOrDefault ["thread", ""],
        _logic getVariable [QGVAR(sortieThread), ""]
    ] select {_x isNotEqualTo ""};
    if (_ids isEqualTo []) then {_ids = [""]};
};

private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];
private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
{
    [_assetId, _state, _said, _callsign, false, _x] call EFUNC(support,state);
} forEach _ids;
