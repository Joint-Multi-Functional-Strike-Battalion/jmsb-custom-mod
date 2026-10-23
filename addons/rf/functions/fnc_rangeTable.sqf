#include "script_component.hpp"
/*
 * Author: JMSB
 * THE RANGE SELF-TEST. For every profile and each of its bands: the distance
 * at which a link between two sets of that profile drops to quality 0 over
 * flat, clear ground - path loss only, no terrain, clutter or body, noise at
 * the floor. Written to the RPT, one line each, for comparison with the
 * targets in docs/DESIGN_RF.md ("Radio profiles", range column; 5 W VHF
 * ~5 km open). Pure: it runs the link budget, not the world.
 *
 * Found by geometric bisection between 1 m and RANGE_MAX_M. SAT is the
 * satellite and has no range: its row is -1 m, and the RPT line gives the
 * quality the satellite link has now (rain fade included).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[profile id, band, metres (-1 = any distance, SAT)], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_rf_fnc_rangeTable
 *
 * Public: Yes
 */

private _out = [];
{
    private _id = _x;
    private _prof = _y;
    private _tx = _prof get "txPowerDbm";
    private _gain = _prof get "antennaGainDb";
    private _sens = _prof get "rxSensDbm";
    {
        private _band = _x;
        // the satellite has no range: open sky at both ends links at any distance
        if (_band isEqualTo SAT_BAND) then {
            private _satFloor = (GVAR(bands) getOrDefault [SAT_BAND, [SAT_EXP, SAT_REF, SAT_FLOOR]]) select 2;
            private _q = ([_satFloor, _prof get "rxSensDbm"] call FUNC(satBudget)) select 2;
            _out pushBack [_id, _band, RANGE_ANY];
            INFO_2("range %1 SAT: satellite, any distance under open sky, quality %2 now",_id,_q);
            continue;
        };
        private _floor = (GVAR(bands) getOrDefault [_band, [VHF_EXP, VHF_REF, VHF_FLOOR]]) select 2;
        private _lo = 1;
        private _hi = RANGE_MAX_M;
        for "_i" from 1 to RANGE_ITERATIONS do {
            private _mid = sqrt (_lo * _hi);
            private _loss = [_mid, _band] call FUNC(pathLossFree);
            private _q = ([_tx, _gain, _gain, _loss, _floor, _sens] call FUNC(linkBudget)) select 2;
            if (_q > 0) then {_lo = _mid} else {_hi = _mid};
        };
        private _m = round _lo;
        _out pushBack [_id, _band, _m];
        INFO_4("range %1 %2: quality 0 at %3 m (%4 dBm TX)",_id,_band,_m,_tx);
    } forEach (_prof get "bands");
} forEach GVAR(profiles);

_out sort true;
_out
