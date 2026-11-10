#include "script_component.hpp"
/*
 * Author: YonV
 * What a vehicle carries: its hard-kill fit, whether it has the RF emitter,
 * and what the crew calls the fit. THE TIER TABLE (user, 2026-08-28):
 *
 *            tank         cannon IFV   other APC    MRAP        helicopter
 *   t0-1     -            -            -            -           -
 *   t2       BASIC        BASIC        -            -           -         near-peer: limited, tanks and some APCs
 *   t3       HEAVY +RF    MEDIUM       LIGHT        LIGHT       -         peer: more
 *   t4       ENHANCED+RF  HEAVY +RF    MEDIUM +RF   LIGHT +RF   RF        peer+: complete
 *
 * Artillery, MLRS and mortar carriers get nothing at any tier. A class the
 * module names in Fit Overrides gets exactly what it says.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * [fit <STRING>, RF emitter <BOOL>, display name <STRING>] - fit "NONE" and
 * false for a vehicle that carries nothing
 *
 * Example:
 * [_tank] call jmfsb_aps_fnc_fitFor
 *
 * Public: Yes
 */

params [["_veh", objNull, [objNull]]];
if (isNull _veh) exitWith { [FIT_NONE, false, ""] };

private _cls = toLower typeOf _veh;
private _tier = [_veh] call FUNC(tierOf);
private _brand = GVAR(brands) getOrDefault [side (group _veh), "APS"];
// CHINA CALLS IT THE GL-5, not east's Afganit. The test read "pla" - the PLA
// pack's own factions - and stopped matching anything when that pack left the
// load order and China moved to jmfsb_China (2026-08-31).
if ("china" in toLower (getText (configOf _veh >> "faction"))) then { _brand = "GL-5" };

private _name = {
    params ["_fit"];
    if (_fit isEqualTo FIT_NONE) exitWith { "" };
    format ["%1 %2", _brand, GVAR(grades) getOrDefault [_fit, ""]]
};

// the module's word beats the table
private _over = GVAR(fitOverride) get _cls;
if (!isNil "_over") exitWith {
    _over params ["_fit", "_rf"];
    [_fit, _rf, [_fit] call _name]
};

// ---- what kind of vehicle this is --------------------------------------
// _this IS the word array. params ["_words"] took _this SELECT 0 - the first
// string - and findIf then threw "Type String, expected Array" on every
// vehicle, so fitFor returned nothing and no vehicle was ever fitted.
private _has = { _this findIf { _x in _cls } > -1 };

// the guns and the rocket carriers get nothing; the AA vehicles stay -
// Tigris, the PGL-625E, Guardian and Bardelas are APCs to a rocket
if (["arty", "mlrs", "mortar"] call _has) exitWith { [FIT_NONE, false, ""] };

private _kind = "";
if (_veh isKindOf "Helicopter") then { _kind = "heli" };
if (_kind isEqualTo "" && {["mbt_", "abramsx", "leopard", "merkava", "karakurt", "tarantul"] call _has}) then { _kind = "tank" };
if (_kind isEqualTo "" && {["apc_", "ztl", "625e", "aav9", "gyra", "lt_01", "afv_wheeled", "patria", "warrior", "bardelas"] call _has}) then {
    _kind = ["apc", "ifv"] select (["cannon", "30mm", "50mm", "57mm", "bofor", "ztl", "gyra_armed", "atgm", "rcws_v2"] call _has);
};
if (_kind isEqualTo "" && {["mrap_", "strider", "fennek"] call _has}) then { _kind = "mrap" };
if (_kind isEqualTo "") exitWith { [FIT_NONE, false, ""] };

// ---- the table -----------------------------------------------------------
private _fit = FIT_NONE;
private _rf = false;
switch (true) do {
    case (_tier <= 1): {};
    case (_tier == 2): {
        if (_kind in ["tank", "ifv"]) then { _fit = FIT_BASIC };
    };
    case (_tier == 3): {
        _fit = switch (_kind) do {
            case "tank": { _rf = true; FIT_HEAVY };
            case "ifv": { FIT_MEDIUM };
            case "apc"; case "mrap": { FIT_LIGHT };
            default { FIT_NONE };
        };
    };
    default {
        _fit = switch (_kind) do {
            case "tank": { FIT_ENHANCED };
            case "ifv": { FIT_HEAVY };
            case "apc": { FIT_MEDIUM };
            case "mrap": { FIT_LIGHT };
            default { FIT_NONE };
        };
        _rf = _kind isNotEqualTo "heli" || GVAR(rfAir);
    };
};
if (!GVAR(hardKill)) then { _fit = FIT_NONE };
if (!GVAR(rfBurst)) then { _rf = false };

[_fit, _rf, [_fit] call _name]
