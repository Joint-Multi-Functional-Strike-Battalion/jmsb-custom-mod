#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a Vector marker's in-world name (FUNC(placeTargetMarker), by
 * remoteExec). The name on it is the sender's own, he must hold a Vector, and
 * the point must be within its reach; then every client draws it
 * (FUNC(show3DMarker), which takes it only from the server).
 *
 * Review R1: it was the marker3D CBA event, so any client could put any text
 * at any place on every screen.
 *
 * Arguments:
 * 0: Target position ASL <ARRAY>
 * 1: Range in metres <NUMBER>
 * 2: Marker colour config name <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_posASL, 750, "ColorRed"] remoteExecCall ["jmfsb_equipment_fnc_srvMarker3D", 2]
 *
 * Public: No
 */

params [["_posASL", [], [[]], 3], ["_distance", 0, [0]], ["_colorName", "Default", [""]]];

if (!isServer || {_posASL isEqualTo []}) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_unit"];
if (isNull _unit || {!alive _unit} || {!(currentWeapon _unit in VECTOR_DESIGNATORS)}) exitWith {
    WARNING_1("srvMarker3D: refused - machine %1 holds no Vector",_owner);
};
if ((eyePos _unit) vectorDistance _posASL > VECTOR_RANGE + VECTOR_RANGE_SLACK) exitWith {
    WARNING_2("srvMarker3D: refused - %1 marked a point out of the Vector's reach (%2)",name _unit,_posASL);
};
if !(isClass (configFile >> "CfgMarkerColors" >> _colorName)) then {_colorName = "Default"};

[_posASL, format ["%1 (%2m)", name _unit, round _distance], _colorName] remoteExecCall [QFUNC(show3DMarker), 0];
