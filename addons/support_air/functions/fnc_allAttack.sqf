#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a fixed-wing CAS flight cleared ALL ATTACK goes in (user, 2026-11-02:
 * "add an all attack for the fixed flight where the drones also attack the
 * target or targets in the area"). The jet runs its attack as CLEARED HOT
 * (FUNC(casJob)); its escort drones break off and attack the target and every
 * other hostile inside ALL_ATTACK_RADIUS m of it with their own weapons, each
 * its own target - vehicles and statics first, then men - under the jet's own
 * friendly rule: no target within the module's Friendly Range of the players'
 * side unless the card's DANGER CLOSE was acknowledged (EFUNC(support,
 * escortAttack)). They rejoin when the area is clear, they are Winchester, or
 * the jet egresses (FUNC(casTick)). Called from the strike from station when it
 * runs in.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The jet <OBJECT>
 * 2: The strike from station <HASHMAP>
 *
 * Return Value:
 * Escorts sent in <NUMBER>
 *
 * Example:
 * [_logic, _veh, _job] call jmfsb_support_air_fnc_allAttack
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_job", createHashMap, [createHashMap]]];

if (!isServer || {isNull _logic} || {!alive _veh}) exitWith {0};

private _sent = [
    _veh,
    _job getOrDefault ["pos", getPosATL _veh],
    ALL_ATTACK_RADIUS,
    _logic getVariable [QGVAR(side), west],
    _logic getVariable [QGVAR(friendlyRange), 0],
    _job getOrDefault ["danger", false]
] call EFUNC(support,escortAttack);
INFO_2("%1 ALL ATTACK - %2 escort(s) in",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_sent);
_sent
