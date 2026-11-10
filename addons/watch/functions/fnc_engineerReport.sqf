#include "script_component.hpp"
/*
 * Author: YonV
 * The engineer profile's REPORT (decided 2026-11-07: the UXO/IED 9-line). A
 * mine or explosive opens the 9-line card filled with the time, the grid,
 * the reporter and the ordnance; a vehicle opens the DEFREP card. The rest -
 * contamination, resources threatened, impact, protective measures, priority -
 * is the engineer's call; sending is his press.
 *
 * Arguments:
 * 0: Target <OBJECT>
 *
 * Return Value:
 * Opened <BOOL>
 *
 * Example:
 * [_obj] call jmfsb_watch_fnc_engineerReport
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]]];

if (isNull _obj || {isNil QEFUNC(tacpad,composeOpen)}) exitWith {false};

if !(_obj in allMines) exitWith {["", DEFREP_TEMPLATE, false, "", []] call EFUNC(tacpad,composeOpen)};

_obj setVariable [QGVAR(reportedAt), serverTime];
["", UXO_TEMPLATE, false, UXO_NET, [
    ["1.A", [dayTime, "HH:MM"] call BIS_fnc_timeToString],
    ["2.A", format ["%1, %2", groupId group player, mapGridPosition _obj]],
    ["3.A", name player],
    ["4.A", format ["placed - %1", [_obj, "threat"] call FUNC(contactName)]]
]] call EFUNC(tacpad,composeOpen)
