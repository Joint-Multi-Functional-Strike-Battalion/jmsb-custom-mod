#include "script_component.hpp"
/*
 * Author: JMSB
 * One mesh edge: the two-way quality between two nodes on a net, the weaker
 * of the two directions (a MANET link carries traffic both ways, and the
 * sets' TX powers differ).
 *
 * THE COST IS jmfsb_rf_fnc_pathLoss, the terrain and clutter casts. It is
 * cached per pair and band in jmfsb_rf_edgeCache and reused while neither end
 * has moved more than EDGE_REUSE_M and the entry is younger than the static
 * tick: two placed relays are re-cast every static tick, a man standing still
 * likewise, and only moving pairs pay every player tick. Pairs beyond the
 * band's clear-ground range (jmfsb_rf_fnc_maxRange) never cast at all. The
 * cache is per band, so DATA and every voice net on the same band share it.
 *
 * Body loss and noise are not cached: stance changes without moving, and
 * noise is per net (the hooks may treat nets apart).
 *
 * THE SATELLITE (docs/DESIGN_RF.md "The satellite link"): when both ends are
 * SAT terminals under open sky (the tick's cached sky check), the pair also
 * links through the bird - one leg, any distance, no ray cast - at
 * jmfsb_rf_fnc_satBudget's quality, two-way against the SAT noise at each
 * end. The edge is the better of the ground link and the satellite. A net on
 * the SAT band itself has no ground link. Same side is the mesh's doing: it
 * only pairs nodes holding the same key.
 *
 * Arguments:
 * 0: Node id A <STRING>
 * 1: Node id B <STRING>
 * 2: Band <STRING>
 * 3: Net id <STRING>
 * 4: Tick context (jmfsb_rf_fnc_tick) <HASHMAP>
 *
 * Return Value:
 * Quality 0..1 <NUMBER>
 *
 * Example:
 * [_a, _b, "UHF", "DATA", _ctx] call jmfsb_rf_fnc_edge
 *
 * Public: No
 */

params ["_a", "_b", "_band", "_net", "_ctx"];

private _info = _ctx get "info";
(_info get _a) params ["", "_profA", "_posA", "_objA", "_bodyA", "_skyA"];
(_info get _b) params ["", "_profB", "_posB", "_objB", "_bodyB", "_skyB"];
private _noiseMemo = _ctx get "noise";

// THE SATELLITE - both ends SAT terminals under open sky: one hop, any range
private _sat = 0;
if (_skyA && _skyB) then {
    private _satKeyA = _a + "|" + _net + "|" + SAT_BAND;
    private _satNoiseA = _noiseMemo getOrDefault [_satKeyA, ""];
    if (_satNoiseA isEqualTo "") then {
        _satNoiseA = [_posA, SAT_BAND, _net, _profA get "spreadGainDb"] call FUNC(noise);
        _noiseMemo set [_satKeyA, _satNoiseA];
    };
    private _satKeyB = _b + "|" + _net + "|" + SAT_BAND;
    private _satNoiseB = _noiseMemo getOrDefault [_satKeyB, ""];
    if (_satNoiseB isEqualTo "") then {
        _satNoiseB = [_posB, SAT_BAND, _net, _profB get "spreadGainDb"] call FUNC(noise);
        _noiseMemo set [_satKeyB, _satNoiseB];
    };
    _sat = (([_satNoiseB, _profB get "rxSensDbm"] call FUNC(satBudget)) select 2)
        min (([_satNoiseA, _profA get "rxSensDbm"] call FUNC(satBudget)) select 2);
};

// THE GROUND LINK needs the net's band at both ends, and SAT is not one
private _bandsA = _profA get "bands";
private _bandsB = _profB get "bands";
if (_band isEqualTo SAT_BAND || !(_band in _bandsA) || !(_band in _bandsB)) exitWith {_sat};

private _txA = _profA get "txPowerDbm";
private _txB = _profB get "txPowerDbm";
private _gA = _profA get "antennaGainDb";
private _gB = _profB get "antennaGainDb";

// PREFILTER - no ray for a pair the clear-ground budget already rules out
if ((_posA vectorDistance _posB) > ([_band, (_txA max _txB) + _gA + _gB] call FUNC(maxRange))) exitWith {_sat};

// CACHED PATH LOSS - in a fixed pair order so A-B and B-A share an entry
private _pair = [_a, _b];
_pair sort true;
private _swap = (_pair select 0) isNotEqualTo _a;
private _p0 = [_posA, _posB] select _swap;
private _p1 = [_posB, _posA] select _swap;
private _key = format ["%1|%2|%3", _pair select 0, _pair select 1, _band];
private _now = CBA_missionTime;
private _hit = GVAR(edgeCache) getOrDefault [_key, []];
private _loss = 0;
if (_hit isNotEqualTo [] && {
    _hit params ["_c0", "_c1", "_t"];
    (_c0 vectorDistance _p0) < EDGE_REUSE_M && {(_c1 vectorDistance _p1) < EDGE_REUSE_M} && {(_now - _t) < GVAR(tickStatic)}
}) then {
    _loss = _hit select 3;
} else {
    // THE PER-PAIR TERRAIN AND CLUTTER CHECK - the expensive call of the tick
    private _parts = [_posA, _posB, _band, _objA, _objB] call FUNC(pathLoss);
    _loss = (_parts select 0) + (_parts select 1) + (_parts select 2);
    GVAR(edgeCache) set [_key, [_p0, _p1, _now, _loss]];
};
_loss = _loss + _bodyA + _bodyB;

// NOISE at each receiver, once per node and net per tick
private _noiseA = _noiseMemo getOrDefault [_a + "|" + _net, ""];
if (_noiseA isEqualTo "") then {
    _noiseA = [_posA, _band, _net, _profA get "spreadGainDb"] call FUNC(noise);
    _noiseMemo set [_a + "|" + _net, _noiseA];
};
private _noiseB = _noiseMemo getOrDefault [_b + "|" + _net, ""];
if (_noiseB isEqualTo "") then {
    _noiseB = [_posB, _band, _net, _profB get "spreadGainDb"] call FUNC(noise);
    _noiseMemo set [_b + "|" + _net, _noiseB];
};

private _ab = [_txA, _gA, _gB, _loss, _noiseB, _profB get "rxSensDbm"] call FUNC(linkBudget);
private _ba = [_txB, _gB, _gA, _loss, _noiseA, _profA get "rxSensDbm"] call FUNC(linkBudget);

((_ab select 2) min (_ba select 2)) max _sat
