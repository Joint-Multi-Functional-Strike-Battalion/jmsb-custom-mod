#include "script_component.hpp"
/*
 * Author: YonV
 * A leader has reached his new town. He gets out, goes inside, and stops
 * moving until the next rotation.
 *
 * Called from the move waypoint's completion statement, so it runs on whoever
 * the waypoint belongs to rather than on a timer that has to guess how long a
 * drive takes.
 *
 * Arguments:
 * 0: The leader <OBJECT>
 *
 * Return Value: None
 *
 * Example:
 * [_leader] call jmfsb_leaders_fnc_arrive
 */

params [["_u", objNull, [objNull]]];

if (!isServer) exitWith {};
if (isNull _u || {!alive _u}) exitWith {};

private _idx = _u getVariable [QGVAR(index), -1];
private _rec = GVAR(leaders) param [_idx, []];
if (_rec isEqualTo []) exitWith {};

private _house = GVAR(houses) param [_rec select 1, objNull];
if (isNull _house) exitWith {};

// Out of the car first. Left assigned he climbs straight back in the moment
// anything startles him, and a leader sitting in a parked car is not hiding.
private _car = _u getVariable [QGVAR(car), objNull];
if (!isNull _car) then {
    unassignVehicle _u;
    [_u] orderGetIn false;
    _u action ["Eject", vehicle _u];
};

// INSIDE, not beside. A building position is the whole point of a safe house -
// it is what makes finding him a search rather than a glance.
[{
    params ["_u", "_house"];
    if (isNull _u || {!alive _u}) exitWith {};

    private _spots = _house buildingPos -1;
    private _at = _spots param [floor random count _spots, getPosATL _house];

    _u setPosATL _at;
    _u disableAI "PATH";
    _u setVariable [QGVAR(moving), false];

    // Hoisted: a comma inside a macro argument reads as an argument separator.
    private _n = (_u getVariable [QGVAR(index), -1]) + 1;
    private _grid = mapGridPosition _at;
    INFO_2("leader %1 is in place at %2",_n,_grid);
}, [_u, _house], LEADERS_DISMOUNT] call CBA_fnc_waitAndExecute;
