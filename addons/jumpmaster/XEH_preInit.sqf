#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// THE LEADER'S PLAN, his own machine: the type, the red and green light
// points (world positions, [] unset), the passes and the exit he picked
// (-1 and "" until the page reads the settings' defaults).
GVAR(type) = TYPE_HALO;
GVAR(red) = [];
GVAR(green) = [];
GVAR(passes) = -1;
GVAR(exit) = "";
// The page's refresh loop; a CBA handler id is only good for this mission.
GVAR(pfh) = -1;
GVAR(dotIcon) = getText (configFile >> "CfgMarkers" >> DOT_MARKER >> "icon");

// THE RUNS, server: one hashmap each (FUNC(srvLaunch)), one per squad.
GVAR(runs) = [];

// THE TILE, offered to tacpad_apps' band; it answers nothing for anyone
// who is not a jumpmaster (FUNC(tile)), so that is its gate, not the role
// tiles[] lists.
if (!isNil QEGVAR(tacpad_apps,tileProviders)) then {
    EGVAR(tacpad_apps,tileProviders) set [APP_ID, FUNC(tile)];
    EGVAR(tacpad_apps,tileUngated) pushBackUnique APP_ID;
};

// THE FREEFALL READOUT, offered to the phone's status row; FUNC(altWatch)
// puts it first for a jump and takes it out on the ground.
if (!isNil QEGVAR(devices,overlayProviders)) then {
    EGVAR(devices,overlayProviders) set [ALT_ICON, FUNC(altCell)];
};

ADDON = true;
