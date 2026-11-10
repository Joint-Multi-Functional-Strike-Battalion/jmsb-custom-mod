#include "script_component.hpp"
/*
 * Author: YonV
 * Client: a side's open LZs and DZs (FUNC(zonesPublish)), kept on this machine
 * when its player is of that side - another side's list is not kept. The AiTR
 * (jmfsb_ecoti) reads it from localNamespace, which no other machine can write.
 * Sent by the server by remoteExec, JIP included, and taken only from it (review
 * S7); a JIP call can come before the player's unit exists, so it waits for it,
 * at most ZONE_PLAYER_WAIT s.
 *
 * Arguments:
 * 0: The side <SIDE>
 * 1: Its zones - [kind, centre, radius, call sign, thread]... <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [west, [["pickup", [1200, 3400, 0], 50, "RAVEN", "t1"]]] remoteExecCall ["jmfsb_support_fnc_zonesLocal", 0, "jmfsb_support_zones_WEST"]
 *
 * Public: No
 */

params [["_side", sideUnknown, [sideUnknown]], ["_zones", [], [[]]]];

if (!hasInterface) exitWith {};
if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("zonesLocal: refused - not from the server (machine %1)",remoteExecutedOwner);
};

[{!isNull player}, {
    params ["_side", "_zones"];
    if ((side group player) isNotEqualTo _side) exitWith {};
    localNamespace setVariable [QGVAR(zonesSeen), [_side, _zones]];
}, [_side, _zones], ZONE_PLAYER_WAIT] call CBA_fnc_waitUntilAndExecute;
