#include "script_component.hpp"
/*
 * Author: YonV
 * ISR processed a batch: one circle on the nearest piece of the enemy's
 * network.
 *
 * THE POOL IS ALL OF IT, and every source is AUTO-PLACED - nothing here is
 * synced in Eden. Anti-ship batteries and their radars, ALiVE's air defence
 * and artillery, jmfsb's own battery sites, the drone supply caches, and on
 * the asymmetric side the installations and safe houses. Whatever is hostile
 * to the depositing side and still standing is a candidate.
 *
 * THE TAOR DECIDES WHAT KIND OF INTEL EXISTS WHERE - the same rule the
 * product menu already follows (see FUNC(taorType)). A candidate only counts
 * if the war being fought on ITS ground matches what it is: leaders and
 * installations on asymmetric ground, the conventional network on invasion/
 * occupation ground, and caches wherever somebody's war is being fought.
 * Ground no commander holds has no network and hints at nothing.
 *
 * NEAREST TO THE DEPOSIT, not random. Intel taken off bodies here is about
 * the enemy here - a batch banked at a drop points at the closest thing the
 * network has, which is also the one the section can actually act on. A
 * target already hinted is skipped so the tally walks outward instead of
 * re-marking the same site; once everything has been named the walk starts
 * again.
 *
 * The circle tightens per batch on the same ladder grammar every other
 * product uses.
 *
 * Arguments:
 * 0: Where the batch was deposited <ARRAY> (optional - empty picks at random)
 * 1: The side the hint is drawn for - the depositor's <SIDE>
 *
 * The walk (ids hinted, tier) is the server's, in localNamespace (review S7).
 *
 * Return Value:
 * Anything drawn <BOOL>
 *
 * Public: No
 */

params [["_from", [], [[]]], ["_side", sideUnknown, [sideUnknown]]];

if (!isServer || {_side isEqualTo sideUnknown}) exitWith {false};
private _pool = [];
// ALiVE's half of the pool, its persistence and its G2 - none of it with ALiVE
// loaded but no commanders, once the adapter has given up (user, 2026-11-02:
// "same as not loaded").
private _alive = [] call EFUNC(common,aliveLoaded);

// --- the conventional network ----------------------------------------------
{
    _x params ["_id", "_at", "_bSide"];
    if (_bSide getFriend _side < 0.6) then {
        _pool pushBack [_id, _at, "anti-ship battery", "conv"];
    };
} forEach (missionNamespace getVariable [QEGVAR(antiship,batteries), []]);

// Live radar objects, the same not-friendly rule as LOCATE RADAR: an uncrewed
// radar answers `side` as civilian and a getFriend test would hide it.
{
    if (!isNull _x && {alive _x} && {side _x isNotEqualTo _side}) then {
        _pool pushBack [format ["radar_%1", mapGridPosition _x], getPosASL _x, "coastal radar", "conv"];
    };
} forEach (missionNamespace getVariable [QEGVAR(antiship,radars), []]);

if (_alive && {!isNil QEFUNC(adapter_alive,aaTargets)}) then {
    {
        _x params ["_id", "_at", "_aSide"];
        if (_aSide getFriend _side < 0.6) then {
            _pool pushBack [_id, _at, "air defence", "conv"];
        };
    } forEach (call EFUNC(adapter_alive,aaTargets));
};

if (_alive && {!isNil QEFUNC(adapter_alive,artyTargets)}) then {
    {
        _x params ["_id", "_at", "_aSide"];
        if (_aSide getFriend _side < 0.6) then {
            _pool pushBack [_id, _at, "artillery", "conv"];
        };
    } forEach ([sideUnknown] call EFUNC(adapter_alive,artyTargets));
};

// ALiVE's radars, beside the coastal ones above: the eyes of every network.
if (_alive && {!isNil QEFUNC(adapter_alive,radars)}) then {
    {
        _x params ["_id", "_at", "_rSide"];
        if (_rSide getFriend _side < 0.6) then {
            _pool pushBack [_id, _at, "radar", "conv"];
        };
    } forEach (call EFUNC(adapter_alive,radars));
};

// THE REAR. A camp is hostile by who garrisons it now; an empty one has no
// side and is not pointed at. A hub is hostile by the faction LOGCOM runs it
// for. Both are the conventional war's - the asymmetric chain has its own
// rear, the installations and safe houses below.
if (_alive && {!isNil QEFUNC(adapter_alive,camps)}) then {
    {
        _x params ["_id", "_at", "", "_cSide"];
        if (_cSide isNotEqualTo sideUnknown && {_cSide getFriend _side < 0.6}) then {
            _pool pushBack [_id, _at, "camp", "conv"];
        };
    } forEach (call EFUNC(adapter_alive,camps));
};

if (_alive && {!isNil QEFUNC(adapter_alive,logisticsHubs)}) then {
    {
        _x params ["_id", "_at", "_hSide"];
        if (_hSide getFriend _side < 0.6) then {
            _pool pushBack [_id, _at, "logistics hub", "conv"];
        };
    } forEach (call EFUNC(adapter_alive,logisticsHubs));
};

{
    if (!isNull _x && {alive _x}
        && {(_x getVariable [QEGVAR(uas,cacheSide), sideUnknown]) getFriend _side < 0.6}) then {
        _pool pushBack [format ["cache_%1", mapGridPosition _x], getPosATL _x, "drone supply cache", "any"];
    };
} forEach (missionNamespace getVariable [QEGVAR(uas,caches), []]);

// --- the asymmetric network -------------------------------------------------
if (_alive && {!isNil QEFUNC(adapter_alive,installations)}) then {
    {
        _x params ["_id", "_at", "", "_type"];
        _pool pushBack [_id, _at, _type, "asym"];
    } forEach ([] call EFUNC(adapter_alive,installations));
};

if (!isNil "jmfsb_leaders_houses") then {
    {
        if (!isNull _x) then {
            _pool pushBack [format ["house_%1", _forEachIndex], getPosATL _x, "safe house", "asym"];
        };
    } forEach jmfsb_leaders_houses;
};

// --- the TAOR gate -----------------------------------------------------------
// The TAOR decides whether you are looking for leaders or for AA and arty
// sites: a candidate counts only where its kind matches the war being fought
// on ITS ground. FUNC(taorType) is the one answer to whose ground this is.
//
// NO COMMANDER MEANS NO OPINION, NOT NO INTEL. jmfsb's version dropped any
// candidate whose ground answered "" - which was right there, where every
// source in the pool was ALiVE's and ground nobody held really did have no
// network. Here the pool is half hand-placed: anti-ship batteries, jammer
// sites, drone caches and safe houses that exist because somebody put them
// somewhere, very possibly outside every TAOR - and with no ALiVE loaded
// FUNC(taorType) answers "" for the whole map. Kept as jmfsb wrote it this
// would empty the pool and the hint system would silently never fire.
_pool = _pool select {
    _x params ["", "_at", "", "_kind"];
    private _ground = [_at] call FUNC(taorType);
    if (_ground isEqualTo "") then {
        true
    } else {
        switch (_kind) do {
            case "conv": {_ground in ["invasion", "occupation"]};
            case "asym": {_ground isEqualTo "asymmetric"};
            // Caches supply whichever war is fought around them.
            default {true};
        }
    };
};

if (_pool isEqualTo []) exitWith {
    INFO("intel hint: nothing hostile on commander ground to point at");
    false
};

// --- the walk ----------------------------------------------------------------
private _hinted = localNamespace getVariable [QGVAR(hintedIds), []];
private _fresh = _pool select {!((_x select 0) in _hinted)};
// Everything named once already: start the walk again rather than going quiet.
if (_fresh isEqualTo []) then { _fresh = _pool; _hinted = [] };

private _pick = if (_from isEqualTo []) then {
    selectRandom _fresh
} else {
    private _best = _fresh select 0;
    {
        if ((_from distance2D (_x select 1)) < (_from distance2D (_best select 1))) then {
            _best = _x;
        };
    } forEach _fresh;
    _best
};
_pick params ["_id", "_at", "_type"];

private _tier = localNamespace getVariable [QGVAR(hintTier), 0];
private _radii = ([QGVAR(cfg_circle_radii)] call FUNC(hackSetting)) splitString ", ";
_radii = _radii apply { parseNumber _x };
_radii = _radii select {_x > 0};
if (_radii isEqualTo []) then { _radii = [3000, 2000, 1000] };
private _radius = _radii select (_tier min (count _radii - 1));

// Fraction first, THEN the cap - the setting is a percentage and the cap is a
// fraction, so capping first turned 75% into 0.95% and drew the "fuzzed"
// circle almost exactly on the target.
private _offset = (([QGVAR(cfg_circle_offset)] call FUNC(hackSetting)) / 100);
_offset = 0 max _offset min INTEL_OFFSET_CAP;
private _throw = _radius * _offset;
private _bearing = random 360;
private _centre = _at vectorAdd [sin _bearing * _throw, cos _bearing * _throw, 0];

_hinted pushBack _id;
localNamespace setVariable [QGVAR(hintedIds), _hinted];
localNamespace setVariable [QGVAR(hintTier), _tier + 1];
// The walk survives a restart with ALiVE's war state - see XEH_postInit.
if (_alive && {!isNil QEFUNC(adapter_alive,setData)}) then {
    [QGVAR(hintedIds), _hinted] call EFUNC(adapter_alive,setData);
    [QGVAR(hintTier), _tier + 1] call EFUNC(adapter_alive,setData);
};
// Into the friendly G2 as well - see FUNC(ladderCircle). The hint pool
// carries no side; the adapter files it against the hostile commander.
if (_alive && {!isNil QEFUNC(adapter_alive,reportIntel)}) then {
    [_side, sideUnknown, _id, _centre, _type] call EFUNC(adapter_alive,reportIntel);
};

["circle",
    format [QGVAR(hint_%1), _id],
    _centre, _radius, "", "", toUpper _type, _side
] call FUNC(sendProduct);

INFO_3("intel hint: %1 '%2', %3 m circle",_type,_id,round _radius);
true
