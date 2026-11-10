#include "script_component.hpp"
/*
 * Author: YonV
 * Whether a transport can still fly, and if not, which test failed and what
 * the airframe looked like - the verdict the transport's watch
 * (FUNC(transportTick)) writes an airframe off on, and the words it does it
 * with.
 *
 * THE TESTS, in order: nobody in the pilot's seat, the pilot dead, canMove
 * false (too damaged to fly). The first that fails is the reason.
 *
 * THE STATE IS FOR THE RPT (2026-11-01). RAVEN was written off over Tanoa
 * with "cannot fly" and "lost ... to ''" and nothing else - no seat, no hit
 * point, no killer - so the RPT could not say whether a pilot was shot, a
 * rotor was hit or the check itself was wrong. Now the line carries the
 * overall damage, every hit point past FAULT_HIT_FLOOR, fuel, engine, height,
 * speed, whether it is on the ground, the crew still alive, and the last thing
 * that hit it (QGVAR(lastHit), recorded by FUNC(prepareAircraft)).
 *
 * Arguments:
 * 0: The aircraft <OBJECT>
 *
 * Return Value:
 * 0: Why it cannot fly, "" when it can <STRING>
 * 1: Its state, "" when it can fly <STRING>
 * 2: The last thing that hit it, objNull for nothing <OBJECT>
 *
 * Example:
 * ([_veh] call jmfsb_support_air_fnc_flightFault) params ["_fault", "_state", "_hitBy"]
 *
 * Public: No
 */

// Decimals a damage value is written with.
#define FAULT_DECIMALS 2

params [["_veh", objNull, [objNull]]];

if (isNull _veh) exitWith {["the airframe is gone", "", objNull]};

private _driver = driver _veh;
private _fault = switch (true) do {
    case (isNull _driver): {"nobody in the pilot's seat"};
    case (!alive _driver): {format ["the pilot ('%1') is dead", typeOf _driver]};
    case (!canMove _veh): {"canMove false - too damaged to fly"};
    default {""};
};
if (_fault isEqualTo "") exitWith {["", "", objNull]};

(getAllHitPointsDamage _veh) params [["_names", []], "", ["_values", []]];
private _hits = [];
{
    if (_x > FAULT_HIT_FLOOR) then {
        _hits pushBack format ["%1 %2", _names param [_forEachIndex, "?"], _x toFixed FAULT_DECIMALS];
    };
} forEach _values;

private _crew = crew _veh;
(_veh getVariable [QGVAR(lastHit), []]) params [["_hitBy", objNull], ["_instigator", objNull], ["_hitAt", -1]];
private _hitText = if (_hitAt < 0) then {"never hit"} else {
    format ["last hit by '%1' (instigator '%2') %3 s before", typeOf _hitBy, typeOf _instigator, round (CBA_missionTime - _hitAt)]
};

private _state = format [
    "damage %1; hit points %2; fuel %3, engine %4, %5 m up, %6 km/h, %7; crew %8 alive of %9; %10",
    (damage _veh) toFixed FAULT_DECIMALS,
    ["none past the floor", _hits joinString ", "] select (_hits isNotEqualTo []),
    (fuel _veh) toFixed FAULT_DECIMALS,
    ["off", "on"] select (isEngineOn _veh),
    round ((getPos _veh) select 2),
    round (speed _veh),
    ["in the air", "on the ground"] select (isTouchingGround _veh),
    {alive _x} count _crew,
    count _crew,
    _hitText
];

[_fault, _state, _hitBy]
