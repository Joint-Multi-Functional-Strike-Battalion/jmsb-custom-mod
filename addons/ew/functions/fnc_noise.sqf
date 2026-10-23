#include "script_component.hpp"
/*
 * Author: JMSB
 * RF noise source (jmfsb_rf_fnc_addNoiseSource), server: what this addon's
 * jammers on the air ("tx", FUNC(jamUpdate)) put into a receiver (DESIGN_EW
 * "Jam modes") -
 *
 *   barrage  its one band, whole; TARGETED only the nets within half
 *            TARGET_BW_MHZ of its tuned MHz (jmfsb_rf_fnc_netFreq), +6 dB
 *   spot     one net only (the net of the track it was aimed at), +10 dB,
 *            and half the receiver's spread gain handed back
 *   sweep    each of its bands in turn, SWEEP_DWELL_S at a time
 *
 * at its power plus a whip's gain, less the band's clear-ground loss
 * (jmfsb_rf_fnc_pathLossFree), scaled by its duty cycle as average power,
 * out to the reach setting. Barrage-style, so the receiver's spread applies.
 * A SECTOR pattern reaches only receivers inside its lobe, with the lobe's
 * gain (jmfsb_rf_fnc_patternGain).
 * GPS jammers and spoofers add nothing here: GPS is not an RF band (the
 * jamming addon's zone carries GPS denial; FUNC(spoof) the spoofing).
 * Called per receiver per net per tick: no raycasts.
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
 * [eyePos player, "VHF", "C2"] call jmfsb_ew_fnc_noise
 *
 * Public: No
 */

params [["_pos", [0, 0, 0], [[]], 3], ["_band", "", [""]], ["_net", "", [""]]];

if (count GVAR(jammers) == 0) exitWith {[]};

private _out = [];
{
    private _j = _y;
    if !(_j get "tx") then {continue};
    private _mode = _j get "mode";
    private _gain = 0;
    switch (_mode) do {
        case MODE_BARRAGE: {
            if ((_j get "band") isNotEqualTo _band) exitWith {_mode = ""};
            if ((_j get "filter") isNotEqualTo FILTER_TARGETED) exitWith {};
            if (abs (([_net, _band] call EFUNC(rf,netFreq)) - (_j get "freq")) > TARGET_BW_MHZ / 2) exitWith {_mode = ""};
            _gain = TARGET_GAIN_DB;
        };
        case MODE_SPOT: {
            if ((_j get "net") isNotEqualTo _net || {(_j get "netBand") isNotEqualTo _band}) then {_mode = ""};
            _gain = SPOT_GAIN_DB + SPOT_SPREAD_BACK_DB;
        };
        case MODE_SWEEP: {
            private _bands = _j get "bands";
            private _now = _bands select ((floor (CBA_missionTime / SWEEP_DWELL_S)) % (count _bands));
            if (_now isNotEqualTo _band) then {_mode = ""};
        };
        default {_mode = ""};
    };
    if (_mode isEqualTo "") then {continue};

    private _host = _j get "host";
    if (isNull _host || {!alive _host}) then {continue};
    private _from = getPosASL _host;
    private _dist = _pos distance _from;
    if (_dist > GVAR(jamRange)) then {continue};
    ([_from, _pos, _j get "pattern", _j get "azimuth", SECTOR_WIDTH_DEG, SECTOR_GAIN_DB] call EFUNC(rf,patternGain)) params ["_reaches", "_lobe"];
    if (!_reaches) then {continue};
    _gain = _gain + _lobe;

    private _dbm = (_j get "dBm") + JAM_GAIN_DBI + _gain
        - ([_dist, _band] call EFUNC(rf,pathLossFree))
        + 10 * log ((_j get "dutyFrac") max 0.01);
    _out pushBack [_dbm, true];
} forEach GVAR(jammers);

_out
