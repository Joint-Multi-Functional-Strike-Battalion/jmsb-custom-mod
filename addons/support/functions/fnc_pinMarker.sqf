#include "script_component.hpp"
/*
 * Author: YonV
 * Client: draws one marker of a support thread's pin from its spec, or removes
 * it (2026-11-01, DESIGN_SUPPORT_MESSAGING 6.3, build step 8). A local
 * marker, as the thread's own pin is (messaging cltMarker): it marks this
 * player's map only, and the game map and the tablet's map draw it alike, so
 * the pin needs no map layer of its own.
 *
 *   [PIN_ICON, at, colour, type, text, size]       an icon with its text
 *   [PIN_RING, centre, colour, radius, brush, alpha] a circle of radius m
 *   [PIN_LINE, points, colour]                      a line through the points
 *
 * Arguments:
 * 0: Marker name <STRING>
 * 1: Spec, [] to remove <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["jmfsb_support_pin_T0042_0", ["icon", _pos, "ColorBlack", "mil_destroy", "HOG TARGET", 1]] call jmfsb_support_fnc_pinMarker
 *
 * Public: No
 */

params [["_name", "", [""]], ["_spec", [], [[]]]];

if (_name isEqualTo "") exitWith {};

deleteMarkerLocal _name;
if (_spec isEqualTo []) exitWith {};

_spec params [["_kind", "", [""]], ["_at", [], [[]]], ["_colour", PIN_COLOUR_INK, [""]], ["_a", ""], ["_b", ""], ["_c", PIN_ICON_SIZE]];

private _first = [_at, _at param [0, []]] select (_kind isEqualTo PIN_LINE);
if (count _first < 2) exitWith {};

private _marker = createMarkerLocal [_name, _first];
if (_marker isEqualTo "") exitWith {};
_marker setMarkerColorLocal _colour;

switch (_kind) do {
    case PIN_ICON: {
        _marker setMarkerShapeLocal PIN_SHAPE_ICON;
        _marker setMarkerTypeLocal _a;
        _marker setMarkerSizeLocal [_c, _c];
        _marker setMarkerTextLocal _b;
    };
    case PIN_RING: {
        _marker setMarkerShapeLocal PIN_SHAPE_RING;
        _marker setMarkerSizeLocal [_a, _a];
        _marker setMarkerBrushLocal _b;
        _marker setMarkerAlphaLocal _c;
    };
    case PIN_LINE: {
        private _flat = [];
        {
            _flat pushBack (_x select 0);
            _flat pushBack (_x select 1);
        } forEach _at;
        _marker setMarkerShapeLocal PIN_SHAPE_LINE;
        _marker setMarkerPolylineLocal _flat;
    };
    default {
        deleteMarkerLocal _marker;
    };
};
