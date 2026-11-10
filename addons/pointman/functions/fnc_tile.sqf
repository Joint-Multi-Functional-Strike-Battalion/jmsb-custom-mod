#include "script_component.hpp"
/*
 * Author: YonV
 * The POINT MAN tile for jmfsb_tacpad_apps' band (a provider registered in
 * XEH_preInit, ungated: a route is anyone's). Walking: the next waypoint's
 * number over its distance, the bearing and its grid under; warn with no
 * GPS fix. Otherwise how many waypoints there are and what to press.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Tile entries, one [appId, kicker, qualifier, value, detail, state] <ARRAY>
 *
 * Example:
 * [] call jmfsb_pointman_fnc_tile
 *
 * Public: No
 */

([] call FUNC(state)) params ["_nav", "_i", "_n", "_label", "_dist", "_brg"];

switch (true) do {
    case (_n isEqualTo 0): {[[APP_ID, APP_TITLE, "", "--", "NO WAYPOINTS - PRESS TO ADD", "rest"]]};
    case (!_nav): {[[APP_ID, APP_TITLE, format ["%1 WP", _n], "--", "PRESS TO NAVIGATE", "rest"]]};
    case (_dist < 0): {[[APP_ID, APP_TITLE, format ["WP %1/%2", _i + 1, _n], "NO FIX", _label, "warn"]]};
    default {
        [[
            APP_ID, APP_TITLE, format ["WP %1/%2", _i + 1, _n],
            [_dist] call EFUNC(maptools,distanceText),
            format ["%1  %2", [_brg] call EFUNC(maptools,bearingText), _label],
            "rest"
        ]]
    };
}
