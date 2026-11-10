#include "script_component.hpp"
/*
 * Author: YonV
 * Tells ALiVE what air defence THIS mod's factions field.
 *
 * WHY THIS EXISTS. mil_placement spawns AA from two sources: the mission
 * maker's own picker (the "AA Units" field), and - when that is left empty -
 * the ALIVE_factionDefaultAA hash. That hash ships with stock A3 factions
 * only, and ALiVE's own comment beside it is explicit: "Mod factions not
 * listed here yield no AA fallback". So every 2040 faction placed with an AA
 * count and an empty picker spawned NOTHING, silently, and the mission maker
 * had no way to know except by counting what appeared.
 *
 * WHAT COUNTS AS AA IS ALiVE'S OWN ANSWER - ALiVE_fnc_isAntiAirCapable, the
 * predicate its SEAD task uses (and FUNC(aaTargets) here): it asks what the
 * vehicle can SHOOT WITH rather than what its turret elevation is, so unarmed
 * high-mount hulls and radars fall out on their own. Reusing it means this
 * agrees with ALiVE about what air defence is, by construction.
 *
 * NOTHING ALREADY REGISTERED IS OVERWRITTEN. A faction ALiVE knows, or one a
 * mission has set up itself, keeps what it has; this only fills holes.
 *
 * TIMED OFF THE HASH, NOT OFF FUNC(ready). The fallback is read when a
 * placement module runs, which can be before OPCOM finishes standing up -
 * waiting for full adapter readiness would sometimes register too late to
 * matter. So it polls for the hash itself and writes the moment it exists.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */

if (!isServer) exitWith {};
if (GVAR(aaRegistered)) exitWith {};

[{
    params ["_args", "_handle"];
    _args params ["_t0"];

    // ALiVE not loaded at all, or taking longer than any real init: stop
    // rather than poll for the whole mission.
    if (CBA_missionTime - _t0 > AA_REGISTER_TIMEOUT) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        if (!isNil "ALIVE_factionDefaultAA") then {
            WARNING("gave up registering faction AA - ALIVE_factionDefaultAA never became writable");
        };
    };
    if (isNil "ALIVE_factionDefaultAA" || {isNil "ALiVE_fnc_hashSet"}
        || {isNil "ALiVE_fnc_hashGet"} || {isNil "ALIVE_fnc_isAntiAirCapable"}) exitWith {};

    [_handle] call CBA_fnc_removePerFrameHandler;
    GVAR(aaRegistered) = true;

    // The jmfsb content mod's factions, by prefix. A faction from another mod
    // is that mod's business. The prefix stays "jmfsb_" and is NOT jmfsb_:
    // this repo ships no factions of its own, and the classes being matched
    // are jmfsb's, which a server may load alongside this mod.
    //
    // THE SLICE LENGTH IS 6, NOT 5. It was 5 in jmfsb, compared against a
    // six-character string, so the test could never be true, _ours was always
    // empty and the function exited one line later without registering a
    // single AA class. ALIVE_factionDefaultAA was never written to.
    private _ours = [];
    {
        private _f = configName _x;
        if ((_f select [0, 6]) isEqualTo "jmfsb_") then { _ours pushBack _f };
    } forEach ("true" configClasses (configFile >> "CfgFactionClasses"));
    if (_ours isEqualTo []) exitWith {};

    // One CfgVehicles walk, bucketed by faction. Asking per faction would
    // walk the whole config once per faction - twenty-odd times over.
    private _byFaction = createHashMap;
    {
        private _cfg = _x;
        if (getNumber (_cfg >> "scope") == 2 && {getNumber (_cfg >> "isUav") == 0}) then {
            private _f = getText (_cfg >> "faction");
            if (_f in _ours) then {
                private _class = configName _cfg;
                if ([_class] call ALIVE_fnc_isAntiAirCapable) then {
                    (_byFaction getOrDefault [_f, [], true]) pushBackUnique _class;
                };
            };
        };
    } forEach ("true" configClasses (configFile >> "CfgVehicles"));

    private _set = 0;
    private _empty = [];
    {
        private _f = _x;
        private _aa = _byFaction getOrDefault [_f, []];
        if (_aa isEqualTo []) then { _empty pushBack _f; continue };
        // never stomp an entry ALiVE or the mission already made
        private _existing = [ALIVE_factionDefaultAA, _f] call ALiVE_fnc_hashGet;
        if (!isNil "_existing" && {_existing isEqualType []} && {count _existing > 0}) then { continue };
        _aa sort true;
        // ALiVE's own entries are one to three classes; a long list buys
        // nothing and makes the spawn less predictable.
        if (count _aa > AA_REGISTER_MAX) then { _aa resize AA_REGISTER_MAX };
        [ALIVE_factionDefaultAA, _f, _aa] call ALiVE_fnc_hashSet;
        _set = _set + 1;
        TRACE_2("faction AA default",_f,_aa);
    } forEach _ours;

    INFO_2("registered default AA for %1 of %2 faction(s) - ALiVE spawns none without this",_set,count _ours);
    // A faction of ours with no air defence at all is worth saying once: an
    // AA count on its placement module will still spawn nothing, and that is
    // now a roster fact rather than a missing registration.
    if (_empty isNotEqualTo []) then {
        INFO_1("no AA-capable vehicle in: %1",_empty joinString ", ");
    };
}, AA_REGISTER_POLL, [CBA_missionTime]] call CBA_fnc_addPerFrameHandler;
