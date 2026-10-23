#include "script_component.hpp"
/*
 * Author: JMSB
 * Server-only. Unbuilds a patrol base: deletes the beacon and marker, re-places
 * the kit objects on the ground, runs the on-undeploy hook, frees a slot and
 * notifies everyone.
 *
 * Arguments:
 * 0: Beacon <OBJECT>
 *
 * Return Value: None
 *
 * Public: No
 */

if !(isServer) exitWith {};

params [["_beacon", objNull, [objNull]]];
if (isNull _beacon) exitWith {};

private _bases = missionNamespace getVariable [QGVAR(bases), []];
private _entry = _bases select {(_x select 0) isEqualTo _beacon};
if (_entry isEqualTo []) exitWith {};
_entry = _entry select 0;
_entry params ["_b", "_name", "_side", "_mrk", ["_n", 4]];

private _pos = getPosATL _b;

// On-undeploy hook runs while the beacon still exists (e.g. to detach its staging
// zone). Deleting the beacon afterwards also fires its Deleted EHs (e.g. Rev teleport cleanup).
[missionNamespace getVariable [QGVAR(onUndeployCode), ""], [_b, _pos, _name, _side]] call FUNC(runHook);

// Tear down - the base station first, whoever put it up (it would also go
// with the beacon's Deleted handler; this says so where the base is taken apart)
if (!isNil QEFUNC(pac,baseStationRemove)) then {[_b] call EFUNC(pac,baseStationRemove)};
deleteMarker _mrk;
deleteVehicle _b;

// Re-place the kit objects on the ground (alternating colours, small spread) so
// they can be picked up again or used for a re-build.
private _kitObjects = KIT_OBJECTS;
private _kc = count _kitObjects;
for "_i" from 0 to (_n - 1) do {
    private _cls = _kitObjects select (_i mod _kc);
    private _ang = _i * (360 / (_n max 1));
    private _p = _pos vectorAdd [1.2 * cos _ang, 1.2 * sin _ang, 0];
    private _prop = createVehicle [_cls, _p, [], 0, "CAN_COLLIDE"];
    _prop setPosATL _p;
    _prop setVectorUp surfaceNormal _p;
};

// Unregister
_bases = _bases - [_entry];
missionNamespace setVariable [QGVAR(bases), _bases, true];

[_name, format ["Unbuilt - %1 kits recovered.", _n], [1, 0.8, 0.3, 1]] call EFUNC(notify,broadcast);
