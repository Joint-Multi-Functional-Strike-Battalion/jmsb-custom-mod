#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// The server's measures (id -> measure) and its counter; the list every
// client gets; this machine's markers and their key; the player's last
// position, which areas and points he is inside, the reportable event; the
// app's new measure.
GVAR(measures) = createHashMap;
GVAR(serial) = 0;
GVAR(measureList) = [];
GVAR(markers) = [];
GVAR(markersKey) = "";
GVAR(lastPos) = [];
GVAR(inside) = createHashMap;
GVAR(event) = [];
GVAR(newType) = "phase_line";
GVAR(newName) = "";

// THE C2 TILE, for team leads and ATLs (FUNC(tile) is its gate).
if (!isNil QEGVAR(tacpad_apps,tileProviders)) then {
    EGVAR(tacpad_apps,tileProviders) set [APP_ID, FUNC(tile)];
    EGVAR(tacpad_apps,tileUngated) pushBackUnique APP_ID;
};

ADDON = true;
