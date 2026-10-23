#include "script_component.hpp"
/*
 * Author: JMSB
 * Sets off a cruise missile or a loitering munition.
 *
 * A PROJECTILE WITH NO WARHEAD NAMED goes off on its own charge (triggerAmmo).
 * Anything else - a named warhead, or an air vehicle, which has no charge of
 * its own - is replaced by the warhead ammo where it stands. Given an aim
 * point the warhead is put just short of the first surface on the line to it,
 * pointed at it, so a shaped charge goes off against the hull rather than
 * beside it, and is fused by script before it can touch anything (an unarmed
 * warhead that touches the hull is a dud).
 *
 * An air vehicle is deleted with its crew rather than killed, so no wreck and
 * no second explosion from a mod's own Killed handler (the Switchblade has
 * one).
 *
 * Arguments:
 * 0: Missile or munition <OBJECT>
 * 1: Warhead ammo class, "" for the projectile's own <STRING>
 * 2: Aim point, ASL, [] to go off where it is <ARRAY> (optional, default [])
 *
 * Return Value: None
 *
 * Example:
 * [_uav, "M_Titan_AP", aimPos _target] call jmfsb_support_fires_fnc_detonate
 *
 * Public: No
 */

params [["_proj", objNull, [objNull]], ["_warhead", "", [""]], ["_aim", [], [[]]]];

if (isNull _proj) exitWith {};

private _isVehicle = _proj isKindOf "AllVehicles";
if (!_isVehicle && _warhead isEqualTo "") exitWith {triggerAmmo _proj};
if (_warhead isEqualTo "") then {_warhead = LM_WARHEAD_DEF};

private _from = getPosASL _proj;
private _vel = velocity _proj;

// The first surface on the way in, not the aim point - aimPos is inside the
// hull. Found before the projectile goes, so the line can ignore it.
private _at = _from;
private _dir = [];
if (_aim isNotEqualTo []) then {
    _dir = _from vectorFromTo _aim;
    private _surface = ((lineIntersectsSurfaces [_from, _aim, _proj, objNull, true, 1, "FIRE", "GEOM"]) param [0, [_aim]]) select 0;
    if ((_from vectorDistance _surface) > WARHEAD_STANDOFF) then {
        _at = _surface vectorAdd (_dir vectorMultiply -WARHEAD_STANDOFF);
    };
};

if (_isVehicle) then {
    {_proj deleteVehicleCrew _x} forEach (crew _proj);
};
deleteVehicle _proj;

private _w = createVehicle [_warhead, ASLToAGL _at, [], 0, "CAN_COLLIDE"];
_w setPosASL _at;

if (_aim isEqualTo []) then {
    _w setVectorDir _vel;
    _w setVelocity _vel;
} else {
    _w setVectorDir _dir;
    _w setVelocity (_dir vectorMultiply WARHEAD_CREEP);
};

[{if (!isNull _this) then {triggerAmmo _this}}, _w] call CBA_fnc_execNextFrame;
