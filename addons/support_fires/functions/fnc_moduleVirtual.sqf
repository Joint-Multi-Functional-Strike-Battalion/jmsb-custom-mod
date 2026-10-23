#include "script_component.hpp"
/*
 * Author: JMSB
 * Reads one JMSB - Virtual Artillery module: a battery at the module's
 * position, on or off the map, with no gun objects anywhere. The artillery
 * module mission makers place (user, 2026-10-20: "arty should be virtual").
 *
 * THE STOCK IS THE MODULE'S: each round type it names a class for and gives
 * rounds to (FUNC(stockFromTable)). FUNC(virtualShot) takes rounds off it as
 * they are fired. Everything else is read by FUNC(setupBattery).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, [], true] call jmfsb_support_fires_fnc_moduleVirtual
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], "", ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};
if (!isServer) exitWith {};
if (_logic in GVAR(entities)) exitWith {};

[
    _logic,
    [_logic] call FUNC(stockFromTable),
    _logic getVariable ["guns", VA_DEF_GUNS],
    getPosATL _logic,
    _logic getVariable ["muzzleVelocity", VA_DEF_MV],
    _logic getVariable ["minRange", VA_DEF_MIN_RANGE],
    _logic getVariable ["maxRange", VA_DEF_MAX_RANGE],
    "VIRTUAL BATTERY",
    "THUNDER"
] call FUNC(setupBattery);
