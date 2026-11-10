#include "script_component.hpp"
/*
 * Author: YonV
 * The action key near a measure (design c2_app.reports): within
 * REPORT_WINDOW seconds of a reportable event ("CROSSED PL BLUE", "ON OBJ RED",
 * "AT RP 1"...), numpad 9 sends it to REPORT_NET as one line, with the grid.
 * Called by jmfsb_watch when the action key has no target to act on.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Sent <BOOL>
 *
 * Example:
 * [] call jmfsb_c2_fnc_report
 *
 * Public: No
 */

GVAR(event) params [["_text", ""], ["_at", -1]];
if (_text isEqualTo "" || {(CBA_missionTime - _at) > REPORT_WINDOW} || {isNil QEFUNC(messaging,submit)}) exitWith {false};

private _line = format ["%1 - %2 %3", _text, groupId group player, mapGridPosition player];
([REPORT_TEMPLATE, [[REPORT_FIELD, _line]], [REPORT_NET], "", "", [], getPosATL player] call EFUNC(messaging,submit)) params ["_sent", "_why"];
[NOTE_TITLE, [format ["Not sent: %1", _why], format ["Reported: %1", _text]] select _sent, [NOTE_WARN, NOTE_COLOUR] select _sent] call EFUNC(notify,notify);
if (_sent) then {GVAR(event) = []};
_sent
