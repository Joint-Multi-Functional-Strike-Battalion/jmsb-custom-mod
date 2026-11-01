#include "script_component.hpp"
/*
 * Author: JMSB
 * The men the BFT picture counts as friendly: everyone alive in a group on
 * the local player's side that has a player in it - the groups the member
 * marks are drawn for. One list, so the danger-close check (TAC//SUPPORT)
 * and Point Man's FOLLOW agree with the map about who is a friendly.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Units <ARRAY>
 *
 * Example:
 * private _friends = [] call jmfsb_bft_fnc_friendlies
 *
 * Public: Yes
 */

private _me = call CBA_fnc_currentUnit;
if (isNull _me) exitWith {[]};

private _side = side group _me;
private _out = [];
{
    if (side _x isNotEqualTo _side) then {continue};
    if ((units _x findIf {isPlayer _x}) < 0) then {continue};
    _out append (units _x select {alive _x});
} forEach allGroups;

_out
