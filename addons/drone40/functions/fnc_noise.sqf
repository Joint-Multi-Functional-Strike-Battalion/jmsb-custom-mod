#include "script_component.hpp"
/*
 * Author: JMSB
 * RF noise source (jmfsb_rf_fnc_addNoiseSource), server: what every powered
 * Drone40 Jammer puts into a receiver on VHF and UHF - the jammer power
 * setting plus the whip's gain, less the band's clear-ground path loss to the
 * receiver (jmfsb_rf_fnc_pathLossFree). Barrage, so the receiver's spread
 * gain applies. Nothing past the radius setting counts. Called per receiver
 * per net per tick: no raycasts.
 *
 * Arguments:
 * 0: Receiver position ASL <ARRAY>
 * 1: Band <STRING>
 * 2: Net id <STRING>
 *
 * Return Value:
 * Contributions [[dBm at the receiver, spreadApplies], ...] <ARRAY>
 *
 * Example:
 * [eyePos player, "UHF", "DATA"] call jmfsb_drone40_fnc_noise
 *
 * Public: No
 */

params [["_pos", [0, 0, 0], [[]], 3], ["_band", "", [""]], ["_net", "", [""]]];

if !(_band in JAMMER_BANDS) exitWith {[]};

private _out = [];
{
    _y params ["_drone", "_role", "_powered"];
    if (_role isNotEqualTo ROLE_JAMMER || {!_powered} || {!alive _drone}) then {continue};
    private _dist = _pos distance (getPosASL _drone);
    if (_dist > GVAR(jammerRadius)) then {continue};
    private _loss = [_dist, _band] call EFUNC(rf,pathLossFree);
    _out pushBack [GVAR(jammerPower) + JAMMER_GAIN_DBI - _loss, true];
} forEach GVAR(drones);

_out
