#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the escorts' attack on a target area is over (user, 2026-11-02: ALL
 * ATTACK - "when the area is clear or the drones are winchester / the jet
 * egresses, the drones rejoin the jet"). Their watch flies them back to their
 * slots on its next tick (FUNC(escortTick)). Called by the provider when its
 * lead egresses or goes home, and by FUNC(escortStrike) when the area is
 * clear, the escorts are Winchester or the time is up. What they destroyed
 * stays counted on the lead (QGVAR(escortHits)).
 *
 * Arguments:
 * 0: The lead aircraft <OBJECT>
 *
 * Return Value:
 * There was an attack to end <BOOL>
 *
 * Example:
 * [_veh] call jmfsb_support_fnc_escortAttackEnd
 *
 * Public: Yes
 */

params [["_lead", objNull, [objNull]]];

if (!isServer || {isNull _lead}) exitWith {false};
if (count (_lead getVariable [QGVAR(escortAttack), createHashMap]) isEqualTo 0) exitWith {false};

_lead setVariable [QGVAR(escortAttack), nil];
INFO_2("escorts of '%1' rejoin - %2 destroyed",typeOf _lead,_lead getVariable [ARR_2(QGVAR(escortHits),0)]);
true
