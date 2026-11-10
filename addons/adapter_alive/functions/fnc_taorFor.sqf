#include "script_component.hpp"
/*
 * Author: YonV
 * A side's ground, as its own placements declared it (new.md section 4): the
 * union of the "taor" marker lists, and separately the "blacklist" lists, of
 * every placement module that BELONGS TO THAT SIDE.
 *
 * WHOSE PLACEMENT IT IS, IS READ OFF THE PLACEMENT - NOT OFF WHAT IT IS
 * SYNCHRONISED TO. This walked each commander's synchronizedObjects and took
 * every placement it found there as that commander's own, and that is wrong on
 * any mission wired the way ALiVE actually documents: placements are matched to
 * commanders by FACTION, and syncing every placement to every OPCOM is a normal
 * and common way to build the map. On this collection's own Tanoa mission all
 * three OPCOMs - west, east and independent - are synchronised to all three
 * placement sets, so every side came back owning "red", "blue" AND "green".
 *
 * That is not a cosmetic error. A side that owns every TAOR passes
 * EFUNC(common,taorGate) everywhere: the gate's own-ground half is satisfied by
 * any marker, and the foreign-ground half subtracts anything the side "claims",
 * which was everything. The RPT shows what that looked like - fifty-five UAS
 * patrols, not one gate refusal, not one objective dropped, and green drones
 * orbiting inside the red TAOR while red ones orbited inside the green. Every
 * consumer of this function was affected the same way: air defence batteries,
 * QRF origins, insurgent safe houses, drone caches.
 *
 * So the owner is the placement's OWN faction, turned into a side by
 * EFUNC(common,sideOfFaction). Only a placement that declares no faction at all
 * - ALiVE's IED module is one - falls back to the commander it is synced to,
 * and only when it is synced to exactly ONE: two commanders and nobody can say
 * whose ground it describes, so it is dropped rather than handed to both.
 *
 * The keys are plain object variables on the placement logic - verified:
 * mil_placement fnc_MP.sqf:346/360 and civ_placement fnc_CP.sqf:208/222 -
 * holding an ARRAY of marker names. They arrive from Eden as a comma
 * separated STRING and are split at module init, so a read that races that
 * can still see the string; both shapes are accepted rather than trusting
 * the timing. "faction" is read the same way and is a plain string.
 *
 * An empty taor list means the whole map minus the blacklist - ALiVE's own
 * convention, passed through untouched.
 *
 * Arguments:
 * 0: Side <SIDE>
 *
 * Return Value:
 * [taorMarkers <ARRAY of STRING>, blacklistMarkers <ARRAY of STRING>]
 *
 * Example:
 * [east] call jmfsb_adapter_alive_fnc_taorFor
 */

params [["_side", sideUnknown, [sideUnknown]]];

if (_side isEqualTo sideUnknown) exitWith {[[], []]};

// Clients answer from the published per-side marker lists - the walk below
// needs the commander instances, which live on the server. Marker NAMES
// only; see the publisher in XEH_postInit.
if (!GVAR(ready)) exitWith {
    private _pub = missionNamespace getVariable [QGVAR(taorPub), []];
    private _row = _pub param [_pub findIf {(_x param [0, sideUnknown]) isEqualTo _side}, []];
    [_row param [1, []], _row param [2, []]]
};

// CSV-or-array tolerance; markers that do not exist are dropped here rather
// than passed on for every consumer to trip over.
private _norm = {
    params ["_v"];
    private _list = if (_v isEqualType "") then {
        (_v splitString " ,") select {_x isNotEqualTo ""}
    } else {
        if (_v isEqualType []) then {+_v} else {[]}
    };
    _list select {markerShape _x isNotEqualTo ""}
};

private _cmds = call FUNC(commanders);

// EVERY PLACEMENT ON THE MAP, ONCE. Gathered across all commanders rather
// than only this side's, because a placement synchronised to somebody else's
// OPCOM - or to nobody's - still describes its own faction's ground.
private _mods = [];
{
    _x params ["", "", "", "_logic"];
    if (isNull _logic) then {continue};

    {
        if (_x isKindOf "Logic") then {_mods pushBackUnique _x};
    } forEach (synchronizedObjects _logic);
} forEach _cmds;

// WHICH SIDE RUNS WHICH FACTION, IN ALiVE'S OWN WORDS. Each commander lists
// the factions it fights with, so a placement naming one of them belongs to
// that commander's side - no config read, no assumption about how a mod
// numbered its faction. The config is the fallback underneath, for a faction
// no commander claims.
private _byFaction = createHashMap;
{
    _x params ["_cside", "", "", "", "_inst"];
    if (_inst isEqualTo []) then {continue};

    {
        if (_x isEqualType "" && _x isNotEqualTo "") then {_byFaction set [toLower _x, _cside]};
    } forEach ([_inst, "factions", []] call ALiVE_fnc_hashGet);
} forEach _cmds;

private _taor = [];
private _black = [];

{
    private _m = _x;

    private _t = _m getVariable "taor";
    private _b = _m getVariable "blacklist";
    if (isNil "_t" && {isNil "_b"}) then {continue};

    // The placement's own faction is the answer wherever there is one.
    private _fac = _m getVariable ["faction", ""];
    if !(_fac isEqualType "") then {_fac = ""};

    private _owner = _byFaction getOrDefault [toLower _fac, sideUnknown];
    if (_owner isEqualTo sideUnknown) then {
        _owner = [_fac] call EFUNC(common,sideOfFaction);
    };

    // No faction of its own: it belongs to the commander it is synchronised
    // to, and only if that is one commander. Said once per module - this
    // function is asked once a spawn by some callers.
    if (_owner isEqualTo sideUnknown) then {
        private _sides = [];
        {
            _x params ["_cside", "", "", "_logic"];
            if (!isNull _logic && {_m in synchronizedObjects _logic}) then {
                _sides pushBackUnique _cside;
            };
        } forEach _cmds;

        if (count _sides == 1) then {
            _owner = _sides # 0;
        } else {
            if !(_m in GVAR(ownerlessSaid)) then {
                GVAR(ownerlessSaid) pushBack _m;
                WARNING_2("placement '%1' declares no faction and is synchronised to %2 commanders - its TAOR is not attributed to any side",typeOf _m,count _sides);
            };
            continue;
        };
    };

    if (_owner isNotEqualTo _side) then {continue};

    if (!isNil "_t") then {
        { _taor pushBackUnique _x } forEach ([_t] call _norm);
    };
    if (!isNil "_b") then {
        { _black pushBackUnique _x } forEach ([_b] call _norm);
    };
} forEach _mods;

[_taor, _black]
