#include "script_component.hpp"
/*
 * Author: JMSB
 * DANGER CLOSE (user, 2026-10-30): the friendlies inside the danger-close
 * distance of a fire task's target point, nearest first. Only the task types
 * that put ordnance on a point (SUP_DANGER_TYPES); anything else, a point
 * not set, or the setting at 0, and nobody is near. The friendlies are the
 * BFT picture's (jmfsb_bft_fnc_friendlies), the player's own group without
 * it - the player included, because a round on his own grid is the case
 * the check is for.
 *
 * Arguments:
 * 0: Asset type, "arty" / "cas" / ... <STRING>
 * 1: Target point, world position <ARRAY>
 *
 * Return Value:
 * [[unit, distance m], ...] nearest first, [] when nobody is near <ARRAY>
 *
 * Example:
 * private _near = ["arty", _point] call jmfsb_tacpad_apps_fnc_supportDangerClose
 *
 * Public: No
 */

params [["_type", "", [""]], ["_point", [], [[]]]];

if (GVAR(dangerClose) <= 0 || {!(_type in SUP_DANGER_TYPES)} || {count _point < 2}) exitWith {[]};

private _friends = if (isNil QEFUNC(bft,friendlies)) then {
    units group (call CBA_fnc_currentUnit)
} else {
    [] call EFUNC(bft,friendlies)
};

private _near = [];
{
    if (!alive _x) then {continue};
    private _d = _x distance2D _point;
    if (_d <= GVAR(dangerClose)) then {_near pushBack [_d, _x]};
} forEach _friends;
_near sort true;

_near apply {[_x select 1, _x select 0]}
