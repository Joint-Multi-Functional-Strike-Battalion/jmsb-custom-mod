#include "script_component.hpp"
/*
 * Author: YonV
 * The grid under the pointer, in the map's title bar.
 *
 * An admin teleports somebody by clicking the map, and the only way to know
 * where the click is going to land is to be told before you make it.
 *
 * Arguments:
 * 0: The map control <CONTROL>
 * 1: Pointer x, in UI coordinates <NUMBER>
 * 2: Pointer y, in UI coordinates <NUMBER>
 *
 * Return Value:
 * None
 *
 * Public: No
 */

params [["_map", controlNull, [controlNull]], ["_mx", 0, [0]], ["_my", 0, [0]]];

if (isNull _map) exitWith {};

private _display = ctrlParent _map;
if (isNull _display) exitWith {};

private _readout = _display displayCtrl IDC_ADMINPANEL_MAP_CURSOR;
if (isNull _readout) exitWith {};

// The engine hands the position in screen coordinates; the map turns it into a
// world one. Six figures, which is the ten-metre grid everybody calls out.
private _world = _map ctrlMapScreenToWorld [_mx, _my];

_readout ctrlSetStructuredText parseText format [
    "<t font='RobotoCondensedBold' size='0.75' align='right'>CURSOR %1</t>",
    mapGridPosition _world
];
