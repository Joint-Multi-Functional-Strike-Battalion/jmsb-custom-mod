#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_tracks (DESIGN_RF "Public API"): the tracks a side holds. On the server,
 * for any side, as copies of the track records; on a client, his own side's
 * from his slice, in the slice's layout (FUNC(publish)).
 *
 * Arguments:
 * 0: Side (server only; optional, default the player's) <SIDE>
 *
 * Return Value:
 * Tracks <ARRAY>
 *
 * Example:
 * [east] call jmfsb_ew_fnc_tracks
 *
 * Public: Yes
 */

params [["_side", sideUnknown, [west]]];

if (isServer && {_side isNotEqualTo sideUnknown}) exitWith {
    (values (GVAR(tracks) getOrDefault [str _side, createHashMap])) apply {+_x}
};

GVAR(mine) param [1, []]
