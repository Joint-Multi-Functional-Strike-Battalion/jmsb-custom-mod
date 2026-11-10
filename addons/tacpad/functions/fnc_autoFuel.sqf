#include "script_component.hpp"
/*
 * Author: YonV
 * Autofill source "vehicleFuel" (report-card review, user 2026-11-02, D18):
 * the fuel of the vehicle the sender is in, as the DEFREP's FUEL line words
 * it - GREEN at least half, YELLOW at least a quarter, RED any, BLACK empty.
 * A vehicle that carries no fuel (a static weapon) gives none.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * The state word, "" on foot or for a vehicle without fuel <STRING>
 *
 * Example:
 * [] call jmfsb_tacpad_fnc_autoFuel
 *
 * Public: No
 */

private _veh = vehicle player;
if (_veh isEqualTo player) exitWith {""};
if (getNumber (configOf _veh >> "fuelCapacity") <= 0) exitWith {""};

private _fuel = fuel _veh;

switch (true) do {
    case (_fuel >= AUTO_FUEL_HALF): {AUTO_GREEN};
    case (_fuel >= AUTO_FUEL_QUARTER): {AUTO_YELLOW};
    case (_fuel > 0): {AUTO_RED};
    default {AUTO_BLACK};
}
