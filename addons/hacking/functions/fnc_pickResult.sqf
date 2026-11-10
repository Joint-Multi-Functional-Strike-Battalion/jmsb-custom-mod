#include "script_component.hpp"
/*
 * Author: YonV
 * Client: the one line a hack's product ends on ("Intel plotted - check your
 * map.", a package's files), shown to the side that earned it. Sent by the
 * server (FUNC(serverPick), FUNC(productPackage)) by remoteExec and taken
 * only from the server (review S7): a client cannot put a false result on
 * his side's screens.
 *
 * Arguments:
 * 0: The line <STRING>
 * 1: The side that earned it <SIDE>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["Nothing to report.", west] remoteExecCall ["jmfsb_hacking_fnc_pickResult", 0]
 *
 * Public: No
 */

params [["_msg", "", [""]], ["_side", sideUnknown, [sideUnknown]]];

if (!hasInterface || {!([] call EFUNC(common,fromServer))}) exitWith {};
if (side group ACE_player isNotEqualTo _side) exitWith {};

["Hack", _msg, HACK_RESULT_COLOR] call EFUNC(notify,notify);
