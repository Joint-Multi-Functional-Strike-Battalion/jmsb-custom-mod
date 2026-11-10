#include "script_component.hpp"
/*
 * Author: YonV
 * Whether a marker is this player's own player marker - one the game lets him
 * delete on its map, and so one the tablet lets him delete too.
 *
 * The engine names a player marker _USER_DEFINED #<player id>/<id>/<channel>,
 * and EFUNC(common,createPlayerMarker) names ours the same way, so the owner
 * is read off the name.
 *
 * Arguments:
 * 0: Marker <STRING>
 *
 * Return Value:
 * It is this player's <BOOL>
 *
 * Example:
 * ["_USER_DEFINED #2/jmfsb_0/3"] call jmfsb_maptools_fnc_markerOwn
 *
 * Public: No
 */

params [["_marker", "", [""]]];

if ((_marker find USER_MARKER_PREFIX) isNotEqualTo 0) exitWith {false};

((_marker select [count USER_MARKER_PREFIX]) find ((getPlayerID player) + "/")) isEqualTo 0
