#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// The relay table this client routes through and the per-leg cache - both
// local, both empty until the first refresh. Declared here so fnc_signal can
// run before the first refresh tick without tripping on nil.
GVAR(nodes) = [];
GVAR(edgeCache) = createHashMap;

ADDON = true;
