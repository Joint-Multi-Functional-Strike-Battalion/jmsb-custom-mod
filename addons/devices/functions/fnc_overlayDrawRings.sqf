#include "script_component.hpp"
/*
 * Author: JMSB
 * The range rings on the walking view's map: 25 m and 50 m round the player,
 * each labelled with its radius at its top. Drawn every frame on the map's
 * Draw event, after FUNC(overlayFollow) has centred it, so they stay on him.
 *
 * Arguments (map Draw event):
 * 0: The map control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * _map ctrlAddEventHandler ["Draw", {_this call jmfsb_devices_fnc_overlayDrawRings}]
 *
 * Public: No
 */

params [["_map", controlNull, [controlNull]]];

private _unit = call CBA_fnc_currentUnit;
if (isNull _unit) exitWith {};

private _pos = getPosVisual _unit;
{
    _map drawEllipse [_pos, _x, _x, 0, COLOUR_RING, ""];
    _map drawIcon [
        BLANK_ICON,
        COLOUR_RING,
        _pos vectorAdd [0, _x, 0],
        0, 0, 0,
        format ["%1 m", _x],
        0, RING_TEXT_SIZE, "RobotoCondensed", "center"
    ];
} forEach RING_RADII;
