#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: what one sensor hears of one emitter - the RF link budget run one
 * way, with RF's own band table, noise and terrain price:
 *
 *   rx  = tx + gainTx + gainRx - pathloss(d, band) - terrain - spread
 *   snr = rx - noise(sensor, band)
 *
 * tx is capped at 2 W from EMCON 1. Without the emitter's key its spread gain
 * comes off (DESIGN_RF "Without the key"). Terrain is RF's three samples;
 * clutter is not cast here - a DF tick prices many pairs, and the walls round
 * an antenna are RF's mesh cost, not a bearing's. A jammer is the noise it is
 * heard against, so it is measured against the band's floor instead.
 * Of the bands both share, the one heard best is taken.
 *
 * Arguments:
 * 0: Emitter, as FUNC(collect) builds it <HASHMAP>
 * 1: Sensor position ASL <ARRAY>
 * 2: Sensor bands <ARRAY of STRINGs>
 * 3: Sensor RX sensitivity dBm <NUMBER>
 * 4: Sensor antenna gain dBi <NUMBER>
 * 5: Sensor holds the emitter's key <BOOL>
 *
 * Return Value:
 * [band, rx dBm, snr dB], [] when not heard <ARRAY>
 *
 * Example:
 * [_emitter, eyePos player, ["VHF", "UHF"], -112, 2, false] call jmfsb_ew_fnc_detect
 *
 * Public: No
 */

params [
    ["_e", createHashMap, [createHashMap]],
    ["_pos", [0, 0, 0], [[]], 3],
    ["_bands", [], [[]]],
    ["_sens", 0, [0]],
    ["_gainRx", 0, [0]],
    ["_keyed", false, [false]]
];

private _from = _e get "pos";
private _dist = _pos distance _from;
if (_dist > DETECT_MAX_M) exitWith {[]};

private _common = (_e get "bands") arrayIntersect _bands;
if (_common isEqualTo []) exitWith {[]};

private _tx = _e get "txDbm";
if ((_e get "emcon") > 0) then {_tx = _tx min EMCON_POWER_CAP_DBM};
private _spread = [_e get "spread", 0] select _keyed;
private _isJam = (_e get "intent") in [INTENT_JAM, INTENT_SPOOF];

// THE TERRAIN, once per pair: RF's three segments, each the ground blocks
// costing RF's own terrain setting.
private _terrainDb = missionNamespace getVariable [QEGVAR(rf,terrainDb), 0];
private _blocked = 0;
for "_i" from 0 to (TERRAIN_SAMPLES - 1) do {
    private _a = _from vectorAdd ((_pos vectorDiff _from) vectorMultiply (_i / TERRAIN_SAMPLES));
    private _b = _from vectorAdd ((_pos vectorDiff _from) vectorMultiply ((_i + 1) / TERRAIN_SAMPLES));
    if (terrainIntersectASL [_a, _b]) then {_blocked = _blocked + 1};
};

private _best = [];
{
    private _loss = ([_dist, _x] call EFUNC(rf,pathLossFree)) + _blocked * _terrainDb;
    private _rx = _tx + (_e get "gainDbi") + _gainRx - _loss - _spread;
    if (_rx < _sens) then {continue};
    private _noise = if (_isJam) then {
        (([_x] call EFUNC(rf,bandInfo)) param [2, _sens])
    } else {
        [_pos, _x, "", 0] call EFUNC(rf,noise)
    };
    private _snr = _rx - _noise;
    if (_snr < DETECT_SNR_DB) then {continue};
    if (_best isEqualTo [] || {_snr > (_best select 2)}) then {_best = [_x, _rx, _snr]};
} forEach _common;

_best
