#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// TAC//TRAINING's page state on this machine: the patient preset, the CUSTOM
// patient (one [wound kind, severity] per body part), the picked training
// area, density, faction and patrol radius, the map preview's markers, and
// the refresh loop's handle.
GVAR(preset) = "light";
GVAR(custom) = BODY_PARTS apply {[0, 0]};
GVAR(areaSel) = "";
GVAR(density) = 1;
GVAR(factionIdx) = 0;
GVAR(patrolOut) = 0;
// The area whose module defaults the page last loaded, and the factions it offers.
GVAR(areaLoaded) = "";
GVAR(factionList) = [];
GVAR(previewMarkers) = [];
GVAR(pfh) = -1;
// The server's crewed statics and vehicles per area, for FUNC(areaClear).
GVAR(areaVehicles) = [];
// The VEHICLE RANGES tab: the picked range, the one whose module defaults the
// page last loaded, and the direction, count and speed it will spawn with.
GVAR(rangeSel) = "";
GVAR(rangeLoaded) = "";
GVAR(rangeDir) = 0;
GVAR(rangeCount) = VR_DEFAULT_COUNT;
GVAR(rangeSpeed) = VR_DEFAULT_SPEED;

// THE TRAINING TILE, offered to tacpad_apps' band; it answers no tile unless
// FUNC(access) lets the player in, which is its gate rather than the role.
if (!isNil QEGVAR(tacpad_apps,tileProviders)) then {
    EGVAR(tacpad_apps,tileProviders) set [APP_ID, FUNC(tile)];
    EGVAR(tacpad_apps,tileUngated) pushBackUnique APP_ID;
};

ADDON = true;
