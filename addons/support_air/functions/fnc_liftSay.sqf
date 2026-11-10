#include "script_component.hpp"
/*
 * Author: YonV
 * Server: one line a transport says in its thread as the asset (2026-11-09) -
 * a WILCO to a MOVE or a FRAGO, HOLDING, GOING AROUND - filed as a free-text
 * card under its call sign (EFUNC(support,fileCard)). A state card would say
 * nothing in a thread already past it (EFUNC(support,state) only goes
 * forward), and these are said mid-task.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Thread id <STRING>
 * 2: The line <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "T0042", "HOLDING AT 045 782"] call jmfsb_support_air_fnc_liftSay
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_threadId", "", [""]], ["_line", "", [""]]];

if (!isServer || {isNull _logic} || _threadId isEqualTo "" || _line isEqualTo "") exitWith {};

[
    format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
    _threadId,
    CARD_FREETEXT,
    [[CARD_TEXT_KEY, _line]],
    _logic getVariable [QGVAR(callsign), "AIR"]
] call EFUNC(support,fileCard);
