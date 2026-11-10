#include "script_component.hpp"
/*
 * Author: YonV
 * Is ALiVE loaded - and, when it is not, says once in the RPT what a feature
 * does instead.
 *
 * RUNS WITH OR WITHOUT ALiVE (user, 2026-11-02: "works with or without" - "if
 * alive is present we integrate"). ALiVE is its own main PBOs (user,
 * 2026-11-02: "use the alive main pbo names"): every CfgPatches class in
 * PATCHES_ALIVE, and the adapter's own class (ADAPTER_PATCH) beside them, so a
 * yes always means the adapter's functions exist. Both hold from preInit on,
 * before any function is compiled.
 *
 * SAME AS NOT LOADED (user, 2026-11-02). ALiVE loaded with no commander at
 * all gives the adapter nothing to read: after READY_GIVE_UP it declares ALiVE
 * absent for the mission (adapter_alive fnc_ready), and from then on this
 * answers no. The server reads its own truth in localNamespace; a client the
 * public copy.
 *
 * ONE LINE PER FEATURE, NOT ONE PER CALL. A feature that asks every capture or
 * every report would otherwise fill the RPT with the same sentence; the
 * features already told are kept in localNamespace.
 *
 * Each call into the adapter is still guarded where it is made, with
 * `isNil QEFUNC(adapter_alive,<function>)` (coding guidelines R6) - this is the
 * feature's decision and its RPT line, not a replacement for that.
 *
 * Arguments:
 * 0: Feature, for the RPT line <STRING> (optional - no line when empty)
 * 1: What the feature does without ALiVE <STRING> (optional, default "off")
 *
 * Return Value:
 * ALiVE (the adapter) is loaded and has not been declared absent <BOOL>
 *
 * Example:
 * if !(["Air defence", "using TAOR markers"] call jmfsb_common_fnc_aliveLoaded) then {...};
 *
 * Public: Yes
 */

params [["_feature", "", [""]], ["_without", "off", [""]]];

private _patches = configFile >> "CfgPatches";
private _present = isClass (_patches >> ADAPTER_PATCH)
    && {(PATCHES_ALIVE findIf {!isClass (_patches >> _x)}) < 0};
private _absent = false;
if (_present) then {
    private _ns = [missionNamespace, localNamespace] select isServer;
    _absent = _ns getVariable [QEGVAR(adapter_alive,absent), false];
};
private _loaded = _present && !_absent;
if (_loaded || (_feature isEqualTo "")) exitWith {_loaded};

private _told = localNamespace getVariable [QGVAR(aliveTold), []];
if !(_feature in _told) then {
    _told pushBack _feature;
    localNamespace setVariable [QGVAR(aliveTold), _told];
    private _why = ["not loaded", "loaded with no commanders - treated as not loaded"] select _absent;
    INFO_3("%1: ALiVE %2 - %3",_feature,_why,_without);
};

false
