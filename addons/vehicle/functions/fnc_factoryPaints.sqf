#include "script_component.hpp"
/*
 * Author: YonV
 * The paint schemes a vehicle's own config offers - its TextureSources - as
 * cosmetic entries, for every vehicle the catalogue has no paint for.
 *
 * THE CATALOGUE COVERED TEN VEHICLES AND THE MOTORPOOL HAS SIXTY (user,
 * 2026-10-08: "the customisations for a lot of vehicles are missing"). Nearly
 * every vehicle already declares what it can be painted - vanilla's Hunter has
 * Green and Sand, the Aegis and Atlas ports carry a camo per theatre, our own
 * factions add "Factory paint" - and nobody has to type those out: this reads
 * them from CfgVehicles at the moment the menu is built.
 *
 * THE UNIT'S OWN LIST WINS. A vehicle with at least one hand-written paint in
 * the catalogue is left alone - its curated set is the point - so this fills
 * the gaps and never doubles a Hunter that already has "Green Paint".
 * Fittings ("Toggle ...") do not count as paint.
 *
 * Arguments:
 * 0: Vehicle class <STRING>
 * 1: The catalogue so far, as FUNC(cosmeticEntries) returns it <ARRAY>
 *
 * Return Value:
 * Entries to append, ["class", "Display Name", ["", code]] each <ARRAY>
 *
 * Example:
 * ["B_MRAP_01_F", call jmfsb_vehicle_fnc_cosmeticEntries] call jmfsb_vehicle_fnc_factoryPaints
 *
 * Public: No
 */

params [["_class", "", [""]], ["_catalogue", [], [[]]]];

if (_class isEqualTo "") exitWith {[]};

// Already painted by hand? Then not by us.
private _curated = _catalogue findIf {
    _x params ["_base", "_label"];
    _class isKindOf _base && {(_label select [0, 6]) isNotEqualTo "Toggle"}
};
if (_curated >= 0) exitWith {[]};

// Per class, once: the config does not change under a running mission.
private _cache = missionNamespace getVariable [QGVAR(factoryPaintCache), createHashMap];
if (_class in _cache) exitWith {_cache get _class};

private _out = [];
private _sources = configProperties [configFile >> "CfgVehicles" >> _class >> "TextureSources", "isClass _x", true];
{
    private _textures = getArray (_x >> "textures");
    private _label = getText (_x >> "displayName");
    if (_label isEqualTo "") then {_label = configName _x};
    if (_textures isEqualTo []) then {continue};

    // The entry's code reads `_vehicle` from the caller, as every catalogue
    // entry does; the texture list is baked in as the index map applyTextures
    // takes - [[0, "a.paa"], [1, "b.paa"], ...].
    private _map = [];
    {
        _map pushBack [_forEachIndex, _x];
    } forEach _textures;
    private _code = compile format ["[_vehicle, %1] call jmfsb_vehicle_fnc_applyTextures", str _map];
    _out pushBack [_class, _label, ["", _code]];
} forEach _sources;

// Only one scheme means there is nothing to choose between.
if (count _out < 2) then {_out = []};

_cache set [_class, _out];
missionNamespace setVariable [QGVAR(factoryPaintCache), _cache];

TRACE_INFO_2("VehicleCosmetics","%1 factory paint(s) for %2 from its TextureSources",count _out,_class);
_out
