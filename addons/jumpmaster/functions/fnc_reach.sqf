#include "script_component.hpp"
/*
 * Author: YonV
 * Whether a jump aircraft can take a jump now - the "reach" code this addon
 * hands the support core (2026-11-02), read for TAC//MSG's TO picker. It can
 * unless the viewer's own squad has a run up (TASKED, one per squad), or -
 * a JMSB - Jump Aircraft module's (user, 2026-11-02) - its aircraft flies a
 * run, it has no airframe left, a loss's Respawn Delay runs, it flies home, or
 * its cooldown runs (FUNC(asset)). Its ETA: a module's aircraft while one is
 * made, from where it is to the point; a module's virtual one (user,
 * 2026-11-02: virtual until tasked) from the module to the point at cruise;
 * else WHEELS UP to the red light (FUNC(runEta)). Its effect the altitudes it
 * flies. Cheap: published values and the class.
 *
 * Arguments:
 * 0: Asset id, "jump:<n>" or "jump:<side>" <STRING>
 * 1: The point asked about - a module's airframe's ETA to it (optional) <ARRAY>
 *
 * Return Value:
 * [can, eta, why, effect, tasks] <ARRAY>
 *
 * Example:
 * ["jump:0", getPosATL player] call jmfsb_jumpmaster_fnc_reach
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_point", [], [[]]]];

private _asset = [_assetId] call FUNC(asset);
if ((count _asset) isEqualTo 0) exitWith {[false, ETA_UNKNOWN, WHY_NO_AIRCRAFT, "", []]};

private _why = _asset get "why";
if (((group player) getVariable [QGVAR(run), []]) isNotEqualTo []) then {_why = WHY_TASKED};
private _can = _why isEqualTo "";
(_asset get "alts") params ["_halo", "_haho", "_static"];
private _veh = _asset getOrDefault ["veh", objNull];
private _logic = _asset getOrDefault ["logic", objNull];
private _eta = switch (true) do {
    case (alive _veh && count _point >= 2): {[_veh, _point] call EFUNC(support,etaTo)};
    // VIRTUAL UNTIL TASKED (user, 2026-11-02): made over the module, so from
    // there to the point at the class's cruise.
    case (!isNull _logic && count _point >= 2): {[_asset get "cls", _logic distance2D _point] call FUNC(runEta)};
    default {[_asset get "cls"] call FUNC(runEta)};
};

[
    _can,
    _eta,
    _why,
    format [REACH_EFFECT, _halo, _haho, _static],
    [[], [JUMP_TASK]] select _can
]
