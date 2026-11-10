#include "script_component.hpp"
/*
 * Author: YonV
 * Turns a marker, trigger, area module or area array into one shape:
 * [centre, a, b, angle, rectangle]. A marker icon, or an object with no area,
 * is a point with POINT_RADIUS round it.
 *
 * Arguments:
 * 0: Area <STRING, OBJECT, ARRAY>
 *
 * Return Value:
 * [centre, a, b, angle, rectangle], [] when there is no such area <ARRAY>
 *
 * Example:
 * ["garrison_1"] call jmfsb_training_fnc_areaOf
 *
 * Public: No
 */

params [["_area", "", ["", objNull, []]]];

if (_area isEqualType "") exitWith {
    private _shape = markerShape _area;
    if (_shape isEqualTo "") exitWith {[]};
    private _centre = getMarkerPos _area;
    if (_shape isEqualTo "ICON") exitWith {[_centre, POINT_RADIUS, POINT_RADIUS, 0, false]};
    (markerSize _area) params ["_a", "_b"];
    [_centre, _a, _b, markerDir _area, _shape isEqualTo "RECTANGLE"]
};

if (_area isEqualType objNull) exitWith {
    if (isNull _area) exitWith {[]};
    private _centre = getPos _area;
    private _shape = if (_area isKindOf "EmptyDetector") then {
        triggerArea _area
    } else {
        _area getVariable ["objectArea", []]
    };
    if (_shape isEqualTo [] || {(_shape select 0) <= 0}) exitWith {
        [_centre, POINT_RADIUS, POINT_RADIUS, 0, false]
    };
    _shape params ["_a", "_b", ["_angle", 0], ["_rect", false]];
    [_centre, _a, _b, _angle, _rect]
};

_area params [["_centre", [], [[]]], ["_a", POINT_RADIUS, [0]], ["_b", -1, [0]], ["_angle", 0, [0]], ["_rect", false, [false]]];
if (_centre isEqualTo []) exitWith {[]};
if (_b < 0) then {_b = _a};
[_centre, _a, _b, _angle, _rect]
