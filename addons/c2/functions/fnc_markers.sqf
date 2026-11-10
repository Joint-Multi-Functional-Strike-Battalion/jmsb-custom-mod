#include "script_component.hpp"
/*
 * Author: YonV
 * The side's C2 measures on every map this machine draws - the main map, the
 * tablet's, BFT's - as local markers: a line or an area as a polyline (an area
 * closed), its name on a marker at its first point; a point as its own icon.
 * Kept to GVAR(measureList); a measure deleted takes its markers with it.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_c2_fnc_markers
 *
 * Public: No
 */

private _key = str GVAR(measureList);
if (_key isEqualTo GVAR(markersKey)) exitWith {};
GVAR(markersKey) = _key;
{deleteMarkerLocal _x} forEach GVAR(markers);
GVAR(markers) = [];

{
    _x params ["_mid", "_type", "_name", "_points", "", "", "", "_side"];
    if (_side isNotEqualTo side group player) then {continue};
    ([_type] call FUNC(typeOf)) params ["", "_label", "_kind", "_colour", "_icon"];
    private _base = MARKER_PREFIX + _mid;
    if (_kind isEqualTo "point") then {
        createMarkerLocal [_base, _points # 0];
        _base setMarkerTypeLocal _icon;
        _base setMarkerColorLocal _colour;
        _base setMarkerTextLocal format ["%1 %2", _label, _name];
        GVAR(markers) pushBack _base;
        continue;
    };
    private _path = +_points;
    if (_kind isEqualTo "area") then {_path pushBack (_points # 0)};
    private _flat = [];
    {_flat append [_x # 0, _x # 1]} forEach _path;
    createMarkerLocal [_base, _points # 0];
    _base setMarkerShapeLocal "POLYLINE";
    _base setMarkerPolylineLocal _flat;
    _base setMarkerColorLocal _colour;
    private _tag = _base + "_name";
    createMarkerLocal [_tag, _points # 0];
    _tag setMarkerTypeLocal "mil_dot";
    _tag setMarkerColorLocal _colour;
    _tag setMarkerTextLocal format ["%1 %2", _label, _name];
    GVAR(markers) append [_base, _tag];
} forEach GVAR(measureList);
