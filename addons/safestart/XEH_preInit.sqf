#include "script_component.hpp"
ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// Safe start and the lowered weapon are plain calls (FUNC(enableSafety),
// FUNC(lowerWeapon)), not CBA events any client could raise (review R1).

ADDON = true;
