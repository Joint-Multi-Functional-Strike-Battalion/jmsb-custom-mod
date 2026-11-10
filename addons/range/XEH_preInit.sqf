#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

// The run this machine is shooting - one at a time, on the shooter's own
// machine, because the hits are seen there (HitPart fires for the shooter).
GVAR(session) = createHashMap;

ADDON = true;
