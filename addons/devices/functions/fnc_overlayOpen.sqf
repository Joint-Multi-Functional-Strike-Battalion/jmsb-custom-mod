#include "script_component.hpp"
/*
 * Author: YonV
 * Puts the walking-view layer up, if it is not already, and answers its
 * display. Nothing is placed or drawn here: FUNC(overlayTick) places the
 * controls on its next pass, because it is the one that knows which device
 * and which edge.
 *
 * THE MAP DRAWS THE BFT. jmfsb_bft hangs its member icons on the vanilla
 * map's Draw event; the same handler is hung on this map, so everyone round
 * the player is on the device the way he is on the map screen. jmfsb_ew's
 * map layer (jammers, fixes) is hung the same way, and so is jmfsb_pointman's
 * route (user, 2026-11-01: "no line no direction no distance" - the route
 * was on the tablet's map and the paper one, never here). Guarded, not
 * required: the suite is assembled from whatever a mission has. The side's
 * drones are this addon's own layer (FUNC(overlayDrawDrones)), under the
 * members like the rest.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The layer's display, displayNull when it could not be raised <DISPLAY>
 *
 * Example:
 * private _display = [] call jmfsb_devices_fnc_overlayOpen
 *
 * Public: No
 */

private _display = uiNamespace getVariable [QGVAR(overlayDisplay), displayNull];
if (!isNull _display) exitWith {_display};

QGVAR(overlay) cutRsc [QGVAR(overlay), "PLAIN", 0, false];
_display = uiNamespace getVariable [QGVAR(overlayDisplay), displayNull];
if (isNull _display) exitWith {
    WARNING("overlayOpen: the title layer did not come up");
    displayNull
};

// Follow first, so the icons below are drawn on the map as it now stands.
(_display displayCtrl IDC_OVERLAY_MAP) ctrlAddEventHandler ["Draw", {_this call FUNC(overlayFollow)}];
(_display displayCtrl IDC_OVERLAY_MAP) ctrlAddEventHandler ["Draw", {_this call FUNC(overlayDrawRings)}];
// The EW layer under the members: fixed jammers and the side's own jammers,
// as on the map screen and the tablet (jmfsb_ew hangs it on those itself).
if (!isNil QEFUNC(ew,mapDraw)) then {
    (_display displayCtrl IDC_OVERLAY_MAP) ctrlAddEventHandler ["Draw", {_this call EFUNC(ew,mapDraw)}];
};
// POINT MAN'S ROUTE, under the members (user, 2026-11-01): the numbered dots
// and legs, and while navigating the leg from the player to the next waypoint
// in the accent - its own attach, as on the tablet's map and the paper one.
if (!isNil QEFUNC(pointman,attach)) then {
    [_display displayCtrl IDC_OVERLAY_MAP] call EFUNC(pointman,attach);
};
// THE SIDE'S DRONES, under the members (DESIGN_PHONE_WALKING "Map": "drones
// (circle + callsign)"): the DRONES board's fleet, kept by the tick.
(_display displayCtrl IDC_OVERLAY_MAP) ctrlAddEventHandler ["Draw", {_this call FUNC(overlayDrawDrones)}];
if (!isNil QEFUNC(bft,drawMembers)) then {
    (_display displayCtrl IDC_OVERLAY_MAP) ctrlAddEventHandler ["Draw", {_this call EFUNC(bft,drawMembers)}];
};

// A fresh layer has never been placed, whatever the last one was placed for,
// and RF's summary and the drone marks are read afresh for it.
GVAR(overlayKey) = "";
GVAR(overlayRfDirty) = true;
GVAR(overlayDronesNext) = 0;

_display
