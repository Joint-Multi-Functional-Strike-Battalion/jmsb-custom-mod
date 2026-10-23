#include "script_component.hpp"
/*
 * Author: JMSB
 * Reads one JMSB - Cruise Missiles module: a launcher at the module's position
 * (a ship, a ground site, or off the map edge) with a stock of missiles.
 *
 * THE MISSILE'S OWN timeToLive IS ITS RANGE. The round is a real projectile
 * and the engine deletes it when its life runs out, so a target further than
 * the missile can fly in that time is refused rather than launched at.
 *
 * Simplex runs a ship's VLS as artillery, so the launcher takes the same
 * fire-mission knobs a battery does: a random response time before the first
 * missile, a cooldown per missile fired on top of the cooldown, and the top
 * of the DELAY stepper.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, [], true] call jmfsb_support_fires_fnc_moduleCruise
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], "", ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};
if (!isServer) exitWith {};
if (_logic in GVAR(entities)) exitWith {};

private _callsign = _logic getVariable ["callsign", ""];

private _cls = _logic getVariable ["missileClass", ""];
if (_cls isEqualTo "") then {_cls = CM_CLASS_DEF};
if !(isClass (configFile >> "CfgAmmo" >> _cls)) exitWith {
    WARNING_2("Cruise Missiles '%1': '%2' is not a CfgAmmo class - no asset placed",_callsign,_cls);
};

private _warhead = _logic getVariable ["warhead", ""];
if (_warhead isNotEqualTo "" && {!isClass (configFile >> "CfgAmmo" >> _warhead)}) then {
    WARNING_2("Cruise Missiles '%1': warhead '%2' is not a CfgAmmo class - the missile's own is used",_callsign,_warhead);
    _warhead = "";
};

private _speed = 50 max (_logic getVariable ["speed", 250]);
private _ttl = getNumber (configFile >> "CfgAmmo" >> _cls >> "timeToLive");
private _reach = [1e7, _speed * (_ttl - CM_BOOST_TIME) * CM_TTL_SHARE] select (_ttl > 0);
private _respMin = 0 max (_logic getVariable ["responseMin", 0]);

_logic setVariable [QGVAR(cls), _cls, true];
_logic setVariable [QGVAR(warhead), _warhead, true];
_logic setVariable [QGVAR(left), 0 max round (_logic getVariable ["missiles", 8]), true];
_logic setVariable [QGVAR(salvo), 1 max round (_logic getVariable ["salvo", 2]), true];
_logic setVariable [QGVAR(speed), _speed, true];
_logic setVariable [QGVAR(altitude), 20 max (_logic getVariable ["altitude", 60]), true];
_logic setVariable [QGVAR(cooldown), 0 max (_logic getVariable ["cooldown", 300]), true];
_logic setVariable [QGVAR(roundCooldown), 0 max (_logic getVariable ["missileCooldown", 0]), true];
_logic setVariable [QGVAR(maxDelay), 0 max round (_logic getVariable ["maxDelay", VA_DEF_MAX_DELAY]), true];
_logic setVariable [QGVAR(response), [_respMin, _respMin max (_logic getVariable ["responseMax", 0])], true];
_logic setVariable [QGVAR(reach), _reach, true];

[_logic, TYPE_CRUISE, _callsign, "TRIDENT"] call FUNC(register);
