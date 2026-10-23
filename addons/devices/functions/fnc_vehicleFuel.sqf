#include "script_component.hpp"
/*
 * Author: JMSB
 * A vehicle's fuel and a rough range on what is left.
 *
 * THE RANGE IS MEASURED, NOT CONFIGURED. A vehicle's config carries a tank
 * size but nothing that says what a kilometre costs, and the engine's burn
 * depends on how it is driven. So the vehicle keeps a local note - the fuel at
 * the last fill and the ground covered since - and the range is what is left at
 * the rate it has actually been burning: fuel x metres / fuel burnt. Until
 * FUEL_SAMPLE_MIN has gone over RANGE_SAMPLE_MIN_M metres there is no rate to
 * speak of and the range is -1 (the page says MEASURING).
 *
 * ANY RISE IS A REFILL, PARTIAL OR NOT. The note also keeps the lowest fuel
 * read since the last fill, and fuel more than FUEL_REFILL_EPS over that low
 * starts the note again at the new level. Measured against the level at the
 * last fill instead, a top-up to less than that (or back to exactly it) was
 * never seen: the burn shrank to almost nothing over the previous tank's
 * metres and the range read many times too long. Against the low, a slow
 * refuel (ACE's, a little per read) still adds up past the epsilon.
 *
 * Ground covered is the straight line between reads, so the note grows while
 * the vehicle tablet is up (its tile reads this every two seconds) and a long
 * drive with it closed counts as the line from where it was to where it is -
 * short, which makes the range a little pessimistic. Rough, as asked.
 *
 * The note is local to this client: nothing else needs it and it is not worth
 * a network message.
 *
 * Arguments:
 * 0: The vehicle <OBJECT>
 *
 * Return Value:
 * 0: Fuel 0..1 <NUMBER>
 * 1: Range in metres, -1 while measuring <NUMBER>
 *
 * Example:
 * [vehicle player] call jmfsb_devices_fnc_vehicleFuel
 *
 * Public: No
 */

params [["_vehicle", objNull, [objNull]]];
if (isNull _vehicle) exitWith {[0, -1]};

private _fuel = fuel _vehicle;
private _pos = getPosASL _vehicle;

private _note = _vehicle getVariable [QGVAR(fuelNote), []];
if !(_note isEqualType []) then {_note = []};
_note params [["_fuelFill", -1, [0]], ["_metres", 0, [0]], ["_last", [], [[]]], ["_fuelLow", -1, [0]]];

if (_fuelFill < 0 || _fuelLow < 0 || {_fuel > _fuelLow + FUEL_REFILL_EPS}) then {
    _fuelFill = _fuel;
    _fuelLow = _fuel;
    _metres = 0;
} else {
    _fuelLow = _fuelLow min _fuel;
    if (_last isNotEqualTo []) then {
        _metres = _metres + (_last distance2D _pos);
    };
};
_vehicle setVariable [QGVAR(fuelNote), [_fuelFill, _metres, _pos, _fuelLow]];

private _burnt = _fuelFill - _fuel;
private _range = if (_burnt >= FUEL_SAMPLE_MIN && _metres >= RANGE_SAMPLE_MIN_M) then {
    _fuel * _metres / _burnt
} else {
    -1
};

[_fuel, _range]
