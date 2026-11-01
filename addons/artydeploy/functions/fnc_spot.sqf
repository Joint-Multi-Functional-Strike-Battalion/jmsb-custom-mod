#include "script_component.hpp"
/*
 * Author: JMSB
 * Where a carrier's gun goes: REAR_GAP metres (2.5) behind the rear edge of
 * the vehicle, on its centre line, on the ground, facing the way the vehicle
 * faces (user, 2026-10-25: "deployed to the rear of the vehicle 2.5 meters to
 * the rear").
 *
 * Arguments:
 * 0: The carrier <OBJECT>
 *
 * Return Value:
 * [position ATL, direction] <ARRAY>
 *
 * Example:
 * ([_veh] call jmfsb_artydeploy_fnc_spot) params ["_pos", "_dir"]
 *
 * Public: No
 */

params [["_veh", objNull, [objNull]]];

(boundingBoxReal _veh) params ["_min"];
private _pos = _veh modelToWorld [0, (_min # 1) - REAR_GAP, 0];
_pos set [2, 0];
[_pos, getDir _veh]
