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

// The compass controls, [marker, readout, ticks, labels], made the first time it
// is drawn, and whether they are showing. See FUNC(drawCompass).
GVAR(compassCtrls) = [];
GVAR(compassShown) = false;
// The support threads' LZs and DZs (user, 2026-11-02, FUNC(updateZones)): the
// side's list last read, each zone's ring and label worked out from it, the
// nearest ZONE_MAX of them to draw and the colour; their controls, [dots,
// label] per zone, and how many were shown last frame (FUNC(drawZones)).
GVAR(zoneSource) = [];
GVAR(zoneCache) = [];
GVAR(zoneDraw) = [];
GVAR(zoneAccent) = COMPASS_WHITE;
GVAR(zonePool) = [];
GVAR(zonesShown) = 0;

// The frame Draw3D last ran on - FUNC(hideCovered) reads a gap as "not drawn".
GVAR(drawFrame) = 0;

// The marked buildings in range, [building, rgb, label] - from the server's
// published list (QGVAR(marks), FUNC(markSet)), twice a second
// (FUNC(updateCandidates)).
GVAR(buildings) = [];

ADDON = true;
