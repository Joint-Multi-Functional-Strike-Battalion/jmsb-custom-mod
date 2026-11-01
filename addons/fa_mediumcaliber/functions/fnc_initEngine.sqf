#include "script_component.hpp"
/*
 * Author: YonV
 * Registers programmable-airburst params for this addon's airburst-capable
 * ammo classes and installs the shared CBA fired event handler that every
 * vehicle-weapon ammo addon in the module (this one plus jmfsbfa_maincaliber)
 * feeds into. Direct scale-up of the antidrone fnc_initAntiDrone pattern.
 *
 * Arguments:
 * None (postInit)
 *
 * Return Value:
 * None
 *
 * Public: No
 */

// [trigger radius (m), lethal radius (m), max damage, effective range (m)]
private _p30mm = [10, 7, 0.6, 2000];
private _p35mm = [12, 8, 0.6, 2500];

GVAR(params) = createHashMap;
// Airburst-capable natures register base + every tracer color variant.
{
    _x params ["_base", "_params"];
    GVAR(params) set [_base, _params];
    {
        GVAR(params) set [format ["%1_T_%2", _base, _x], _params];
    } forEach ["Red", "Yellow", "Green", "White", "Blue", "Orange", "IR"];
} forEach [
    // 30mm ABM (defilade defeat)
    ["FA_B_30mm_ABM",  _p30mm],
    // 30mm PROX (counter-UAS)
    ["FA_B_30mm_PROX", _p30mm],
    // 35mm AHEAD (counter-UAS / air defense)
    ["FA_B_35mm_AHEAD", _p35mm]
];

["AllVehicles", "fired", {
    params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_mag", "_proj"];
    // Fired runs on every machine; only the shooter's tracks the round, or
    // the burst and its damage happen once per client.
    if (GVAR(enableAirburst) && {_ammo in GVAR(params)} && {local _proj}) then {
        [_proj, _ammo, _unit] call FUNC(trackShell);
    };
}] call CBA_fnc_addClassEventHandler;
