#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the light to every man of a run - the word on his notify rail, and
 * whether he may exit himself from now (FUNC(light) by remoteExec, where each
 * is local; review S7). The leader hears the same in the run's thread
 * (FUNC(threadCard), 2026-11-02).
 *
 * Arguments:
 * 0: The run <HASHMAP>
 * 1: What is said <STRING>
 * 2: May exit himself from now <BOOL>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_st, "GREEN LIGHT. GO.", true] call jmfsb_jumpmaster_fnc_srvLight
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]], ["_text", "", [""]], ["_mayJump", false, [false]]];

{
    [_x, _text, _mayJump] remoteExecCall [QFUNC(light), _x];
} forEach ((_st get "jumpers") select {alive _x});
