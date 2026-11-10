#include "script_component.hpp"
/*
 * Author: YonV
 * A run is tasked: the side is told it is inbound - what the man on the radio
 * hears. The run is flown on the server and every word of it is said here, so
 * a strike is not a thing that silently happens somewhere.
 *
 * Sent by the server (FUNC(request)) by remoteExec to the module's side and
 * taken only from the server (review S7: it was a global CBA event, so any
 * client could put a false "inbound" on every screen of a side).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target position <ARRAY>
 * 2: Seconds until it is airborne <NUMBER>
 * 3: Mode, "strike" or "loiter" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _pos, 30, "strike"] remoteExecCall ["jmfsb_cas_fnc_inbound", west]
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_pos", [], [[]]], ["_delay", 0, [0]], ["_mode", MODE_STRIKE, [""]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("inbound: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (isNull _logic) exitWith {};
if ((_logic getVariable [QGVAR(side), sideUnknown]) isNotEqualTo (side group player)) exitWith {};

["SUPPORT", format [
    "%1 %2 %3, %4 sec",
    _logic getVariable [QGVAR(callsign), "CAS"],
    ["inbound to", "moving to hold over"] select (_mode isEqualTo MODE_LOITER),
    mapGridPosition _pos,
    round _delay
], "high"] call EFUNC(messaging,notify);
