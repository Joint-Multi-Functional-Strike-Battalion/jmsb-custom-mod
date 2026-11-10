#include "script_component.hpp"
/*
 * Author: YonV
 * The round kind of an ammo class - what a card's Engagement tick asks for
 * (SHELL_KINDS: "he", "smoke", "illum", "cluster", "guided"). The retired
 * Artillery Battery reads its stock from guns and magazines, not from the
 * kind table FUNC(stockFromTable) uses; it stored the class name as the
 * kind, so a ticked shell never matched and was refused NO STORES
 * (2026-11-05). Read from the config, the way the engine tells them apart:
 *
 *   illum    simulation shotIlluminating (a flare)
 *   smoke    simulation shotSmoke / shotSmokeX, or a smoke submunition
 *   guided   a laser or IR seeker (laserLock / irLock) or manual control, on
 *            the shell or the munition it releases
 *   cluster  a spread of submunitions (submunitionConeType: bomblets, mines)
 *   he       anything else
 *
 * Arguments:
 * 0: Ammo class <STRING>
 *
 * Return Value:
 * The kind <STRING>
 *
 * Example:
 * ["Sh_155mm_AMOS"] call jmfsb_support_fires_fnc_ammoKind
 *
 * Public: No
 */

params [["_cls", "", [""]]];

private _cfg = configFile >> "CfgAmmo" >> _cls;
if (!isClass _cfg) exitWith {KIND_HE};

private _sim = toLower getText (_cfg >> "simulation");
private _sub = getText (_cfg >> "submunitionAmmo");
if (isArray (_cfg >> "submunitionAmmo")) then {_sub = (getArray (_cfg >> "submunitionAmmo")) param [0, ""]};
if !(_sub isEqualType "") then {_sub = ""};
private _subSim = toLower getText (configFile >> "CfgAmmo" >> _sub >> "simulation");

private _seeker = {
    params ["_c"];
    getNumber (_c >> "laserLock") > 0 || {getNumber (_c >> "irLock") > 0} || {getNumber (_c >> "manualControl") > 0}
};

switch (true) do {
    case (_sim isEqualTo SIM_ILLUM || _subSim isEqualTo SIM_ILLUM): {KIND_ILLUM};
    case (_sim in SIM_SMOKE || _subSim in SIM_SMOKE): {KIND_SMOKE};
    case ([_cfg] call _seeker || {_sub isNotEqualTo "" && {[configFile >> "CfgAmmo" >> _sub] call _seeker}}): {KIND_GUIDED};
    case (isArray (_cfg >> "submunitionConeType")): {KIND_CLUSTER};
    default {KIND_HE};
}
