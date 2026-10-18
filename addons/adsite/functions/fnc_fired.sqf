#include "..\script_component.hpp"
/*
 * Author: JMSB
 * The fired class event, on every machine, for every shot of every unit.
 *
 * THE HOT PATH. An ignored ammo type - every bullet and grenade - costs one
 * hashmap lookup and returns. A relevant one goes on only on the machine where
 * the shooter (the gunner, for a vehicle) is LOCAL: that machine owns the
 * round, so exactly one machine reports each shot and the kill can later be
 * done where it counts. A missile is reported a frame later, once the engine
 * has given it its target.
 *
 * Arguments: the fired event's own
 * 0: Unit or vehicle <OBJECT>
 * 4: Ammo <STRING>
 * 6: Projectile <OBJECT>
 * 7: Gunner <OBJECT>
 *
 * Return Value: None
 *
 * Example:
 * (CBA "fired" class event handler)
 *
 * Public: No
 */

params ["_unit", "", "", "", "_ammo", "", "_proj", ["_gunner", objNull]];

private _info = GVAR(families) get _ammo;
if (isNil "_info") then { _info = [_ammo] call FUNC(family) };
private _family = _info select 0;
if (_family == FAM_NONE || {!GVAR(enabled)}) exitWith {};

private _on = switch (_family) do {
    case FAM_ARTILLERY: { GVAR(threatArtillery) };
    case FAM_ROCKET: { GVAR(threatRockets) };
    case FAM_MISSILE: { GVAR(threatMissiles) };
    case FAM_BOMB: { GVAR(threatBombs) };
    default { false };
};
// nothing on the map to defend with - published by FUNC(register)
if (!_on || {!(missionNamespace getVariable [QGVAR(armed), false])}) exitWith {};

private _owner = [_gunner, _unit] select (isNull _gunner);
if (!local _owner || {isNull _proj}) exitWith {};

GVAR(nextShot) = GVAR(nextShot) + 1;
private _id = format ["%1:%2", clientOwner, GVAR(nextShot)];

if (_family == FAM_MISSILE) exitWith {
    [LINKFUNC(shot), [_id, _owner, _proj, _info]] call CBA_fnc_execNextFrame;
};
[_id, _owner, _proj, _info] call FUNC(shot);
