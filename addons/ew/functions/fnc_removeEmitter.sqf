#include "script_component.hpp"
/*
 * Author: YonV
 * Server: forgets an emitter FUNC(addEmitter) registered.
 *
 * Arguments:
 * 0: Emitter id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ew_ext_1"] call jmfsb_ew_fnc_removeEmitter
 *
 * Public: Yes
 */

params [["_id", "", [""]]];

if (!isServer) exitWith {};
GVAR(external) deleteAt _id;
