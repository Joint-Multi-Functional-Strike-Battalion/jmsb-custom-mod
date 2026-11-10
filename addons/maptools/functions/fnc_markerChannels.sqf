#include "script_component.hpp"
/*
 * Author: YonV
 * The channels this player can put a marker on now, as the engine allows
 * them, with MY MAP (this player's map only) first.
 *
 * ASKED OF THE ENGINE, THE WAY ACE ASKS IT. setCurrentChannel answers false
 * for a channel the mission disabled (disableChannels) or the player is not
 * on - VEHICLE outside a vehicle - so each is tried and the player's own
 * channel put back after. The game's marker dialog lists the same ones.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [channel id, label] pairs <ARRAY>
 *
 * Example:
 * [] call jmfsb_maptools_fnc_markerChannels
 *
 * Public: No
 */

private _was = currentChannel;
private _out = [[MARKER_CHANNEL_LOCAL, MARKER_CHANNEL_LOCAL_LABEL]];

{
    if (setCurrentChannel (_x # 0)) then {
        _out pushBack _x;
    };
} forEach MARKER_CHANNELS;

setCurrentChannel _was;

_out
