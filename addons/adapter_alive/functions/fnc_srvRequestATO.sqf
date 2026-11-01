#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a player tasks the ATO from TAC//SUPPORT (FUNC(supportTask), by
 * remoteExec). The requester is the sending machine's own live player, his
 * side is his group's, and the support tasking gate is asked again here - it
 * was a CBA event any client could raise to call any side's CAS onto any
 * position (review S7).
 *
 * Arguments:
 * 0: Target position <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_pos] remoteExecCall ["jmfsb_adapter_alive_fnc_srvRequestATO", 2]
 *
 * Public: No
 */

params [["_pos", [], [[]], [2, 3]]];

if (!isServer) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_unit"];
if (isNull _unit || {!alive _unit}) exitWith {
    WARNING_1("srvRequestATO: refused - machine %1 has no live player",_owner);
};
if !(_pos isEqualTypeAll 0) exitWith {
    WARNING_1("srvRequestATO: refused - no target position from machine %1",_owner);
};
([_unit] call EFUNC(support,canTask)) params ["_may", "_why"];
if (!_may) exitWith {
    WARNING_2("srvRequestATO: refused %1 - %2",name _unit,_why);
};

private _side = side group _unit;
private _at = [_pos select 0, _pos select 1, 0];
private _ok = [_side, _at] call FUNC(requestCAS);
INFO_3("ATO CAS request by %1 for %2 -> %3",name _unit,_side,_ok);
