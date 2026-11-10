#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the men of a run still aboard its aircraft - alive, in it or fixed
 * to its hull standing in the bay.
 *
 * Arguments:
 * 0: The run <HASHMAP>
 *
 * Return Value:
 * The men aboard, in stick order <ARRAY of OBJECTs>
 *
 * Example:
 * private _aboard = [_st] call jmfsb_jumpmaster_fnc_aboard
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]]];

private _veh = _st getOrDefault ["veh", objNull];
if (isNull _veh) exitWith {[]};

(_st getOrDefault ["jumpers", []]) select {alive _x && {vehicle _x isEqualTo _veh || {attachedTo _x isEqualTo _veh}}}
