#include "script_component.hpp"
/*
 * Author: YonV
 * May this flight be cleared ALL ATTACK? (user, 2026-11-02: "add an all attack
 * for the fixed flight where the drones also attack the target or targets in
 * the area"). Only a fixed-wing lead with an escort drone up - a helicopter
 * flight not this time. Read where CLEARED HOT is offered (the prompts'
 * answers) and where ALL ATTACK is answered (FUNC(threadReply)).
 *
 * Arguments:
 * 0: The lead aircraft <OBJECT>
 *
 * Return Value:
 * ALL ATTACK is offered and taken <BOOL>
 *
 * Example:
 * [_veh] call jmfsb_support_air_fnc_canAllAttack
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

if (!alive _veh || {_veh isKindOf "Helicopter"}) exitWith {false};

((_veh getVariable [QEGVAR(support,escorts), []]) findIf {alive _x}) > -1
