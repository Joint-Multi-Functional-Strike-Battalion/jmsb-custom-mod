#include "script_component.hpp"
/*
 * Author: JMSB
 * Raises a task condition event (a name listed in a CfgTasks class's
 * conditionEvents* arrays): every task waiting on it counts it once.
 *
 * The server's own calls pass. On a client this goes to the server by
 * remoteExec, where only an admin by the server's records passes (review R1:
 * the conditions were CBA events, which any client could raise to complete
 * or show any task). A mission script that raises a condition from a
 * player's machine asks its own server function, which checks the player,
 * and that function calls this.
 *
 * Arguments:
 * 0: Event name <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["intelFound"] call jmfsb_tasks_fnc_raise
 *
 * Public: Yes
 */

params [["_event", "", [""]]];

if (_event isEqualTo "") exitWith {};
if (!isServer) exitWith {
    [_event] remoteExecCall [QFUNC(raise), SERVER_OWNER];
};
if !([] call EFUNC(common,senderIsAdmin)) exitWith {
    WARNING_2("raise '%1' refused - machine %2 is not an admin",_event,remoteExecutedOwner);
};

private _hooks = localNamespace getVariable [QGVAR(hooks), createHashMap];
private _list = _hooks getOrDefault [toLower _event, []];
// Each hook runs once, as the CBA handlers it replaced removed themselves.
_hooks deleteAt (toLower _event);

{
    _x params ["_code", "_args"];
    [_args] call _code;
} forEach _list;
