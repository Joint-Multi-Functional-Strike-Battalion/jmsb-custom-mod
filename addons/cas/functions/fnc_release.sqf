#include "script_component.hpp"
/*
 * Author: YonV
 * The aircraft is in hot: its terminal guidance is read back to the side, so
 * the JTAC knows whether his spot or smoke was the thing used.
 *
 * Sent by the server (FUNC(request)) by remoteExec to the module's side and
 * taken only from the server (review S7: it was a global CBA event, so any
 * client could put a false "in hot" on every screen of a side).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Aim point <ARRAY>
 * 2: What guided it, "laser", "smoke" or "grid" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _aim, "laser"] remoteExecCall ["jmfsb_cas_fnc_release", west]
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_aim", [], [[]]], ["_by", "grid", [""]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("release: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (isNull _logic) exitWith {};
if ((_logic getVariable [QGVAR(side), sideUnknown]) isNotEqualTo (side group player)) exitWith {};

// The word for what guided it, in the JTAC's own vocabulary - "spot" is a
// laser, and a man who lit one wants to know it was the thing used.
private _word = switch (_by) do {
    case "laser": {"on your spot"};
    case "smoke": {"on your smoke"};
    default {"on the grid"};
};

["SUPPORT", format [
    "%1 in hot %2 - %3",
    _logic getVariable [QGVAR(callsign), "CAS"],
    _word,
    mapGridPosition _aim
], "high"] call EFUNC(messaging,notify);
