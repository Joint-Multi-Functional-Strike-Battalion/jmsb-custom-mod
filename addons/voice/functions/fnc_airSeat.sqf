#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: whether the local player is flying an aircraft, kept on his unit as
 * jmfsb_voice_air (public, set only when it changes) for FUNC(a2gNet) on
 * every machine. A2G IS PILOTS (user, 2026-10-20): the driver of an Air
 * vehicle (not a parachute) and anyone in one of its copilot turrets (the
 * turret's config isCopilot) join the A2G net by themselves, and leave it with
 * the seat. Called only on seat changes - GetInMan, GetOutMan,
 * SeatSwitchedMan - and on his Killed and Respawn, plus once at start (a slot
 * that begins in the seat); never per frame. The fill (FUNC(fill)) picks the
 * new A2G net up on its next tick.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * He is in a pilot or copilot seat now <BOOL>
 *
 * Example:
 * [] call jmfsb_voice_fnc_airSeat
 *
 * Public: No
 */

private _unit = player;
if (isNull _unit) exitWith {false};

private _vehicle = vehicle _unit;
private _air = alive _unit && _vehicle isNotEqualTo _unit && {_vehicle isKindOf AIR_KIND} && {!(_vehicle isKindOf PARACHUTE_KIND)};
if (_air && driver _vehicle isNotEqualTo _unit) then {
    private _path = _vehicle unitTurret _unit;
    _air = _path isNotEqualTo [] && {getNumber (([_vehicle, _path] call BIS_fnc_turretConfig) >> "isCopilot") > 0};
};

if (_air isNotEqualTo (_unit getVariable [QGVAR(air), false])) then {
    _unit setVariable [QGVAR(air), _air, true];
    INFO_2("A2G seat: %1 (%2)",_air,typeOf _vehicle);
};

_air
