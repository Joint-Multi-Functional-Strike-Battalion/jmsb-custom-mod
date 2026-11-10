#include "script_component.hpp"

ADDON = false;
LOG(MSG_INIT);

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// The icon set a group leader can pick from. These are the CfgMarkers suffixes -
// the side letter in front of them comes from FUNC(getGroupMarkerShape), so one
// list serves all three sides.
GVAR(availableMarkerIcons) = [
    "inf",
    "motor_inf",
    "mech_inf",
    "air",
    "armor",
    "recon",
    "antiair",
    "art",
    "hq",
    "installation",
    "maint",
    "med",
    "mortar",
    "naval",
    "ordnance",
    "plane",
    "service",
    "support",
    "uav",
    "unknown"
];

// Every marker colour the game knows, upper-cased once here so the preferred and
// blacklist settings can be compared against it without case games at runtime.
GVAR(availableMarkerColors) = [
    "true" configClasses (configFile >> "CfgMarkerColors"),
    {toUpper configName _x}
] call CBA_fnc_filter;

// Markers this machine drew last pass. Local, always - the whole system is one
// local draw off shared group variables, so nothing is ever broadcast.
GVAR(markers) = [];

GVAR(settingsAdded) = false;
GVAR(buddyAdded) = false;

// Whether the group-change watcher is up. One per client - see FUNC(init).
GVAR(groupWatch) = false;
GVAR(loopRunning) = false;

// An admin's own switch for the god view. On by default so a logged-in admin
// gets the full picture without asking; #jmfsb bft.view drops them back to what
// their group actually sees, which is the only way to check crypto from inside.
GVAR(adminView) = true;

ADDON = true;
