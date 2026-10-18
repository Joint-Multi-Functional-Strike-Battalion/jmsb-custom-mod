#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Reports one relevant round to the server, from the machine that fired it,
 * and keeps the round so the server can ask for it to be killed (FUNC(kill)).
 *
 * One message per artillery shell, rocket, missile or bomb - never per bullet -
 * and none at all when the shooter is the server's own AI (a local event).
 *
 * Arguments:
 * 0: Shot id <STRING>
 * 1: Shooter <OBJECT>
 * 2: Projectile <OBJECT>
 * 3: [family, speed] (FUNC(family)) <ARRAY>
 *
 * Return Value: None
 *
 * Example:
 * ["2:14", _gunner, _proj, [1, 200]] call jmfsb_adsite_fnc_shot
 *
 * Public: No
 */

params ["_id", "_owner", "_proj", "_info"];

if (isNull _proj) exitWith {};

// a guided missile goes where its target is
private _target = [];
if ((_info select 0) == FAM_MISSILE) then {
    private _locked = missileTarget _proj;
    if (!isNull _locked) then { _target = getPosASL _locked };
};

// landed rounds leave the map whenever it grows past its cap
if (count GVAR(owned) >= ADS_OWNED_CAP) then {
    private _gone = [];
    { if (isNull _y) then { _gone pushBack _x } } forEach GVAR(owned);
    { GVAR(owned) deleteAt _x } forEach _gone;
};
GVAR(owned) set [_id, _proj];

[QGVAR(threat), [_id, _owner, getPosASL _proj, velocity _proj, _info, _target, side group _owner]] call CBA_fnc_serverEvent;
