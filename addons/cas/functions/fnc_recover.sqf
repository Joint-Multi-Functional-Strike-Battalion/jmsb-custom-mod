#include "script_component.hpp"
/*
 * Author: YonV
 * The end of a run, server side (user, 2026-11-02: "all support aircraft needs
 * to be virtual till tasked, then they spawn in at alt over the support module
 * location"): the seat goes back, the airframe comes back to the server, and
 * the drone flies home to the module - by the run's egress point first when the
 * BDA said EGRESS - at the hold altitude, where it is removed, crew and
 * airframe, inside CAS_HOME_RING m. The asset is virtual again; the next
 * tasking makes a new drone, full of fuel and stores. Flying home uses no
 * respawn.
 *
 * THE BOARD IS NOT WAITING FOR THIS. The run watch has already put the asset
 * back to READY and started its cooldown before calling here. The drone on its
 * way home is still a real one: its MPKilled still counts a loss against the
 * module if something shoots it down on the way (FUNC(killed)).
 *
 * THE SEAT IS GIVEN BACK BEFORE THE AIRCRAFT IS TAKEN AWAY. A drone controller
 * whose airframe is deleted out from under him is a man looking at a dead
 * camera with no way out of it, so this says so first - here when the run
 * ends, and again before the delete, because the aircraft is on every DRONES
 * board on the side until it is gone and somebody may have taken it. AND THE
 * AIRFRAME IS TAKEN BACK OFF HIS MACHINE: a UAV goes LOCAL to whoever is
 * flying it, and a delete only lands where the object lives.
 *
 * A wreck is removed at once. A drone that has not made it home in
 * CAS_EXIT_TIMEOUT is removed where it is.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The drone <OBJECT>
 * 2: Callsign, for the log <STRING>
 * 3: A point to fly first (the BDA's EGRESS), [] for none <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh, "HAWK", []] call jmfsb_cas_fnc_recover
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_veh", objNull, [objNull]],
    ["_callsign", "CAS", [""]],
    ["_via", [], [[]]]
];

if (!isServer || {isNull _veh}) exitWith {};

// A pass still under way is over: the AI gets the airframe back for the leg
// home (2026-11-05).
[_veh, "recovered", "", true] call FUNC(passEnd);

// Hand back and take back - the same two steps before the route and before
// the delete.
private _reclaim = {
    params ["_veh"];
    // By remoteExec, taken only from the server (review S7); only the
    // machine linked to this aircraft acts on it.
    [_veh] remoteExecCall [QFUNC(offStation), 0];
    if (!local _veh) then {_veh setOwner SERVER_OWNER};
    private _grp = group driver _veh;
    if (!isNull _grp && {!local _grp}) then {_grp setGroupOwner SERVER_OWNER};
};

// The delete, a beat after the hand-back so the controller is out first. It
// calls _reclaim by name, so the home watch carries both.
private _remove = {
    params ["_veh"];
    [_veh] call _reclaim;
    [{
        params ["_veh"];
        if (isNull _veh) exitWith {};
        deleteVehicleCrew _veh;
        deleteVehicle _veh;
    }, [_veh], CAS_EXIT_HANDBACK] call CBA_fnc_waitAndExecute;
};

private _grp = group driver _veh;
private _home = getPosATL _veh;
if (!isNull _logic) then {
    (getPosATL _logic) params ["_hx", "_hy"];
    _home = [_hx, _hy, 0];
};

// A wreck, a drone that cannot move, one with nobody left aboard to fly it,
// or one whose module is gone goes now.
if (!alive _veh || {!canMove _veh} || {isNull _grp} || {isNull _logic}) exitWith {
    [_veh] call _remove;
};

[_veh] call _reclaim;

// Whatever it was doing - the strike's last MOVE, the loiter orbit - is
// replaced by the leg home, by the egress point first when there is one.
[_grp] call CBA_fnc_clearWaypoints;
_veh flyInHeight ([_veh, FLY_STATION] call EFUNC(support,flightHeight));
private _legs = [_home];
if (count _via >= 2) then {_legs = [_via, _home]};
{
    private _wp = _grp addWaypoint [_x, 0];
    _wp setWaypointType "MOVE";
    _wp setWaypointSpeed "NORMAL";
    if (_forEachIndex isEqualTo 0) then {_grp setCurrentWaypoint _wp};
} forEach _legs;

INFO_2("%1 off task - flying home to %2",_callsign,mapGridPosition _home);

// THE HOME WATCH. Removed over the module, a wreck at once, and one that has
// not got there in CAS_EXIT_TIMEOUT where it is.
[{
    params ["_args", "_handle"];
    _args params ["_veh", "_home", "_until", "_callsign", "_reclaim", "_remove"];

    if (isNull _veh) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
    };

    if (!alive _veh || {_veh distance2D _home < CAS_HOME_RING}) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        if (alive _veh) then {INFO_1("%1 home - removed, virtual again",_callsign)};
        [_veh] call _remove;
    };

    if (CBA_missionTime > _until) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        WARNING_1("%1 did not make it home in time - removed where it is",_callsign);
        [_veh] call _remove;
    };
}, CAS_EXIT_STEP, [_veh, _home, CBA_missionTime + CAS_EXIT_TIMEOUT, _callsign, _reclaim, _remove]] call CBA_fnc_addPerFrameHandler;
