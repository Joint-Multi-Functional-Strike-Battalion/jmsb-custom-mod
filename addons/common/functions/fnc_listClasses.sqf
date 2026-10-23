#include "script_component.hpp"
/*
 * Author: JMSB
 * Feeder for the Eden class picker (jmfsb_ClassPick_*): every class of a kind,
 * as display rows the picker can filter by side and faction.
 *
 * One config walk per panel open; the picker keeps the result on its display
 * for the filter cycles. Side comes from the class's own `side` where it has
 * one, else from its faction's; a class with neither is side -1, which the
 * picker offers as "no side" rather than hiding.
 *
 * Arguments:
 * 0: Kind <STRING> - "vehicle" | "uav" | "static" | "ammo" | "aircraft" (planes and
 *    helicopters, crewed or drone) | "heli_transport" (crewed helicopters with
 *    passenger seats) | "air_transport" (crewed planes and helicopters with
 *    passenger seats)
 *
 * NOT EVERYTHING IN CONFIG IS THE UNIT'S (user, 2026-10-19). The Aegis and
 * Atlas classes that QAV and the faction ports bring in are hidden though the
 * Aegis mod is not run, and so is any class whose faction is not defined - the
 * leftovers of a mod that is not loaded. LIST_HIDE_SOURCES names the addon
 * fragments that hide a class.
 *
 * Return Value:
 * [[class, display, side <NUMBER>, faction, category, source], ...] <ARRAY>
 *   category: kind-specific - vehicle: "air"/"land"/"sea"/"static",
 *   uav: "air"/"ground", ammo: "shell"/"rocket"/"missile"/"bomb"/"other"
 *
 * Example:
 * ["uav"] call jmfsb_common_fnc_listClasses
 *
 * Public: No
 */

params [["_kind", "vehicle", [""]]];

private _rows = [];
private _facSide = createHashMap;

// HIDDEN SOURCES. A class is dropped when any addon that defines or changes it
// carries one of these fragments in its CfgPatches name.
private _hidden = {
    params ["_cfg"];
    private _src = (configSourceAddonList _cfg) apply {toLower _x};
    (LIST_HIDE_SOURCES findIf {
        private _frag = _x;
        (_src findIf {_frag in _x}) > -1
    }) > -1
};
private _sideOf = {
    params ["_cfg"];
    if (isNumber (_cfg >> "side")) exitWith { getNumber (_cfg >> "side") };
    private _fac = toLower getText (_cfg >> "faction");
    if (_fac isEqualTo "") exitWith {-1};
    private _s = _facSide get _fac;
    if (isNil "_s") then {
        private _fc = configFile >> "CfgFactionClasses" >> _fac;
        _s = if (isNumber (_fc >> "side")) then { getNumber (_fc >> "side") } else { -1 };
        _facSide set [_fac, _s];
    };
    _s
};

if (_kind isEqualTo "ammo") exitWith {
    private _cands = "(configName _x) isKindOf 'ShellBase' || {(configName _x) isKindOf 'RocketBase'} || {(configName _x) isKindOf 'MissileBase'} || {(configName _x) isKindOf 'BombCore'}" configClasses (configFile >> "CfgAmmo");
    {
        private _cn = configName _x;
        private _cat = switch (true) do {
            case (_cn isKindOf "ShellBase"): {"shell"};
            case (_cn isKindOf "RocketBase"): {"rocket"};
            case (_cn isKindOf "MissileBase"): {"missile"};
            case (_cn isKindOf "BombCore"): {"bomb"};
            default {"other"};
        };
        if ([_x] call _hidden) then {continue};
        _rows pushBack [_cn, _cn, -1, "", _cat, (configSourceModList _x) param [0, "A3"]];
    } forEach _cands;
    _rows sort true;
    _rows
};

private _filter = switch (_kind) do {
    // isUav alone is not "a drone": the autonomous turrets, the SAM sites and
    // the radars carry it too, and they were turning up in the drone pickers
    case "uav": {"getNumber (_x >> 'scope') == 2 && {getNumber (_x >> 'isUav') > 0} && {!((configName _x) isKindOf 'StaticWeapon')}"};
    case "static": {"getNumber (_x >> 'scope') == 2 && {(configName _x) isKindOf 'StaticWeapon'}"};
    // AIRCRAFT ONLY for the support modules: a parachute is a Helicopter in
    // config and a quad bike is not an aircraft, and both were in their lists.
    case "aircraft": {"getNumber (_x >> 'scope') == 2 && {((configName _x) isKindOf 'Plane') || {(configName _x) isKindOf 'Helicopter'}} && {!((configName _x) isKindOf 'ParachuteBase')}"};
    case "heli_transport": {"getNumber (_x >> 'scope') == 2 && {(configName _x) isKindOf 'Helicopter'} && {!((configName _x) isKindOf 'ParachuteBase')} && {getNumber (_x >> 'isUav') == 0} && {getNumber (_x >> 'transportSoldier') > 0}"};
    case "air_transport": {"getNumber (_x >> 'scope') == 2 && {((configName _x) isKindOf 'Plane') || {(configName _x) isKindOf 'Helicopter'}} && {!((configName _x) isKindOf 'ParachuteBase')} && {getNumber (_x >> 'isUav') == 0} && {getNumber (_x >> 'transportSoldier') > 0}"};
    default {"getNumber (_x >> 'scope') == 2 && {(configName _x) isKindOf 'LandVehicle' || {(configName _x) isKindOf 'Air'} || {(configName _x) isKindOf 'Ship'} || {(configName _x) isKindOf 'StaticWeapon'}}"};
};
{
    private _cfg = _x;
    private _cn = configName _cfg;
    if ([_cfg] call _hidden) then {continue};
    // A faction that is not defined is a mod that is not loaded.
    private _fac = getText (_cfg >> "faction");
    if (_fac isNotEqualTo "" && {!isClass (configFile >> "CfgFactionClasses" >> _fac)}) then {continue};
    private _dn = getText (_cfg >> "displayName");
    if (_dn isEqualTo "") then { _dn = _cn };
    private _cat = switch (_kind) do {
        case "uav": {["ground", "air"] select (_cn isKindOf "Air")};
        case "aircraft";
        case "heli_transport";
        case "air_transport": {["heli", "plane"] select (_cn isKindOf "Plane")};
        case "static": {"static"};
        default {
            switch (true) do {
                case (_cn isKindOf "Air"): {"air"};
                case (_cn isKindOf "Ship"): {"sea"};
                case (_cn isKindOf "StaticWeapon"): {"static"};
                default {"land"};
            }
        };
    };
    _rows pushBack [_cn, _dn, [_cfg] call _sideOf, getText (_cfg >> "faction"), _cat, (configSourceModList _cfg) param [0, "A3"]];
} forEach (_filter configClasses (configFile >> "CfgVehicles"));
_rows sort true;
_rows
