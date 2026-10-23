#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// ALL CLIENT STATE, in world positions. Nothing here belongs to a map control,
// so the same ruler stands on the vanilla map and on the tablet's screen, and a
// host coming and going loses none of it - see README.md.

// The tool taking map clicks, "" for none. One at a time.
GVAR(tool) = "";

// Where the cursor is on whichever map it last moved over, [] off the maps.
GVAR(cursor) = [];

// RULER: a first point waiting for its second, and the measured pair.
GVAR(anchor) = [];
GVAR(ruler) = [];
// The map a ruler press landed on, so its release can tell a drag from a click.
// A control, so it lives in uiNamespace - missionNamespace cannot serialize it.
uiNamespace setVariable [QGVAR(pressMap), controlNull];

// PROTRACTOR: [centre, arm bearing], the bearing -1 while the arm follows the
// cursor.
GVAR(protractor) = [];

// ROUTE: the waypoints, in order.
GVAR(route) = [];

// VIEWSHED: [centre, radius, rings, sectors, eye ASL, next ray], the two
// triangle lists the cells have been sorted into so far, and the per-frame
// handler computing the rest (-1 for none).
GVAR(viewshed) = [];
GVAR(vsSeen) = [];
GVAR(vsHidden) = [];
GVAR(vsHandle) = -1;

// MARK: the local markers this client dropped, so CLEAR can take them back.
GVAR(marks) = [];

// The frame an app last closed on. A press on the map that closed an app is
// the app's, not a tool's - see FUNC(hasInput).
GVAR(closedFrame) = -1;

// Where this terrain's grid squares fall, worked out on the first grid asked
// for - see FUNC(gridCalibrate). [] until then.
GVAR(gridCal) = [];

// The dot drawn at a measured point: the marker set's own, read off config
// rather than spelled as a path.
GVAR(dotIcon) = getText (configFile >> "CfgMarkers" >> MARK_TYPE >> "icon");

ADDON = true;
