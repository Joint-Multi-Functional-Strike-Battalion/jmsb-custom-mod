#include "script_component.hpp"
/*
 * Author: YonV
 * The engineer profile's readout. A mine or explosive: its type, its trigger
 * as its class tells it (pressure, tripwire, remote, timed), its distance. A
 * vehicle (design engineer.vehicle_look): damaged parts and fuel, ammunition
 * left, ACE cargo space, and whether the player carries a toolkit to repair it.
 *
 * Arguments:
 * 0: Target <OBJECT>
 *
 * Return Value:
 * [name, state word, colour, [line 2, line 3], live] <ARRAY>
 *
 * Example:
 * [_obj] call jmfsb_watch_fnc_engineerRow
 *
 * Public: No
 */

params [["_obj", objNull, [objNull]]];

private _name = toUpper ([_obj, "threat"] call FUNC(contactName));
if (_obj in allMines) exitWith {
    private _class = toLower typeOf _obj;
    private _trigger = switch (true) do {
        case ("trip" in _class): {"TRIPWIRE"};
        case ("remote" in _class || {"ied" in _class} || {"satchel" in _class} || {"demo" in _class}): {"REMOTE"};
        case ("timer" in _class || {"timed" in _class}): {"TIMED"};
        default {"PRESSURE"};
    };
    [_name, ["SAFE", "ARMED"] select (mineActive _obj), COLOUR_AMBER,
        [format ["TRIGGER %1", _trigger], format ["DIST %1 M", round (player distance _obj)]], true]
};

private _damaged = {_x > DAMAGED_PART} count ((getAllHitPointsDamage _obj) param [2, []]);
private _mags = magazinesAllTurrets _obj;
private _rounds = 0;
private _full = 0;
{
    _rounds = _rounds + (_x # 2);
    _full = _full + getNumber (configFile >> "CfgMagazines" >> (_x # 0) >> "count");
} forEach _mags;
private _cargo = _obj getVariable ["ace_cargo_space", -1];
[
    toUpper getText (configOf _obj >> "displayName"),
    ["DAMAGED", "OK"] select (_damaged isEqualTo 0),
    [COLOUR_AMBER, COLOUR_GREEN] select (_damaged isEqualTo 0),
    [
        format ["DMG %1 PARTS   FUEL %2%3", _damaged, round (fuel _obj * 100), "%"],
        format ["AMMO %1   CARGO %2   TOOLKIT %3",
            [format ["%1%2", round (_rounds / (_full max 1) * 100), "%"], "-"] select (_mags isEqualTo []),
            ["-", str _cargo] select (_cargo >= 0),
            ["NO", "YES"] select ("ToolKit" in items player)]
    ],
    alive _obj
]
