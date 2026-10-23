#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// THE DEPLOYED DRONES, server only: node id -> [drone, role, powered].
GVAR(drones) = createHashMap;
GVAR(nextId) = 0;

#include "initSettings.inc.sqf"

ADDON = true;
