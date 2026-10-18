#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts infantry groups on the ground around a site, holding where they stand.
 *
 * Placement only - what happens to them afterwards (left live, or handed to
 * ALiVE) is the caller's call. FUNC(buildSecurity) keeps them live;
 * FUNC(moduleAABase) profiles them.
 *
 * Arguments:
 * 0: The site's position <ARRAY>
 * 1: The side <SIDE>
 * 2: Man classes to draw from <ARRAY>
 * 3: Markers never to place on <ARRAY>
 * 4: How many groups <NUMBER>
 * 5: Inner edge of the ring they stand on, m <NUMBER>
 * 6: Outer edge of the ring, m <NUMBER>
 * 7: Area they must stand inside, inArea form - [] for anywhere on the ring <ARRAY>
 *
 * Return Value:
 * The groups made <ARRAY of GROUP>
 *
 * Example:
 * [_pos, east, _kinds, [], 1, 60, 200] call jmfsb_airdefence_fnc_placeGuards
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_side", sideUnknown, [sideUnknown]],
        ["_kinds", [], [[]]], ["_black", [], [[]]], ["_want", 0, [0]],
        ["_minR", AD_SEC_MIN_R, [0]], ["_maxR", AD_SEC_MAX_R, [0]], ["_within", [], [[]]]];

if (_want <= 0) exitWith {[]};
if (_pos isEqualTo [] || {_kinds isEqualTo []}) exitWith {[]};

private _spots = [[], _want, createHashMapFromArray [
    ["centre", _pos],
    ["minRange", _minR],
    ["maxRange", _maxR],
    ["footprint", 4],
    ["clearRadius", 4],
    ["separation", 80],
    ["blacklist", _black]
]] call EFUNC(common,findSite);

if (_within isNotEqualTo []) then {
    _spots = _spots select {_x inArea _within};
};

if (_spots isEqualTo []) exitWith {
    TRACE_1("no ground for security at this battery",mapGridPosition _pos);
    []
};

private _groups = [];

{
    private _at = _x;
    private _grp = createGroup [_side, true];
    if (isNull _grp) then {continue};

    private _n = AD_SEC_MIN + floor random (AD_SEC_MAX - AD_SEC_MIN + 1);
    for "_i" from 1 to _n do {
        private _u = _grp createUnit [selectRandom _kinds, _at getPos [random 10, random 360], [], 0, "CAN_COLLIDE"];
        if (isNull _u) then {continue};
    };

    if (units _grp isEqualTo []) then {
        deleteGroup _grp;
        continue;
    };

    // They hold the ground they were put on. A guard that wanders is not
    // guarding anything, and one that charges leaves the site open.
    _grp setBehaviour "SAFE";
    _grp setCombatMode "YELLOW";

    private _wp = _grp addWaypoint [_at, 0];
    _wp setWaypointType "SENTRY";

    _groups pushBack _grp;
} forEach _spots;

_groups
