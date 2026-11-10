#include "script_component.hpp"
/*
 * Author: YonV
 * Chooses what the console's map puts trackers on.
 *
 * The panel tracked players and only players. That is the right default and it
 * is not the only thing an admin ever has to find - an empty helicopter three
 * grids from anybody, or the AI group that will not stop shooting at a convoy,
 * are both invisible on a player-only map.
 *
 * MARKERS turns the trackers off entirely and leaves the mission's own markers,
 * which the map control draws by itself. It is the quiet setting, for reading
 * the mission rather than policing it.
 *
 * Arguments:
 * 0: Filter - "players", "vehicles", "ai" or "markers" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["ai"] call jmfsb_adminpanel_fnc_mapFilter
 *
 * Public: No
 */

params [["_filter", "players", [""]]];

GVAR(mapFilter) = _filter;

// The trackers are rebuilt from scratch rather than edited: this is the panel's
// own "the set of things I am marking has changed" flag, and it is the one
// admp_fnc_updateMapMarkers already watches.
admp_map_markersActive = false;

[] call FUNC(mapTabs);
