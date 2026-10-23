#include "script_component.hpp"
/*
 * Author: JMSB
 * What the picked asset draws on the support page's map - the "overlay" code
 * of provider "fires", Simplex's range indicators: the asset's position, and
 * its minimum and maximum range as rings round it (FUNC(gunRanges)). A
 * battery has both; a cruise missile launcher its 1 km minimum and its reach;
 * a loitering munition site its reach. A range with no real limit is not
 * drawn.
 *
 * Arguments:
 * 0: Asset id, "fires:<n>" <STRING>
 * 1: The asset's row <ARRAY>
 *
 * Return Value:
 * Shapes, ["ring", centre, radius, label] / ["point", at, label] <ARRAY>
 *
 * Example:
 * ["fires:0", _row] call jmfsb_support_fires_fnc_overlay
 *
 * Public: No
 */

#define OVERLAY_NO_LIMIT 1e6

params [["_assetId", "", [""]], ["_row", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[]};

private _at = _logic getVariable [QGVAR(origin), getPosATL _logic];
([_logic] call FUNC(gunRanges)) params ["_min", "_max"];

private _shapes = [["point", _at, _logic getVariable [QGVAR(callsign), _row param [2, ""]]]];
if (_max > 0 && _max < OVERLAY_NO_LIMIT) then {
    _shapes pushBack ["ring", _at, _max, format ["MAX %1", toUpper ([_max] call FUNC(fmtDist))]];
};
if (_min > 0) then {
    _shapes pushBack ["ring", _at, _min, format ["MIN %1", toUpper ([_min] call FUNC(fmtDist))]];
};

_shapes
