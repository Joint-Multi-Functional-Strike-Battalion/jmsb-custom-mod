#include "script_component.hpp"
/*
 * Author: JMSB
 * The walking view's one loop: decides whether the view should be up, raises
 * or cuts the layer to match, re-lays it out when something about it has
 * changed, and redraws the rows.
 *
 * UP ONLY WHEN ALL OF THIS IS TRUE: there is a player; the display mode is
 * TABLET (in native mode the suite is on the map and there is no device);
 * the toggle key has not hidden it; one of the three items is assigned; no
 * dialog is open and the map is not up; he is alive, not in an arsenal and
 * not spectating (FUNC(overlayHidden)). A title layer draws over every
 * dialog in the game, including the tablet, and over the map - so rather
 * than fight the z-order it simply is not there while a screen is.
 *
 * Runs off a per-frame handler every OVERLAY_TICK seconds, and directly from
 * the key, the edge and the frame buttons so they land at once.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The view is up <BOOL>
 *
 * Example:
 * [] call jmfsb_devices_fnc_overlayTick
 *
 * Public: No
 */

if (!hasInterface) exitWith {false};

private _display = uiNamespace getVariable [QGVAR(overlayDisplay), displayNull];

// The display mode is read with a default rather than through HOST_DEVICE:
// the setting is declared at the shell's preInit, but a default costs nothing
// and spares a lazy guard.
private _device = "";
private _mode = missionNamespace getVariable [QEGVAR(tacpad,displayMode), "native"];
if (!isNull player && GVAR(overlayShown) && _mode isNotEqualTo "native") then {
    _device = [] call FUNC(overlayDevice);
};

private _wanted = _device isNotEqualTo "" && {!dialog} && {!visibleMap} && {!([] call FUNC(overlayHidden))};
if (!_wanted) exitWith {
    if (!isNull _display) then {
        [] call FUNC(overlayClose);
    };
    false
};

if (isNull _display) then {
    _display = [] call FUNC(overlayOpen);
};
if (isNull _display) exitWith {false};

// Re-laid out only when what it is laid out FOR has changed. The phone has no
// edge; a side device has the one the player last chose.
private _edge = ["", GVAR(overlayEdge)] select (_device isNotEqualTo "phone");
private _key = format ["%1/%2/%3/%4/%5/%6", _device, _edge, GVAR(sideFill), GVAR(phoneFill), EGVAR(tacpad,scheme), GVAR(overlayOpacity)];
if (_key isNotEqualTo GVAR(overlayKey)) then {
    GVAR(overlayKey) = _key;
    [_display, _device, _edge] call FUNC(overlayPlace);
};

// RF's summary is rebuilt only after RF said a link changed
// (jmfsb_rf_linkChanged sets the flag, see XEH_postInit).
if (GVAR(overlayRfDirty)) then {
    GVAR(overlayRfDirty) = false;
    GVAR(overlayRf) = [] call FUNC(overlayRf);
};

[_display] call FUNC(overlayDraw);

true
