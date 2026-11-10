#include "script_component.hpp"
/*
 * Author: YonV
 * Profiles near a position - the virtual half of "who is around".
 *
 * Thin wrap of ALiVE's own spatial query so no feature addon has to name an
 * ALiVE function to ask who is nearby. The selector is ALiVE's own shape:
 * [sideText, type, objectType, code], all optional.
 *
 * Arguments:
 * 0: Position <ARRAY>
 * 1: Radius (m) <NUMBER>
 * 2: Selector <ARRAY> (optional, default [] - entities)
 *
 * Return Value:
 * Profiles <ARRAY>
 *
 * Example:
 * [getPosATL player, 800, ["EAST"]] call jmfsb_adapter_alive_fnc_nearProfiles
 */

params [["_pos", [], [[]]], ["_radius", 500, [0]], ["_filters", [], [[]]]];

if (!GVAR(ready) || {_pos isEqualTo []}) exitWith {[]};

[_pos, _radius, _filters] call ALIVE_fnc_getNearProfiles
