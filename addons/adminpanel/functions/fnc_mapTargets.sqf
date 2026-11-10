#include "script_component.hpp"
/*
 * Author: YonV
 * What the map should be putting trackers on, for the tab that is selected.
 *
 * ONE PLACE, because admp_fnc_updateMapMarkers walks this list to CREATE the
 * markers and then walks its own array to UPDATE them - if the two disagreed
 * about what is being tracked the map would keep markers for things it no longer
 * shows.
 *
 * The lists are deliberately bounded. Every AI on a populated mission is a
 * thousand local markers redrawn ten times a second, so AI is the units nearest
 * the camera's own view of the map rather than all of them, and vehicles are the
 * ones with somebody in them or with damage worth looking at.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Objects to track <ARRAY>
 *
 * Example:
 * private _targets = [] call jmfsb_adminpanel_fnc_mapTargets
 *
 * Public: No
 */

private _filter = missionNamespace getVariable [QGVAR(mapFilter), "players"];

switch (_filter) do {
    case ("markers"): {[]};

    case ("vehicles"): {
        (vehicles select {
            alive _x
            && {!(_x isKindOf "CAManBase")}
            && {(crew _x) isNotEqualTo [] || {damage _x > 0.6} || {!(_x isKindOf "Man") && {getPos _x # 2 > 5}}}
        }) select [0, 200] // a bounded list, see above
    };

    case ("ai"): {
        (allUnits select {alive _x && {!isPlayer _x}}) select [0, 200] // a bounded list, see above
    };

    // Players, and the panel's own list of them - which is already built, is
    // already what the list on the left is showing, and already excludes the
    // headless clients that allPlayers does not.
    default {
        missionNamespace getVariable ["admp_playerlist_playerArray", []]
    };
};
