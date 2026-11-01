#include "script_component.hpp"
/*
 * Author: JMSB
 * ACRE's custom signal function: the signal a receiver gets from a
 * transmitter, routed through the mesh when that is stronger than the direct
 * path.
 *
 * ACRE calls this once per transmitter/receiver pair with the frequency, the
 * transmitter's power and the two radio ids, and expects [quality 0..1, dBm]
 * back. The direct result is ACRE's own (getSignalCore). Relays are the
 * friendly radios in the relay table on the same frequency; each leg is
 * ACRE's model too (fnc_edge). The path is the widest one - the route whose
 * weakest leg is strongest - found by a Dijkstra over the relays, unbounded in
 * hops. Quality is the weakest leg's, less the hop loss for every relay that
 * transmits under the power threshold. Reception (dBm) is the weakest leg's,
 * unpenalised. Whichever of direct and relayed hears better is returned.
 *
 * The jam level jmfsb_jamming maintains for this client is applied last, the
 * way that addon applied it before this one took the signal function over.
 *
 * Arguments:
 * 0: Frequency in MHz <NUMBER>
 * 1: Transmitter power in mW <NUMBER>
 * 2: Receiving radio id <STRING>
 * 3: Transmitting radio id <STRING>
 *
 * Return Value:
 * [quality 0..1, signal dBm] <ARRAY>
 *
 * Public: No (registered with acre_api_fnc_setCustomSignalFunc)
 */
params ["_freq", "_power", "_rx", "_tx"];

private _direct = [_freq, _power, _rx, _tx] call FUNC(edge);
private _best = _direct;

if (GVAR(enabled) && {GVAR(nodes) isNotEqualTo []}) then {
    private _txSide = [_tx] call FUNC(radioSide);

    // The relays this transmission may use: on its frequency, on its side,
    // and neither end of the link itself.
    private _cands = GVAR(nodes) select {
        _x params ["_id", "_f", "", "_s"];
        _id isNotEqualTo _tx && _id isNotEqualTo _rx
            && abs (_f - _freq) <= MESH_FREQ_TOL && _s isEqualTo _txSide
    };

    // THE COST CEILING - the nearest N to the middle of the link
    if (count _cands > GVAR(maxNodes) && {!isNil "acre_sys_radio_fnc_getRadioPos"}) then {
        private _mid = (([_tx] call acre_sys_radio_fnc_getRadioPos) vectorAdd ([_rx] call acre_sys_radio_fnc_getRadioPos)) vectorMultiply 0.5;
        _cands = _cands apply { [([_x select 0] call acre_sys_radio_fnc_getRadioPos) distance _mid, _x] };
        _cands sort true;
        _cands = (_cands select [0, GVAR(maxNodes)]) apply { _x select 1 };
    };

    if (_cands isNotEqualTo []) then {
        private _loss = GVAR(hopLoss);
        private _thr = GVAR(lossBelowMw);
        private _n = count _cands;

        // WIDEST PATH. For every relay: the best "weakest leg" on any route
        // from the transmitter to it, the quality along that route, and how
        // many weak (sub-threshold) relays that route has already been
        // through. Seeded with the direct leg from the transmitter.
        private _bestDbm = [];
        private _bestPct = [];
        private _weak = [];
        private _done = [];
        for "_i" from 0 to _n - 1 do {
            private _e = [_freq, _power, (_cands select _i) select 0, _tx] call FUNC(edge);
            _bestDbm pushBack (_e select 1);
            _bestPct pushBack (_e select 0);
            _weak pushBack 0;
            _done pushBack false;
        };

        for "_k" from 0 to _n - 1 do {
            // the unsettled relay reached best so far
            private _u = -1;
            private _uDbm = MESH_NO_SIGNAL;
            for "_i" from 0 to _n - 1 do {
                if (!(_done select _i) && {(_bestDbm select _i) > _uDbm}) then {
                    _u = _i;
                    _uDbm = _bestDbm select _i;
                };
            };
            if (_u < 0) exitWith {};
            _done set [_u, true];
            (_cands select _u) params ["_uId", "", "_uPower"];
            // this relay's own hop is a weak one if it transmits under the threshold
            private _uWeak = (_weak select _u) + parseNumber (_uPower < _thr);

            // relay -> receiver: a complete route
            private _er = [_freq, _uPower, _rx, _uId] call FUNC(edge);
            private _dbm = _uDbm min (_er select 1);
            if (_dbm > (_best select 1)) then {
                private _pct = ((_bestPct select _u) min (_er select 0)) * ((1 - _loss) ^ _uWeak);
                _best = [_pct, _dbm];
            };

            // relay -> the other relays: extend the frontier
            for "_v" from 0 to _n - 1 do {
                if (!(_done select _v)) then {
                    private _ev = [_freq, _uPower, (_cands select _v) select 0, _uId] call FUNC(edge);
                    private _d2 = _uDbm min (_ev select 1);
                    if (_d2 > (_bestDbm select _v)) then {
                        _bestDbm set [_v, _d2];
                        _bestPct set [_v, (_bestPct select _u) min (_ev select 0)];
                        _weak set [_v, _uWeak];
                    };
                };
            };
        };
    };
};

// Jamming last, as jmfsb_jamming applied it when it held the signal function:
// the jam level is a fraction of received quality removed.
private _jam = missionNamespace getVariable ["jmfsb_jamming_acreJam", 0];
// and the RF burst's own registry (jmfsb_aps), the same lever from another source
_jam = _jam max (missionNamespace getVariable ["jmfsb_aps_acreJam", 0]);
if (_jam > 0) then {
    _best = [(_best select 0) * (1 - _jam), _best select 1];
};

_best
