#include "script_component.hpp"
/*
 * Author: YonV
 * Wave 3: men, and they WALK IN.
 *
 * Spawned at TAOR-valid origins three to six kilometres out, profiled the
 * moment they exist, and given a profile waypoint onto the objective. So they
 * cross the map virtually and materialise when the players can see them -
 * they arrive, rather than appearing.
 *
 * Composition is the answering commander's own faction, read from ALiVE. A
 * faction with no infantry gets nothing and says so, rather than quietly
 * sending somebody else's soldiers.
 *
 * Arguments:
 * 0: Answering side <SIDE>
 * 1: Its faction <STRING>
 * 2: Objective position <ARRAY>
 *
 * Return Value: None
 *
 * Public: No
 */

params ["_side", "_faction", "_pos"];

// WITHOUT ALiVE THEY STILL COME (user, 2026-11-02: "works with or without"):
// nothing to profile them into, so they walk in live - the same answer as a
// group ALiVE refuses to profile, below. The same with ALiVE loaded but no
// commanders, once the adapter has given up ("same as not loaded").
private _profiling = !isNil QEFUNC(adapter_alive,profileGroup) && {[] call EFUNC(common,aliveLoaded)};

private _n = round (GVAR(squadsMin) + random ((GVAR(squadsMax) max GVAR(squadsMin)) - GVAR(squadsMin)));
if (_n <= 0) exitWith {};

// WHO comes from the commander's faction, never from a class list here.
// Walked once per faction per mission (review P10, 2026-10-31): the walk of all
// of CfgVehicles on every capture was a server hitch.
if (isNil QGVAR(infantry)) then {GVAR(infantry) = createHashMap};
private _kinds = GVAR(infantry) getOrDefault [_faction, []];
if !(_faction in GVAR(infantry)) then {
    {
        private _cls = configName _x;
        if (getNumber (_x >> "scope") == 2
            && {getText (_x >> "faction") == _faction}
            && {_cls isKindOf "CAManBase"}) then {
            _kinds pushBack _cls;
        };
    } forEach ("true" configClasses (configFile >> "CfgVehicles"));
    GVAR(infantry) set [_faction, _kinds];
};

if (_kinds isEqualTo []) exitWith {
    WARNING_1("QRF squads: faction '%1' fields no infantry - sending nobody",_faction);
};

([_side] call EFUNC(common,groundFor)) params ["_taor", "_black"];

private _origins = [[], _n, createHashMapFromArray [
    ["centre", _pos],
    ["minRange", QRF_RING_MIN],
    ["maxRange", QRF_RING_MAX],
    ["footprint", 4],
    ["separation", 400],
    ["blacklist", _black]
]] call EFUNC(common,findSite);

// Own ground or nowhere - the soft "formed up just outside" fallback is
// exactly the wrong-side spawn the pre-spawn gate exists to stop, and the
// user closed that door for every module at once. A QRF with no origin
// inside its own TAOR stays home, and the gate's warning says so.
_origins = _origins select {[_side, _x, "qrf squads", _taor, _black] call EFUNC(common,taorGate)};
if (_origins isEqualTo []) exitWith {
    WARNING_1("QRF squads: no origin inside %1's own ground - sending nobody",_side);
};

private _sent = 0;
{
    private _at = _x;
    private _grp = createGroup [_side, true];
    for "_i" from 1 to 4 do {
        _grp createUnit [selectRandom _kinds, _at, [], 15, "NONE"];
    };

    private _profile = [];
    if (_profiling) then {
        _profile = [_grp] call EFUNC(adapter_alive,profileGroup);
    };
    if (_profile isEqualTo []) then {
        // Not profiled: they would stand there live for the rest of the
        // mission. Walk them in on their own legs instead.
        private _wp = _grp addWaypoint [_pos, 0];
        _wp setWaypointType "SAD";
        _wp setWaypointSpeed "NORMAL";
    } else {
        [_profile, _pos, 100, "SAD"] call EFUNC(adapter_alive,profileWaypoint);
    };
    _sent = _sent + 1;
} forEach _origins;

INFO_3("QRF squads: %1 of %2 sent for %3",_sent,_n,_side);
