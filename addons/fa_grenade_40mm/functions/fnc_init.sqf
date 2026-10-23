#include "script_component.hpp"
/*
 * Author: YonV
 * Builds the Mk380 support registry and installs the CBA fired event handler.
 * Safe to call multiple times; exits immediately if already initialised.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Public: No
 */
if (GVAR(initDone)) exitWith {};
GVAR(initDone) = true;

GVAR(hasACRE) = isClass (configFile >> "CfgPatches" >> "acre_main");
GVAR(hasDEW)  = isClass (configFile >> "CfgPatches" >> "DEW_main") ||
                {isClass (configFile >> "CfgPatches" >> "Drongo_EW")};

GVAR(relays) = [];

// Registry: ammo class -> [deploy mode, effect function, lifetime (s), radius (m)]
// CHUTE = HuntIR-style: pops a parachute at apex and floats the payload down,
// then runs the effect at the landing point. No explosion on any of these.
GVAR(registry) = createHashMapFromArray [
    ["FA_40mm_Mk380_NRP",    ["CHUTE", FUNC(relay),   1800, 5000]],
    ["FA_40mm_Mk383_EMP",    ["CHUTE", FUNC(emp),        8,   60]],
    ["FA_40mm_Mk384_MSmoke", ["CHUTE", FUNC(msmoke),    60,   25]],
    ["FA_40mm_Mk385_Decoy",  ["CHUTE", FUNC(decoy),    120,  300]],
    ["FA_40mm_Mk386_UGS",    ["CHUTE", FUNC(ugs),     1800,  150]],
    ["FA_40mm_Mk388_Jammer", ["CHUTE", FUNC(jammer),   900,  400]]
];

["CAManBase", "fired", {
    params ["_unit", "_w", "_m", "_md", "_ammo", "_mag", "_proj"];
    private _entry = GVAR(registry) getOrDefault [_ammo, []];
    if (_entry isEqualTo []) exitWith {};
    [_unit, _proj, _entry] call FUNC(handle);
}] call CBA_fnc_addClassEventHandler;
