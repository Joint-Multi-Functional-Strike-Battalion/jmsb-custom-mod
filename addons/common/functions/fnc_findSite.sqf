#include "script_component.hpp"
/*
 * Author: YonV
 * Finds ground worth putting something on - the placement service every
 * auto-sited asset goes through, so "radar in a lake" and "battery in a
 * forest" are solved once rather than once per module.
 *
 * TWO STAGES, because either alone fails: pure rejection sampling loops
 * forever on hard maps, and first-legal-spot placement gives the first barely
 * legal spot. Candidates that survive the HARD REJECTS compete on a SOFT
 * SCORE, and the best of the batch wins - good placement in bounded time.
 *
 * Hard rejects, all off the profile:
 *   water     under the whole footprint, not just the centre - a radar is
 *             metres wide and its centre can be dry while a leg is in the sea
 *   slope     terrain height sampled across the footprint, not one normal
 *   clutter   trees, bushes and rocks by nearestTerrainObjects - the engine's
 *             own flat-empty test does not reliably see terrain vegetation
 *   occupied  buildings or objects standing in the footprint
 *   spacing   minimum separation from already-accepted sites and the caller's
 *             avoid list; blacklist markers
 *   road      within reach of a road, when asked
 *   LOS       must see given positions (a sensor), or must NOT see them (an
 *             inland launcher that may never stand in view of the sea)
 *
 * Default score prefers height and margin over the slope limit; the profile
 * can hand in its own scorer.
 *
 * Anything hand-placed in Eden is none of this function's business - it
 * places what a mission did NOT specify, never second-guesses what it did.
 *
 * TWO WAYS TO NAME THE GROUND. Area markers are what a mission draws, and are
 * the usual case. A ring - centre plus a range band - is what a system means
 * when it says "somewhere about a kilometre off that contact" and no marker
 * exists to describe it. Give one or the other.
 *
 * Arguments:
 * 0: Area marker names <ARRAY of STRING> ([] when using the ring keys below)
 * 1: How many sites <NUMBER>
 * 2: Profile <HASHMAP> (every key optional):
 *    "centre"     ring centre, when no markers are given <ARRAY>
 *    "minRange"   m, inner edge of the ring (default 0)
 *    "maxRange"   m, outer edge of the ring - required with "centre"
 *    "footprint"  m half-size that must be clear and dry (default 6)
 *    "maxSlope"   gradient limit, rise over run (default 0.18)
 *    "clearRadius" m free of vegetation and rocks (default footprint + 4)
 *    "separation" m between results (default 150)
 *    "avoid"      positions to stand clear of <ARRAY>
 *    "avoidRadius" m (default separation)
 *    "blacklist"  area markers never to use <ARRAY>
 *    "nearRoad"   m to a road, 0 = do not care (default 0)
 *    "offRoad"    m of clearance FROM a road surface, 0 = allow the shoulder
 *                 (default footprint + 2, capped at 10) - nothing sited here
 *                 belongs on a carriageway, and standing ON one is refused
 *                 whatever this says
 *    "losTo"      positions that MUST be visible from the site <ARRAY>
 *    "losDenied"  positions that must NOT be visible <ARRAY>
 *    "eyeHeight"  m above ground the LOS is judged from (default 3)
 *    "samples"    candidate draws per site (default 40)
 *    "score"      code, candidate pos -> number, higher wins <CODE>
 *    "debug"      drop a marker per result (default false)
 *
 * Return Value:
 * Positions, possibly fewer than asked - the shortfall is logged, never
 * silent <ARRAY>
 *
 * Example:
 * private _sites = [["taor_1"], 3, createHashMapFromArray [["nearRoad", 300]]] call jmfsb_common_fnc_findSite
 */

params [["_markers", [], [[]]], ["_count", 1, [0]], ["_profile", createHashMap, [createHashMap]]];
if (_count < 1) exitWith {[]};

private _centre = _profile getOrDefault ["centre", []];
private _minRange = _profile getOrDefault ["minRange", 0];
private _maxRange = _profile getOrDefault ["maxRange", 0];
private _ring = _markers isEqualTo [] && {_centre isNotEqualTo []} && _maxRange > 0;
if (_markers isEqualTo [] && {!_ring}) exitWith {[]};

private _foot = _profile getOrDefault ["footprint", 6];
private _maxSlope = _profile getOrDefault ["maxSlope", 0.18];
private _clear = _profile getOrDefault ["clearRadius", _foot + 4];
private _sep = _profile getOrDefault ["separation", 150];
private _avoid = _profile getOrDefault ["avoid", []];
private _avoidR = _profile getOrDefault ["avoidRadius", _sep];
private _blacklist = _profile getOrDefault ["blacklist", []];
private _nearRoad = _profile getOrDefault ["nearRoad", 0];
// Road CLEARANCE, on by default: nothing this function sites belongs on a
// carriageway. It is the footprint plus a margin unless a caller says
// otherwise, and "offRoad" 0 turns it off for anything that wants the road.
// Capped: a big footprint should not demand half a field of road clearance,
// which is how a town-centre profile ends up with nowhere legal to stand.
private _offRoad = _profile getOrDefault ["offRoad", ((_foot max 4) + 2) min 10];
private _losTo = _profile getOrDefault ["losTo", []];
private _losDenied = _profile getOrDefault ["losDenied", []];
private _eye = _profile getOrDefault ["eyeHeight", 3];
private _samples = _profile getOrDefault ["samples", 40];
private _debug = _profile getOrDefault ["debug", false];
private _fnc_score = _profile getOrDefault ["score", {
    // higher ground wins; a site well inside its slope limit beats one at it
    params ["_p", "_slope", "_maxSlope"];
    (getTerrainHeightASL _p) + 20 * (1 - _slope / (_maxSlope max 0.01))
}];

private _fnc_slopeAt = {
    params ["_p", "_r"];
    private _h = getTerrainHeightASL _p;
    private _worst = 0;
    {
        private _d = abs (getTerrainHeightASL (_p getPos [_r, _x]) - _h) / _r;
        if (_d > _worst) then {_worst = _d};
    } forEach [0, 90, 180, 270];
    _worst
};

private _found = [];

for "_site" from 1 to _count do {
    private _best = [];
    private _bestScore = -1e9;
    private _usedPass = 0;

    // RELAX RATHER THAN FAIL. Every gate below is a preference except the
    // few that are physically wrong to break, and stacking preferences at
    // full strength was returning "0 of 1 site(s) found" - a battery that
    // does not exist is worse than a battery on imperfect ground, and the
    // caller has no way to negotiate from outside.
    //
    // So the sample loop runs up to three times, easing the SOFT gates each
    // pass: vegetation clearance, slope, road clearance, and how hard it
    // looks. What never eases: water, the blacklist, separation from other
    // sites, line of sight, and standing ON a road.
    for "_pass" from 0 to 2 do {
        if (_best isNotEqualTo []) exitWith {};
        _usedPass = _pass;

        private _wClear = _clear * ([1, 0.6, 0.25] select _pass);
        private _wSlope = _maxSlope * ([1, 1.4, 2] select _pass);
        private _wOff = _offRoad min ([_offRoad, 6, 4] select _pass);
        private _wFoot = _foot * ([1, 0.9, 0.75] select _pass);
        private _wSamples = _samples * ([1, 2, 3] select _pass);

        for "_try" from 1 to _wSamples do {
            private _p = if (_ring) then {
                _centre getPos [_minRange + random (_maxRange - _minRange), random 360]
            } else {
                [[selectRandom _markers]] call BIS_fnc_randomPos
            };
            if (_p isEqualTo [0, 0, 0]) then {continue};

            // OFF THE ROAD, AND OFF ITS SHOULDER. Every siting this function does
            // is for something that stands still - a launcher, a gun, a prop -
            // and hardware in the middle of a carriageway is the one placement
            // fault a player reads as broken before they read it as hostile.
            // Checked FIRST because it is the cheapest test here and it throws
            // away the candidates a settlement pass would otherwise spend
            // vegetation and LOS work on.
            //
            // The centre alone is not enough: isOnRoad is a surface test, and a
            // point beside a road passes it while the object's body still sits on
            // the tarmac. A ring at the clearance distance is what actually keeps
            // the footprint clear.
            // Standing on the tarmac is never allowed, at any pass; only the
            // shoulder clearance eases.
            if (isOnRoad _p) then {continue};
            if (_wOff > 0) then {
                private _onRoad = false;
                {
                    if (isOnRoad (_p getPos [_wOff, _x])) exitWith {_onRoad = true};
                } forEach [0, 45, 90, 135, 180, 225, 270, 315];
                if (_onRoad) then {continue};
            };

            // dry under the WHOLE footprint
            if (surfaceIsWater _p) then {continue};
            private _wet = false;
            {
                if (surfaceIsWater (_p getPos [_wFoot, _x])) exitWith {_wet = true};
            } forEach [45, 135, 225, 315];
            if (_wet) then {continue};

            // the engine's fast gate first, then what it cannot see - it returns
            // [] for a failing position
            if ((_p isFlatEmpty [-1, -1, _wSlope, _wFoot, 0, false, objNull]) isEqualTo []) then {continue};

            private _slope = [_p, _wFoot] call _fnc_slopeAt;
            if (_slope > _wSlope) then {continue};

            if (_wClear > 0 && {(nearestTerrainObjects [_p, ["TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS"], _wClear, false]) isNotEqualTo []}) then {continue};

            // NEVER INSIDE A BUILDING, at any pass - only the elbow room
            // beside one eases.
            //
            // This was `_p nearObjects ["Building", footprint * 2]`, which
            // measures to a building's ORIGIN, not its walls: a warehouse
            // whose centre is fifteen metres away passes a four-metre test
            // while the candidate stands in the middle of its floor. That is
            // how net pops ended up inside houses. The real test is the
            // building's own bounding box, in ITS model space, so rotation
            // and shape are handled by the engine rather than guessed at.
            private _margin = _wFoot * ([1, 0.6, 0.3] select _pass);
            private _inside = false;
            {
                (boundingBoxReal _x) params ["_bbMin", "_bbMax"];
                (_x worldToModel _p) params ["_rx", "_ry"];
                if (_rx > (_bbMin select 0) - _margin && {_rx < (_bbMax select 0) + _margin}
                    && {_ry > (_bbMin select 1) - _margin} && {_ry < (_bbMax select 1) + _margin}) exitWith {
                    _inside = true;
                };
            } forEach (_p nearObjects ["Building", 60]);
            if (_inside) then {continue};

            if (_blacklist findIf {_p inArea _x} > -1) then {continue};
            if (_found findIf {_x distance2D _p < _sep} > -1) then {continue};
            if (_avoid findIf {_x distance2D _p < _avoidR} > -1) then {continue};

            if (_nearRoad > 0 && {(_p nearRoads _nearRoad) isEqualTo []}) then {continue};

            // LOS both ways, judged from antenna height over each ground point
            private _from = AGLToASL _p vectorAdd [0, 0, _eye];
            private _blocked = false;
            {
                if (terrainIntersectASL [_from, AGLToASL _x vectorAdd [0, 0, _eye]]) exitWith {_blocked = true};
            } forEach _losTo;
            if (_blocked) then {continue};
            private _seen = false;
            {
                if !(terrainIntersectASL [_from, AGLToASL _x vectorAdd [0, 0, _eye]]) exitWith {_seen = true};
            } forEach _losDenied;
            if (_seen) then {continue};

            private _score = [_p, _slope, _wSlope] call _fnc_score;
            if (_score > _bestScore) then {
                _bestScore = _score;
                _best = +_p;
            };
        };
    };

    // A site found on a relaxed pass is worth saying: it is standing on
    // ground the profile asked this function to avoid.
    if (_best isNotEqualTo [] && _usedPass > 0) then {
        diag_log text format [
            "[jmfsb_common] findSite: site %1 needed relaxation pass %2 - the strict profile had no ground here",
            count _found + 1, _usedPass
        ];
    };

    if (_best isNotEqualTo []) then {
        _found pushBack _best;
        if (_debug) then {
            // same trap as the shortfall log below: never build the branch
            // that does not apply - `_markers select 0` on the ring path is
            // reading element 0 of an empty array
            private _where = if (_ring) then {"ring"} else {_markers param [0, "area"]};
            private _mkr = createMarker [format [QGVAR(site_%1_%2), _where, count _found], _best];
            _mkr setMarkerTypeLocal "hd_dot";
            _mkr setMarkerColorLocal "ColorOrange";
            _mkr setMarkerText format ["site %1", count _found];
        };
    };
};

// fewer than asked is a fact worth saying, never a silence to debug at 2am
if (count _found < _count) then {
    // BOTH BRANCHES OF A `select` ARE EVALUATED FIRST. Written as
    // [_markers, format [... mapGridPosition _centre]] select _ring, the ring
    // description was built even on the marker path - where _centre is [] and
    // mapGridPosition errors - so the one line meant to explain a shortfall
    // threw an error of its own instead.
    private _where = if (_ring) then {
        format ["%1 m ring at %2", round _maxRange, mapGridPosition _centre]
    } else {
        str _markers
    };
    diag_log text format [
        "[jmfsb_common] findSite: %1 of %2 site(s) found in %3 - the profile could not be satisfied %4 time(s)",
        count _found, _count, _where, _count - count _found
    ];
};

_found
