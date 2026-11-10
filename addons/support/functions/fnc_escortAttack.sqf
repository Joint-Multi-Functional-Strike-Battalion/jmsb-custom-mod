#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a lead's drone escorts break off and attack a target area (user,
 * 2026-11-02: "add an all attack for the fixed flight where the drones also
 * attack the target or targets in the area"). The provider calls it when its
 * lead is cleared ALL ATTACK; the escorts' watch flies it (FUNC(escortTick),
 * FUNC(escortStrike)): each escort its own hostile target inside the area -
 * vehicles and statics first, then men - with its own weapons, never one
 * within the friendly range of the players' own side unless danger close was
 * acknowledged. They rejoin the lead when the area is clear, when they are
 * Winchester, after ESCORT_ATTACK_TIME s, or when the provider ends it
 * (FUNC(escortAttackEnd) - the lead egresses or goes home).
 *
 * What they destroy is counted on the lead (QGVAR(escortHits)) for the
 * provider's BDA prompt.
 *
 * Arguments:
 * 0: The lead aircraft <OBJECT>
 * 1: The target area's centre <ARRAY>
 * 2: Its radius, m <NUMBER>
 * 3: The players' side <SIDE>
 * 4: Friendly range, m - no target with the side's own men this close, 0 for no check <NUMBER>
 * 5: Danger close acknowledged - the friendly range is not checked <BOOL>
 *
 * Return Value:
 * Escorts sent in, 0 when it has none alive <NUMBER>
 *
 * Example:
 * [_veh, _target, 300, west, 100, false] call jmfsb_support_fnc_escortAttack
 *
 * Public: Yes
 */

params [
    ["_lead", objNull, [objNull]],
    ["_pos", [], [[]]],
    ["_radius", ESCORT_ATTACK_RADIUS, [0]],
    ["_side", west, [west]],
    ["_friendly", 0, [0]],
    ["_danger", false, [false]]
];

if (!isServer || {!alive _lead} || {count _pos < 2}) exitWith {0};

private _escorts = (_lead getVariable [QGVAR(escorts), []]) select {alive _x};
if (_escorts isEqualTo []) exitWith {0};

_pos params ["_px", "_py"];
_lead setVariable [QGVAR(escortHits), 0];
_lead setVariable [QGVAR(escortAttack), createHashMapFromArray [
    ["pos", [_px, _py, 0]],
    ["radius", _radius max 0],
    ["side", _side],
    ["friendly", _friendly max 0],
    ["danger", _danger],
    ["until", CBA_missionTime + ESCORT_ATTACK_TIME],
    ["engaged", []],
    ["hit", []]
]];
{_x setVariable [QGVAR(attackTarget), objNull]} forEach _escorts;

INFO_3("%1 escort(s) of '%2' attacking round %3",count _escorts,typeOf _lead,mapGridPosition _pos);

count _escorts
