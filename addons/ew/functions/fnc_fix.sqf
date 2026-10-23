#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: crosses a track's recent cuts into a fix (DESIGN_EW "2+ cuts within
 * 30 s make a fix with an error ellipse"). Every pair of cuts inside the fix
 * window, from sensors at least FIX_MIN_BASELINE_M apart and crossing at
 * FIX_MIN_CROSS_DEG or more, in front of both, gives a point; the fix is
 * their mean weighted by each pair's error, and the error is that of the
 * best pair. The ellipse is carried as its larger axis - a circle.
 * A track that cannot be crossed this tick keeps its last fix and its time.
 * Confidence: how many cuts are fresh, and how tight the fix is.
 *
 * Arguments:
 * 0: Track <HASHMAP>
 *
 * Return Value:
 * Whether this tick made a first fix <BOOL>
 *
 * Example:
 * [_track] call jmfsb_ew_fnc_fix
 *
 * Public: No
 */

params [["_track", createHashMap, [createHashMap]]];

private _now = CBA_missionTime;
private _fresh = (_track get "cuts") select {(_now - (_x select 3)) <= GVAR(fixWindow)};
private _minCross = sin FIX_MIN_CROSS_DEG;

private _sumW = 0;
private _sx = 0;
private _sy = 0;
private _bestErr = FIX_ERR_MAX_M;
for "_i" from 0 to (count _fresh - 2) do {
    (_fresh select _i) params ["_p1", "_b1", "_e1"];
    for "_j" from (_i + 1) to (count _fresh - 1) do {
        (_fresh select _j) params ["_p2", "_b2", "_e2"];
        if ((_p1 distance2D _p2) < FIX_MIN_BASELINE_M) then {continue};
        private _d1 = [sin _b1, cos _b1];
        private _d2 = [sin _b2, cos _b2];
        private _cross = (_d1 select 0) * (_d2 select 1) - (_d1 select 1) * (_d2 select 0);
        if (abs _cross < _minCross) then {continue};
        private _wx = (_p2 select 0) - (_p1 select 0);
        private _wy = (_p2 select 1) - (_p1 select 1);
        private _t = (_wx * (_d2 select 1) - _wy * (_d2 select 0)) / _cross;
        private _s = (_wx * (_d1 select 1) - _wy * (_d1 select 0)) / _cross;
        if (_t <= 0 || _s <= 0) then {continue};
        private _err = ((sqrt ((_t * tan _e1) ^ 2 + (_s * tan _e2) ^ 2)) / abs _cross) min FIX_ERR_MAX_M;
        private _w = 1 / (_err max 1);
        _sumW = _sumW + _w;
        _sx = _sx + _w * ((_p1 select 0) + _t * (_d1 select 0));
        _sy = _sy + _w * ((_p1 select 1) + _t * (_d1 select 1));
        _bestErr = _bestErr min _err;
    };
};

private _first = false;
if (_sumW > 0) then {
    _first = (_track get "fix") isEqualTo [];
    _track set ["fix", [_sx / _sumW, _sy / _sumW]];
    _track set ["fixErr", round _bestErr];
    _track set ["fixAt", _now];
};

private _conf = ((count _fresh) min CUTS_PER_EMITTER) / CUTS_PER_EMITTER * 0.4;
if ((_track get "fix") isNotEqualTo []) then {
    _conf = _conf + 0.6 * (1 - (((_track get "fixErr") / FIX_ERR_POOR_M) min 1));
};
_track set ["conf", (round (_conf * 20)) / 20];

_first
