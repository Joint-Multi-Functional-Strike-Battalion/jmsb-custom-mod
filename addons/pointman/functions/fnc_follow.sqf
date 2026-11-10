#include "script_component.hpp"
/*
 * Author: YonV
 * FOLLOW (user, 2026-10-30): a waypoint that walks with a man - a BFT
 * friendly, or the vehicle he is in - so the distance on the phone tracks
 * him. Added at the end of the route like any other waypoint, labelled
 * with his number and name; FUNC(wpPos) reads his position from then on.
 *
 * Arguments:
 * 0: Unit to follow <OBJECT>
 *
 * Return Value:
 * The waypoint's index, -1 when not added <NUMBER>
 *
 * Example:
 * [cursorObject] call jmfsb_pointman_fnc_follow
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {!alive _unit}) exitWith {-1};

private _n = if (isNil QEFUNC(bft,memberNumber)) then {0} else {[_unit] call EFUNC(bft,memberNumber)};
private _label = format [FOLLOW_LABEL, _n, (toUpper name _unit) select [0, FOLLOW_NAME_MAX]];
private _i = [getPosATL _unit, _label, _unit] call FUNC(add);
if (_i >= 0) then {
    [format ["WP %1 follows %2.", _i + 1, name _unit]] call FUNC(say);
};

_i
