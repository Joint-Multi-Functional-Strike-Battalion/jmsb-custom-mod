#include "script_component.hpp"
/*
 * Author: YonV
 * Server: runs code once, the next time a task condition event is raised
 * with FUNC(raise). The task conditions listened on CBA events, and a CBA
 * event carries no sender: any client could raise one and complete or show
 * any mission task (review R1). The hooks live in localNamespace, which is
 * not networked. Local calls only.
 *
 * Arguments:
 * 0: Event name (case does not matter) <STRING>
 * 1: Code, run with [arguments] <CODE>
 * 2: Arguments <ANY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["intelFound", {params ["_args"]; systemChat str _args}, 1] call jmfsb_tasks_fnc_onEvent
 *
 * Public: No
 */

params [["_event", "", [""]], ["_code", {}, [{}]], ["_args", []]];

if (!isServer || {isRemoteExecuted} || _event isEqualTo "") exitWith {};

private _hooks = localNamespace getVariable [QGVAR(hooks), createHashMap];
private _key = toLower _event;
private _list = _hooks getOrDefault [_key, []];
_list pushBack [_code, _args];
_hooks set [_key, _list];
localNamespace setVariable [QGVAR(hooks), _hooks];
