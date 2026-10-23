#include "script_component.hpp"
/*
 * Author: JMSB
 * Keeps the walking view's map centred on the player at the player's zoom,
 * every frame. Hung on the map's own Draw event, which fires each frame the
 * map is drawn, so the man stays dead centre as he walks - the half-second
 * tick it used to ride on let him wander off the middle between updates
 * (user, 2026-10-19: "centre on the player, zoomed in, and follow the player -
 * this is very important").
 *
 * The animation is cleared first so a queue never builds up behind it.
 *
 * Arguments (map Draw event):
 * 0: The map control <CONTROL>
 *
 * Return Value:
 * None
 *
 * Example:
 * _map ctrlAddEventHandler ["Draw", {_this call jmfsb_devices_fnc_overlayFollow}]
 *
 * Public: No
 */

params [["_map", controlNull, [controlNull]]];

private _unit = call CBA_fnc_currentUnit;
if (isNull _unit) exitWith {};

private _pos = getPosVisual _unit;
ctrlMapAnimClear _map;
_map ctrlMapAnimAdd [0, GVAR(phoneZoom), _pos];
ctrlMapAnimCommit _map;

// THE CHECK THAT IT WORKED: the world under the control's own centre is the
// man. Logged with DEBUG_MODE_FULL only; a gap of more than a few metres means
// the map's transform is not the control's rectangle (see FUNC(overlayPlace)).
#ifdef DEBUG_MODE_FULL
    (ctrlPosition _map) params ["_mx", "_my", "_mw", "_mh"];
    private _centre = _map ctrlMapScreenToWorld [_mx + _mw / 2, _my + _mh / 2];
    TRACE_3("overlayFollow",_pos,_centre,_pos distance2D _centre);
#endif
