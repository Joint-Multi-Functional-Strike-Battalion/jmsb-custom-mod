#include "script_component.hpp"
/*
 * Author: YonV
 * Where a side's ground is: its TAOR and blacklist area markers.
 *
 * WITH ALiVE, ALiVE's answer and nothing else - the adapter's taorFor, read off
 * the side's own placement modules. Unchanged by this function.
 *
 * WITHOUT ALiVE (user, 2026-11-02: "works with or without"), the mission's own
 * map markers, named for the side the way a mission maker reads them: an area
 * marker whose name starts jmfsb_taor_west / jmfsb_taor_east / jmfsb_taor_guer
 * is that side's ground, one starting jmfsb_black_<side> is kept out of. Case
 * does not matter and anything may follow (jmfsb_taor_east_2). No marker is
 * the whole map - ALiVE's own convention, so every caller reads both the same.
 *
 * Arguments:
 * 0: Side <SIDE>
 *
 * Return Value:
 * [taorMarkers <ARRAY of STRING>, blacklistMarkers <ARRAY of STRING>]
 *
 * Example:
 * ([east] call jmfsb_common_fnc_groundFor) params ["_taor", "_black"];
 *
 * Public: Yes
 */

params [["_side", sideUnknown, [sideUnknown]]];

// ALiVE loaded with no commanders is not loaded (user, 2026-11-02: "same as
// not loaded") - FUNC(aliveLoaded) says no once the adapter has given up.
if (!isNil QEFUNC(adapter_alive,taorFor) && {[] call FUNC(aliveLoaded)}) exitWith {
    [_side] call EFUNC(adapter_alive,taorFor)
};

if !(_side in [west, east, independent]) exitWith {[[], []]};

private _name = toLower ([_side] call FUNC(sideToText));
private _taorPrefix = GROUND_TAOR_PREFIX + _name;
private _blackPrefix = GROUND_BLACK_PREFIX + _name;
private _taor = [];
private _black = [];

{
    private _m = toLower _x;
    // An area, not an icon: inArea on an icon marker is a point.
    if !(markerShape _x in ["RECTANGLE", "ELLIPSE"]) then {continue};
    if ((_m find _taorPrefix) == 0) then {_taor pushBack _x; continue};
    if ((_m find _blackPrefix) == 0) then {_black pushBack _x};
} forEach allMapMarkers;

[_taor, _black]
