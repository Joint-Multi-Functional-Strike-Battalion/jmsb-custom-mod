#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_netFreq: the frequency a net - or any other stable id, an emitter's -
 * sits on in a band: a hash of the id on the band's channel raster
 * (RF_BAND_MHZ), so the same on every machine and never sent. Worked out once
 * per id and band, then kept.
 *
 * Arguments:
 * 0: Net id (or another stable id) <STRING>
 * 1: Band "VHF" | "UHF" | "SAT" | "VIDEO" <STRING>
 *
 * Return Value:
 * MHz, 0 for an unknown band or an empty id <NUMBER>
 *
 * Example:
 * ["C2", "VHF"] call jmfsb_rf_fnc_netFreq
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_band", "", [""]]];

private _key = _id + "|" + _band;
private _known = GVAR(freqs) getOrDefault [_key, -1];
if (_known >= 0) exitWith {_known};

(GVAR(bandMhz) getOrDefault [_band, [[], 0]]) params ["_ranges", "_step"];
if (_id isEqualTo "" || {_ranges isEqualTo []}) exitWith {0};

private _hash = 0;
{
    _hash = (_hash * RF_FREQ_HASH_MULT + _x) mod RF_FREQ_HASH_MOD;
} forEach toArray _id;

// The channel the hash picks, counted across the band's ranges in order.
private _channels = _ranges apply {floor (((_x select 1) - (_x select 0)) / _step)};
private _total = 0;
{
    _total = _total + _x;
} forEach _channels;
private _n = _hash mod (_total max 1);
private _mhz = 0;
{
    if (_n < _x) exitWith {
        _mhz = ((_ranges select _forEachIndex) select 0) + _n * _step;
    };
    _n = _n - _x;
} forEach _channels;

GVAR(freqs) set [_key, _mhz];
_mhz
