#include "script_component.hpp"
/*
 * Author: YonV
 * Where the towns are: a centre and a size for each settlement on the map.
 *
 * WITH ALiVE, ALiVE's settlement clusters (the adapter's clusterCandidates) -
 * unchanged, and empty on a map ALiVE has not indexed, as before.
 *
 * WITHOUT ALiVE (user, 2026-11-02: "works with or without"), the map's own
 * named places: every capital, city and village location the terrain carries,
 * sized by the location itself and never below SETTLEMENT_MIN_SIZE. Every map
 * has them; that is why they are the fallback.
 *
 * Arguments: None
 *
 * Return Value:
 * [[centre <ARRAY>, size <NUMBER>], ...] <ARRAY>
 *
 * Example:
 * private _towns = call jmfsb_common_fnc_settlements;
 *
 * Public: Yes
 */

// ALiVE loaded with no commanders is not loaded (user, 2026-11-02: "same as
// not loaded") - FUNC(aliveLoaded) says no once the adapter has given up.
if (!isNil QEFUNC(adapter_alive,clusterCandidates) && {[] call FUNC(aliveLoaded)}) exitWith {
    ["settlement"] call EFUNC(adapter_alive,clusterCandidates)
};

private _centre = [worldSize / 2, worldSize / 2, 0];
(nearestLocations [_centre, SETTLEMENT_TYPES, worldSize]) apply {
    private _size = size _x;
    private _pos = locationPosition _x;
    _pos set [2, 0];
    [_pos, ((_size select 0) max (_size select 1)) max SETTLEMENT_MIN_SIZE]
}
