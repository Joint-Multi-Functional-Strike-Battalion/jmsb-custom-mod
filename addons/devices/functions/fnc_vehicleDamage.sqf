#include "script_component.hpp"
/*
 * Author: JMSB
 * A vehicle's damage by part, grouped the way a crew says it: HULL, ENGINE,
 * FUEL, OPTICS, TURRET, GUN, TRACKS or WHEELS, ROTORS, AVIONICS, CONTROLS,
 * ARMOUR, GLASS and whatever is left as OTHER.
 *
 * READ OFF getAllHitPointsDamage, the engine's own per-part table, so any land
 * vehicle, aircraft or boat answers with the parts it has and nothing it does
 * not - a car has no TURRET row, a helicopter has ROTORS. Each hit point goes to
 * the first group in DAMAGE_GROUPS whose fragment its name contains; lights are
 * not parts and are left out.
 *
 * A GROUP IS AS BAD AS ITS WORST PART. One track at 100% is a vehicle that does
 * not move, however healthy the other one is - so the worst damage is what the
 * row is coloured by, and the count of hit parts says how many.
 *
 * Arguments:
 * 0: The vehicle <OBJECT>
 *
 * Return Value:
 * One entry per group present, in DAMAGE_GROUPS order (VEHICLE STATUS then
 * sorts them worst first, FUNC(vehicleLines)):
 * [label <STRING>, worst damage 0..1 <NUMBER>, parts at or past DAMAGE_WARN <NUMBER>, parts <NUMBER>] <ARRAY>
 *
 * Example:
 * [vehicle player] call jmfsb_devices_fnc_vehicleDamage
 *
 * Public: No
 */

params [["_vehicle", objNull, [objNull]]];
if (isNull _vehicle) exitWith {[]};

(getAllHitPointsDamage _vehicle) params [["_names", [], [[]]], "", ["_damages", [], [[]]]];

private _groups = DAMAGE_GROUPS;
private _skip = DAMAGE_SKIP;
private _found = createHashMap;

{
    private _name = toLower _x;
    private _damage = _damages param [_forEachIndex, 0];
    if (_name isEqualTo "" || {(_skip findIf {(_name find _x) >= 0}) >= 0}) then {continue};

    private _index = _groups findIf {
        private _fragments = _x select 1;
        (_fragments findIf {(_name find _x) >= 0}) >= 0
    };
    if (_index < 0) then {continue};

    (_found getOrDefault [_index, [0, 0, 0]]) params ["_worst", "_hit", "_parts"];
    _found set [_index, [
        _worst max _damage,
        _hit + parseNumber (_damage >= DAMAGE_WARN),
        _parts + 1
    ]];
} forEach _names;

private _out = [];
{
    private _entry = _found getOrDefault [_forEachIndex, []];
    if (_entry isEqualTo []) then {continue};
    _out pushBack ([_x select 0] + _entry);
} forEach _groups;

_out
