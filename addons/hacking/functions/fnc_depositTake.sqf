#include "script_component.hpp"
/*
 * Author: JMSB
 * The items the server banked come out of the man's inventory, on the machine
 * where he is local (FUNC(srvDeposit)). Taken only from the server (review
 * S7): a client cannot empty another man's pockets by asking.
 *
 * Arguments:
 * 0: The man who banked <OBJECT>
 * 1: The items banked <ARRAY of STRINGs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, ["jmfsb_hacking_intelItem"]] remoteExecCall ["jmfsb_hacking_fnc_depositTake", _owner]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_items", [], [[]]]];

if !([] call EFUNC(common,fromServer)) exitWith {};
if (isNull _unit || {!local _unit}) exitWith {};

{
    _unit removeItem _x;
} forEach (_items select {_x in INTEL_ITEMS});
