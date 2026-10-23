#include "script_component.hpp"
/*
 * Author: JMSB
 * How long an airframe takes to fly a route at one of the SPEED words - the
 * estimate the verdict before CONFIRM (FUNC(preview)) reads. The AI is taken
 * to hold ETA_SHARES of the class's top speed at each word; the route is
 * flown point to point, over the ground.
 *
 * Arguments:
 * 0: Aircraft class <STRING>
 * 1: The route, positions in the order flown <ARRAY>
 * 2: Speed index into SPEED_WORDS <NUMBER> (optional, default 0 - NORMAL)
 *
 * Return Value:
 * Seconds, 0 when the class has no top speed <NUMBER>
 *
 * Example:
 * ["B_Heli_Transport_01_F", [_home, _lz], 0] call jmfsb_support_air_fnc_flightTime
 *
 * Public: No
 */

params [["_cls", "", [""]], ["_route", [], [[]]], ["_speed", SPEED_NORMAL, [0]]];

private _ms = getNumber (configFile >> "CfgVehicles" >> _cls >> "maxSpeed") / KMH_PER_MS * (ETA_SHARES param [_speed, ETA_SHARES select SPEED_NORMAL]);
if (_ms <= 0) exitWith {0};

private _dist = 0;
for "_i" from 1 to (count _route - 1) do {
    _dist = _dist + ((_route select (_i - 1)) distance2D (_route select _i));
};

_dist / _ms
