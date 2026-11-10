#include "script_component.hpp"
/*
 * Author: YonV
 * Registers proximity-airburst params for all PAB ammo classes and installs
 * the CBA fired event handler that triggers per-round proximity tracking.
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
// Rifle/HMG PAB rounds rebalanced: radii and damage halved (2026-08). The
// 40mm Mk364 keeps its original envelope — it is the dedicated C-UAS payload.
// 5.56/7.62 radii halved again (2026-08) — realism pass: a bullet-sized frag
// sleeve shouldn't reach much past half a metre.
private _p556  = [0.875, 0.625, 0.25, 500];
private _p762  = [1,     0.75,  0.25, 800];
private _p300  = [1.75, 1.25, 0.25, 300];
private _p40mm = [6,    4.5,  0.5,  400];
private _p50   = [2.5,  1.75, 0.25, 1500];
private _p65   = [1.75, 1.25, 0.25, 600];
private _p338  = [2.25, 1.5,  0.25, 1500];
// 12ga Mk363 PABS — heavy dedicated AD slug; short shotgun reach.
private _p12g  = [2.25, 1.5,  0.25, 150];

GVAR(AD_params) = createHashMapFromArray [
    // 5.56 Mk361
    ["FA_b_556_Mk361_PAB",          _p556],
    ["FA_b_556_Mk361_PAB_T_Red",    _p556],
    ["FA_b_556_Mk361_PAB_T_Yellow", _p556],
    ["FA_b_556_Mk361_PAB_T_Green",  _p556],
    ["FA_b_556_Mk361_PAB_T_White",  _p556],
    ["FA_b_556_Mk361_PAB_T_Blue",   _p556],
    ["FA_b_556_Mk361_PAB_T_Orange", _p556],
    // 7.62 Mk362
    ["FA_b_762_Mk362_PAB",          _p762],
    ["FA_b_762_Mk362_PAB_T_Red",    _p762],
    ["FA_b_762_Mk362_PAB_T_Yellow", _p762],
    ["FA_b_762_Mk362_PAB_T_Green",  _p762],
    ["FA_b_762_Mk362_PAB_T_White",  _p762],
    ["FA_b_762_Mk362_PAB_T_Blue",   _p762],
    ["FA_b_762_Mk362_PAB_T_Orange", _p762],
    // .300 BLK Mk363
    ["FA_b_300_Mk363_PAB",          _p300],
    ["FA_b_300_Mk363_PAB_T_Red",    _p300],
    ["FA_b_300_Mk363_PAB_T_Yellow", _p300],
    ["FA_b_300_Mk363_PAB_T_Green",  _p300],
    ["FA_b_300_Mk363_PAB_T_White",  _p300],
    ["FA_b_300_Mk363_PAB_T_Blue",   _p300],
    ["FA_b_300_Mk363_PAB_T_Orange", _p300],
    // 40mm Mk364 (no tracer variants)
    ["FA_b_40mm_Mk364_PAB",         _p40mm],
    // .50 Mk366
    ["FA_b_127_Mk366_PAB",          _p50],
    ["FA_b_127_Mk366_PAB_T_Red",    _p50],
    ["FA_b_127_Mk366_PAB_T_Yellow", _p50],
    ["FA_b_127_Mk366_PAB_T_Green",  _p50],
    ["FA_b_127_Mk366_PAB_T_White",  _p50],
    ["FA_b_127_Mk366_PAB_T_Blue",   _p50],
    ["FA_b_127_Mk366_PAB_T_Orange", _p50],
    // 6.5 caseless Mk367
    ["FA_b_65_Mk367_PAB",          _p65],
    ["FA_b_65_Mk367_PAB_T_Red",    _p65],
    ["FA_b_65_Mk367_PAB_T_Yellow", _p65],
    ["FA_b_65_Mk367_PAB_T_Green",  _p65],
    ["FA_b_65_Mk367_PAB_T_White",  _p65],
    ["FA_b_65_Mk367_PAB_T_Blue",   _p65],
    ["FA_b_65_Mk367_PAB_T_Orange", _p65],
    // .338 Mk373
    ["FA_b_338_Mk373_PAB",          _p338],
    ["FA_b_338_Mk373_PAB_T_Red",    _p338],
    ["FA_b_338_Mk373_PAB_T_Yellow", _p338],
    ["FA_b_338_Mk373_PAB_T_Green",  _p338],
    ["FA_b_338_Mk373_PAB_T_White",  _p338],
    ["FA_b_338_Mk373_PAB_T_Blue",   _p338],
    ["FA_b_338_Mk373_PAB_T_Orange", _p338],
    // 12ga Mk363 PABS (no tracer variants — slug fired from shotgun)
    ["FA_b_12G_Mk363_PABS",         _p12g]
];

// Ammo classes whose dialled airburst range (fnc_setBurst) is honoured by
// fnc_trackAD. Other components append theirs (e.g. the MAAWS HE 448 AB).
GVAR(programmableAB) = ["FA_b_40mm_Mk364_PAB"];

["CAManBase", "fired", {
    params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_mag", "_proj"];
    // Fired runs on every machine; only the shooter's tracks the round, or
    // the burst, its damage and the ACE frag happen once per client.
    if (_ammo in GVAR(AD_params) && {local _proj}) then {
        [_proj, _ammo, _unit] call FUNC(trackAD);
    };
}] call CBA_fnc_addClassEventHandler;

// Mk364 programmable airburst — key to cycle the dialled slant range. Mirrors
// the ACE self-interaction submenu (CfgVehicles.hpp). Unbound by default.
if (hasInterface) then {
    [
        "1st Joint Multi-Functional Strike Battalion",
        QGVAR(cycleBurst),
        ["Mk364: Cycle Airburst Range", "Cycles the 40mm Mk364 programmable airburst slant range (Off / 100 / 150 / 200 / 250 / 300 / 400 m)."],
        { call FUNC(cycleBurst); false },
        {false},
        []
    ] call CBA_fnc_addKeybind;
};
