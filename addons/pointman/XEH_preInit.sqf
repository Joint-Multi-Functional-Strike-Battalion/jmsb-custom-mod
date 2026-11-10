#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// This player's waypoints, in order: [[position, label], ...]. Client side
// and his own - a route is a thing a man walks, not a thing a section shares
// (the shared picture is TAC//MSG's and BFT's).
GVAR(waypoints) = [];
// The one being walked to (an index into GVAR(waypoints)), -1 for none.
GVAR(next) = -1;
GVAR(navigating) = false;
// The page's refresh loop, a mission variable on purpose: a CBA per-frame
// handler id is only good for the mission that issued it. The app group this
// addon last drew is a control and lives in uiNamespace (QGVAR(group)).
GVAR(pfh) = -1;
GVAR(dotIcon) = getText (configFile >> "CfgMarkers" >> DOT_MARKER >> "icon");

#include "initSettings.inc.sqf"

// THE PHONE'S AND SIDE DEVICES' STATUS CELL and THE TABLET'S TILE, offered
// to their rows. jmfsb_devices shows the first OVERLAY_STATUS_CELLS (seven)
// of its order, five named since GPS went (2026-11-01), so PM is put at the
// front of the order only while navigating (FUNC(use)). jmfsb_devices is a
// required addon, so its preInit has built the providers by now. The tile is
// ungated: a route is anyone's.
if (!isNil QEGVAR(devices,overlayProviders)) then {
    EGVAR(devices,overlayProviders) set [STATUS_ICON, FUNC(cell)];
};
if (!isNil QEGVAR(tacpad_apps,tileProviders)) then {
    EGVAR(tacpad_apps,tileProviders) set [APP_ID, FUNC(tile)];
    EGVAR(tacpad_apps,tileUngated) pushBackUnique APP_ID;
};

ADDON = true;
