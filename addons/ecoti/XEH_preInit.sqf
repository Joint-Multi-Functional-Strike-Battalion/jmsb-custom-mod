#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// Power, the player's own switch. Not a setting: it is flipped in the field with
// a key, and a goggle that comes on with the mission is the expected default.
GVAR(powered) = true;

// hmd class -> [opted in, in day mode too], so the config is read once per goggle class.
GVAR(nvgCache) = createHashMap;

// hmd class -> a JMSB full-screen goggle or not. See FUNC(isFullScreen).
GVAR(fullScreenCache) = createHashMap;

// The caches Draw3D draws from.
GVAR(men) = [];
GVAR(vehicles) = [];
GVAR(visCursor) = 0;

// The box controls on the mission display, [top, bottom, left, right, label]
// per box, and how many were shown last frame. See FUNC(drawBoxes).
GVAR(pool) = [];
GVAR(shown) = 0;

ADDON = true;
