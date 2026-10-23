#include "script_component.hpp"
/*
 * Author: JMSB
 * The release that ends a ruler drag. Only the release of the press that
 * anchored a ruler means anything here.
 *
 * DRAG OR CLICK IS DECIDED ON SCREEN, against where the anchor is drawn NOW.
 * If the map panned under the drag, the anchor travelled with the cursor and
 * the release lands on top of it - that was a pan, not a measurement, and the
 * ruler goes on waiting for a second press. Measured in world metres instead,
 * a pan would have read as a zero-length ruler.
 *
 * Arguments:
 * 0: Map control <CONTROL>
 * 1: Mouse button <NUMBER>
 * 2: Screen x <NUMBER>
 * 3: Screen y <NUMBER>
 *
 * Return Value:
 * The release was a tool's <BOOL>
 *
 * Example:
 * [_map, 0, 0.5, 0.5] call jmfsb_maptools_fnc_mouseUp
 *
 * Public: No
 */

params ["_map", "_button", "_sx", "_sy"];

if (_button isNotEqualTo 0) exitWith {false};

private _pressMap = uiNamespace getVariable [QGVAR(pressMap), controlNull];
uiNamespace setVariable [QGVAR(pressMap), controlNull];

if (_pressMap isNotEqualTo _map || GVAR(tool) isNotEqualTo TOOL_RULER || GVAR(anchor) isEqualTo []) exitWith {false};

private _anchorAt = _map ctrlMapWorldToScreen GVAR(anchor);
if ((_anchorAt distance2D [_sx, _sy]) < DRAG_MIN) exitWith {true};

GVAR(ruler) = [GVAR(anchor), _map ctrlMapScreenToWorld [_sx, _sy]];
GVAR(anchor) = [];

true
