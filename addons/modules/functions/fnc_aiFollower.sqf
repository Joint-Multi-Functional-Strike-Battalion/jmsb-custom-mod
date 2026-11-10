#include "script_component.hpp"
/*
 * Author: YonV
 * Keeps a hunter group walking onto whichever player is inside the hunt
 * trigger, re-tasking every 15 s until the group is dead.
 *
 * Arguments:
 * 0: Group <GROUP>
 * 1: Hunt trigger <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

params ["_group", "_huntTrigger"];

[{
    params ["_args", "_handle"];
    _args params ["_group", "_huntTrigger"];

    // Wiped out: clean up the group AND this handler. The removal is the point -
    // without it every hunter wave that ever died leaves a permanent 15 s
    // allPlayers-inAreaArray running for the rest of the mission.
    if (({alive _x} count units _group) == 0) exitWith {
        deleteGroup _group;
        [_handle] call CBA_fnc_removePerFrameHandler;
    };

    private _huntTargets = allPlayers inAreaArray _huntTrigger;
    if (_huntTargets isEqualTo []) exitWith {};

    while {(count (waypoints _group)) > 0} do {
        deleteWaypoint ((waypoints _group) select 0);
    };
    private _wp1 = _group addWaypoint [getPos (_huntTargets select 0), 0];
    _wp1 setWaypointType "SAD";
}, 15, [_group, _huntTrigger]] call CBA_fnc_addPerFrameHandler;
