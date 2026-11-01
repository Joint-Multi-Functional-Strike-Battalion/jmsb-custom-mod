#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the light to every man of a run - the word, and whether he may
 * exit himself from now (FUNC(light) by remoteExec, where each is local;
 * review S7) - and the run's
 * phase published on the leader for his page (QGVAR(run): phase, pass,
 * passes; [] when the run is over).
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

(_st get "leader") setVariable [QGVAR(run), [_st get "phase", (_st get "pass") + 1, _st get "passes"], true];
