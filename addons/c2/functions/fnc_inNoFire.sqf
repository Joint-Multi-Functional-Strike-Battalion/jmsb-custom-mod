#include "script_component.hpp"
/*
 * Author: YonV
 * Whether a position lies inside one of a side's no-fire areas (design: a
 * support request from inside one is blocked - jmfsb_support asks this).
 *
 * Arguments:
 * 0: Position <ARRAY>
 * 1: Side <SIDE>
 *
 * Return Value:
 * The no-fire area's name, "" for none <STRING>
 *
 * Example:
 * [getPos player, west] call jmfsb_c2_fnc_inNoFire
 *
 * Public: Yes
 */

params [["_pos", [0, 0, 0], [[]]], ["_side", sideUnknown, [sideUnknown]]];

private _at = GVAR(measureList) findIf {
    (_x # 1) isEqualTo "no_fire_area" && {(_x # 7) isEqualTo _side} && {_pos inPolygon (_x # 3)}
};
if (_at < 0) exitWith {""};
(GVAR(measureList) # _at) # 2
