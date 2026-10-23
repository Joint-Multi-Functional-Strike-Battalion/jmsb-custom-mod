#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: takes the base station off a site (FUNC(baseStation)) - out of RF,
 * out of the registry, and its helper object deleted when the site was a
 * position. Called by the owner (a staging zone removed, a patrol base
 * unbuilt) and by the station's own MPKilled and Deleted handlers; a second
 * call finds nothing and does nothing. An owner named here takes down only
 * its own station: a staging zone removed from a patrol base's mast leaves
 * the patrol base's station up (one object, one station, the first asker's).
 *
 * Arguments:
 * 0: Site object <OBJECT>
 * 1: Owner (optional, default "" = whoever owns it) <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_beacon] call jmfsb_pac_fnc_baseStationRemove
 * [_crate, "jmfsb_mission"] call jmfsb_pac_fnc_baseStationRemove
 *
 * Public: Yes
 */

params [["_object", objNull, [objNull]], ["_owner", "", [""]]];

if (!isServer || isNull _object) exitWith {};

private _id = _object getVariable [QGVAR(baseStation), ""];
if (_id isEqualTo "") exitWith {};
private _entry = GVAR(baseStations) getOrDefault [_id, []];
if (_owner isNotEqualTo "" && (_entry param [2, ""]) isNotEqualTo _owner) exitWith {};

_object setVariable [QGVAR(baseStation), nil];
GVAR(baseStations) deleteAt _id;
if (!isNil QEFUNC(rf,unregister)) then {[_id] call EFUNC(rf,unregister)};
INFO_1("base station %1 down",_id);

if (_entry isEqualTo []) exitWith {};
_entry params ["", "", "", "_helper", "_posKey"];
if (_posKey isNotEqualTo "") then {GVAR(basePositions) deleteAt _posKey};
if (_helper) then {deleteVehicle _object};
