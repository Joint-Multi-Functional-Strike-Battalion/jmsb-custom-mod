#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a battery tasked by a call for fire stands down (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING step 6) - END OF MISSION from the observer, no
 * answer to its prompt for PROMPT_END s (D9), or a first salvo it could not
 * fire. The mission ends (FUNC(finish)) and the thread is CLOSED with what it
 * says; a battery laid AT MY COMMAND that never fired takes no cooldown. The
 * same for a cruise missile or loitering munition launcher (2026-11-01).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: What it says <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "END OF MISSION"] call jmfsb_support_fires_fnc_threadEnd
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_said", "", [""]]];

if (!isServer || {isNull _logic}) exitWith {};
if ((_logic getVariable [QGVAR(thread), ""]) isEqualTo "") exitWith {};

private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
INFO_2("%1 stands down - %2",_callsign,_said);

// Still laid is nothing fired - a battery's salvo or a launcher's missile
// (2026-11-01: a launcher's QGVAR(salvo) is its salvo size, not a count).
private _spent = (_logic getVariable [QGVAR(status), ""]) isNotEqualTo STATUS_LAID;
[_logic, _logic getVariable [QGVAR(token), -1], _said, _spent] call FUNC(finish);
