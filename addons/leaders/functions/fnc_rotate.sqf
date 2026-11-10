#include "script_component.hpp"
/*
 * Author: YonV
 * Moves every standing leader to another safe house - IN A CAR, along the
 * roads, not on foot across country.
 *
 * He sits in a building for the rotation period, drives to another town, and
 * hides again. The drive is the part players can catch him on: a man walking
 * cross-country between towns is not something anyone would see and think
 * "that is the network", but a car leaving a house and arriving at another one
 * is exactly the thread a hunt is supposed to pull.
 *
 * The next house is published BEFORE he leaves - see GVAR(nextHouse) - so
 * intel found in the house he is leaving points at where he is going rather
 * than where he was.
 *
 * Arguments: None (per-frame handler)
 *
 * Return Value: None
 *
 * Example:
 * [] call jmfsb_leaders_fnc_rotate
 */

{
    private _rec = _x;
    private _idx = _forEachIndex;
    _rec params ["_u", "_hi", "_state"];

    if (_state isNotEqualTo "up") then {continue};
    if (isNull _u || {!alive _u}) then {continue};

    // A restrained man is not going anywhere. He is somebody's prisoner, and
    // the capture play needs him to stay where he was taken.
    if (_u getVariable ["ACE_captives_isHandcuffed", false]) then {continue};

    // Already on the road from the last rotation: let him finish. Rotating a
    // leader mid-drive would leave the car halfway and him walking.
    if (_u getVariable [QGVAR(moving), false]) then {continue};

    private _nhi = floor random count GVAR(houses);
    if (_nhi isEqualTo _hi) then { _nhi = (_nhi + 1) mod (count GVAR(houses)) };
    private _next = GVAR(houses) select _nhi;

    GVAR(nextHouse) set [_idx, _nhi];
    _rec set [1, _nhi];

    _u enableAI "PATH";
    _u setVariable [QGVAR(moving), true];

    private _car = _u getVariable [QGVAR(car), objNull];
    private _grp = group _u;

    // Clear whatever the last move left behind, or waypoints stack up and he
    // drives the whole tour every rotation.
    while {count (waypoints _grp) > 0} do { deleteWaypoint ((waypoints _grp) select 0) };

    if (!isNull _car && {alive _car} && {canMove _car}) then {
        _u assignAsDriver _car;
        [_u] orderGetIn true;

        // THE KERB OUTSIDE THE HOUSE, NOT THE HOUSE. A MOVE waypoint on the
        // building's own position orders the driver to steer at its centre,
        // which he does - into the wall, engine running, for as long as the
        // waypoint stands.
        private _wp = _grp addWaypoint [[_next] call FUNC(parkSpot), 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointCompletionRadius LEADERS_ARRIVE_R;
        // A civilian car driving normally. CARELESS keeps him on the roads and
        // stops him behaving like a combatant on the way.
        _wp setWaypointBehaviour "CARELESS";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointStatements ["true",
            "[this] call jmfsb_leaders_fnc_arrive"];

        INFO_3("leader %1 driving to house %2 (%3)",_idx + 1,_nhi,mapGridPosition (getPosATL _next));
    } else {
        // No car, or it has been wrecked: he walks. Worse for him and better
        // for the players hunting him, which is the right way round.
        private _wp = _grp addWaypoint [getPosATL _next, 0];
        _wp setWaypointType "MOVE";
        _wp setWaypointCompletionRadius LEADERS_ARRIVE_R;
        _wp setWaypointBehaviour "SAFE";
        _wp setWaypointStatements ["true",
            "[this] call jmfsb_leaders_fnc_arrive"];

        INFO_2("leader %1 has no car - walking to house %2",_idx + 1,_nhi);
    };

    // The house he is going to is trapped, not the one he is leaving.
    [_next] call FUNC(armTrap);
} forEach GVAR(leaders);
