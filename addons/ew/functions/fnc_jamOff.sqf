#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a jammer gone - its operator dropped the pack, left the vehicle,
 * died or left the game. Its GPS zone, if it had one, goes with it.
 *
 * Arguments:
 * 0: Jammer id <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ew_jam_76561198000000000"] call jmfsb_ew_fnc_jamOff
 *
 * Public: No
 */

params [["_id", "", [""]]];

private _j = GVAR(jammers) deleteAt _id;
if (isNil "_j") exitWith {};

private _zone = _j getOrDefault ["zone", ""];
if (_zone isNotEqualTo "" && {!isNil QEFUNC(jamming,removeZone)}) then {
    [_zone] call EFUNC(jamming,removeZone);
};
TRACE_1("jammer gone",_id);
