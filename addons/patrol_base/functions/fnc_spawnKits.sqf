#include "script_component.hpp"
/*
 * Author: YonV
 * Server-only. Drops patrol-base kit objects on the ground, ready for a player to
 * build a base. Used by the Zeus module.
 *
 * Arguments:
 * 0: Position ATL <ARRAY>
 * 1: Number of kits <NUMBER> (optional, default = the "Kits required" setting)
 *
 * Return Value:
 * The dropped kit objects <ARRAY of OBJECT>
 *
 * Public: No
 */

if !(isServer) exitWith {[]};

params [["_pos", [], [[]]], ["_count", -1, [0]]];
if (_pos isEqualTo []) exitWith {[]};
// Accept a nested position (e.g. ZEN hands the callback [pos,...]); flatten to [x,y,z].
if ((_pos select 0) isEqualType []) then { _pos = _pos select 0 };
if (_count <= 0) then { _count = missionNamespace getVariable [QGVAR(kitCount), 4] };

// A ring wide enough that four folded tents do not try to occupy the same
// metre - at 1.2 m they were interpenetrating, and the engine resolves that
// by shoving props around or refusing them.
private _radius = 1.4 max (0.45 * _count);

private _objects = [];
for "_i" from 0 to (_count - 1) do {
    private _ang = _i * (360 / (_count max 1));
    private _p = _pos vectorAdd [_radius * cos _ang, _radius * sin _ang, 0];
    private _obj = createVehicle [QGVAR(kit_sand_object), _p, [], 0, "CAN_COLLIDE"];
    if (isNull _obj) then {
        WARNING_1("a patrol base kit would not create at %1",mapGridPosition _p);
    } else {
        _obj setPosATL _p;
        _obj setVectorUp surfaceNormal _p;
        _objects pushBack _obj;
    };
};

INFO_2("%1 of %2 kit(s) placed",count _objects,_count);
_objects
