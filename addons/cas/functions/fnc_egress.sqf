#include "script_component.hpp"
/*
 * Author: JMSB
 * The end of a run, server side: the seat goes back, the airframe comes back
 * to the server, and the aircraft flies on its egress heading off the edge of
 * the map, where it is deleted.
 *
 * IT LEAVES THE WAY AN AIRCRAFT LEAVES. A drone that vanishes four kilometres
 * past the target is a drone that vanishes in front of whoever is standing
 * four kilometres past the target. One that flies off the map edge never
 * vanishes anywhere a player can be, so it is routed on its egress heading to
 * the first point past the edge and only deleted once it is outside the map.
 *
 * THE BOARD IS NOT WAITING FOR THIS. The run watch has already put the asset
 * back to idle and started its cooldown before calling here; the aircraft on
 * its way out is no longer the asset's aircraft. It is still a real one: its
 * MPKilled still counts a loss against the module if something shoots it down
 * on the way out.
 *
 * THE SEAT IS GIVEN BACK BEFORE THE AIRCRAFT IS TAKEN AWAY. A drone
 * controller whose airframe is deleted out from under him is a man looking at
 * a dead camera with no way out of it, so this says so first - here when the
 * run ends, and again before the delete, because the aircraft is on every
 * DRONES board on the side until it is gone and somebody may have taken it.
 *
 * AND THE AIRFRAME IS TAKEN BACK OFF HIS MACHINE. A UAV goes LOCAL to whoever
 * is flying it, and a delete only lands where the object lives - so an
 * aircraft a controller was holding would be deleted on the server, stay
 * alive on his client, and fly on with nobody watching it.
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 * 1: Egress heading <NUMBER> - degrees
 * 2: Callsign, for the log <STRING> (optional, default "CAS")
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]], ["_heading", 0, [0]], ["_callsign", "CAS", [""]]];

if (!isServer || {isNull _veh}) exitWith {};

// Hand back and take back - the same two steps before the route and before
// the delete.
private _reclaim = {
    params ["_veh"];
    [QGVAR(offStation), [_veh]] call CBA_fnc_globalEvent;
    if (!local _veh) then {_veh setOwner 2};
    private _grp = group driver _veh;
    if (!isNull _grp && {!local _grp}) then {_grp setGroupOwner 2};
};

// The delete, a beat after the hand-back so the controller is out first. It
// calls _reclaim by name, so the exit watch carries both.
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

private _offMap = {
    params ["_p"];
    _p params ["_east", "_north"];
    _east < 0 || _north < 0 || _east > worldSize || _north > worldSize
};

private _grp = group driver _veh;

// A wreck goes now, as does anything already off the map or with nobody left
// aboard to fly it out.
if (!alive _veh || {isNull _grp} || {[getPosATL _veh] call _offMap}) exitWith {
    [_veh] call _remove;
};

[_veh] call _reclaim;

// WHERE IT CROSSES THE EDGE. The first point on the egress heading outside a
// box CAS_EXIT_MARGIN wider than the map - the aircraft is inside the map, so
// that is always ahead of it and always past the line it is deleted on.
(getPosATL _veh) params ["_px", "_py"];
private _dx = sin _heading;
private _dy = cos _heading;
private _lo = -CAS_EXIT_MARGIN;
private _hi = worldSize + CAS_EXIT_MARGIN;
private _legs = [];
if (_dx != 0) then {_legs pushBack ((([_lo, _hi] select (_dx > 0)) - _px) / _dx)};
if (_dy != 0) then {_legs pushBack ((([_lo, _hi] select (_dy > 0)) - _py) / _dy)};
private _run = selectMin _legs;
private _exit = [_px + _dx * _run, _py + _dy * _run, 0];

// Whatever it was doing - the strike's last MOVE, the loiter orbit - is
// replaced by one MOVE off the map.
for "_i" from (count waypoints _grp) - 1 to 0 step -1 do {
    deleteWaypoint [_grp, _i];
};
private _wp = _grp addWaypoint [_exit, 0];
_wp setWaypointType "MOVE";
_wp setWaypointSpeed "FULL";
_grp setCurrentWaypoint _wp;

INFO_3("%1 leaving the map on %2 deg at %3",_callsign,round _heading,mapGridPosition _exit);

// THE EXIT WATCH. Deleted once it is outside the map, or if it is shot down on
// the way, or if it has not got there in CAS_EXIT_TIMEOUT - an aircraft that
// has lost its waypoint to terrain or a stall is deleted where it is rather
// than left circling for the rest of the mission.
[{
    params ["_args", "_handle"];
    _args params ["_veh", "_until", "_callsign", "_offMap", "_reclaim", "_remove"];

    if (isNull _veh) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
    };

    if (!alive _veh || {[getPosATL _veh] call _offMap}) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        [_veh] call _remove;
    };

    if (CBA_missionTime > _until) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        WARNING_1("%1 did not reach the map edge in time - deleted where it is",_callsign);
        [_veh] call _remove;
    };
}, CAS_EXIT_STEP, [_veh, CBA_missionTime + CAS_EXIT_TIMEOUT, _callsign, _offMap, _reclaim, _remove]] call CBA_fnc_addPerFrameHandler;
