#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts the walking-view layer up, if it is not already, and answers its
 * display. Nothing is placed or drawn here: FUNC(overlayTick) places the
 * controls on its next pass, because it is the one that knows which device
 * and which edge.
 *
 * THE MAP DRAWS THE BFT. jmfsb_bft hangs its member icons on the vanilla
 * map's Draw event; the same handler is hung on this map, so everyone round
 * the player is on the device the way he is on the map screen. Guarded, not
 * required: the suite is assembled from whatever a mission has.
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
if (!isNil QEFUNC(bft,drawMembers)) then {
    (_display displayCtrl IDC_OVERLAY_MAP) ctrlAddEventHandler ["Draw", {_this call EFUNC(bft,drawMembers)}];
};

// A fresh layer has never been placed, whatever the last one was placed for,
// and RF's summary is read afresh for it.
GVAR(overlayKey) = "";
GVAR(overlayRfDirty) = true;

_display
