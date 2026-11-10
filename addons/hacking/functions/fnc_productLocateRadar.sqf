#include "script_component.hpp"
/*
 * Author: YonV
 * LOCATE RADAR: every network's eyes, on the shrinking circle ladder.
 *
 * TWO SOURCES, ONE HUNT. The coastal radars are jmfsb's own objects
 * (jmfsb_antiship_radars); the rest - the SAM site's search set, a Clam Shell
 * on a hill - are ALiVE vehicle profiles the adapter picks out by class.
 * The player is hunting eyes, whoever owns them.
 *
 * A RADAR IS A SEPARATE TARGET FROM THE BATTERY IT FEEDS. The anti-ship design
 * splits them deliberately - kill the radar and the launchers are firing blind,
 * kill the launchers and the radar is still watching for the next lot. One
 * product for "the coastal site" would have hidden that split behind a single
 * circle.
 *
 * The pool is read off the live radar objects rather than a registry of
 * positions: a set that has been destroyed drops out on its own, which is what
 * makes working the coast feel like it is going somewhere.
 *
 * NOT FRIENDLY, rather than hostile. A radar is a building with an aerial - one
 * placed in Eden and never crewed answers `side` as civilian, and a
 * getFriend test would quietly exclude every one of them. The rule is that you
 * cannot hunt your own.
 *
 * Same ladder as everything else - see FUNC(ladderCircle) for the rules.
 *
 * Arguments:
 * 0: Where the hack happened <ARRAY>
 * 1: Asking side <SIDE>
 *
 * Return Value:
 * Anything plotted <BOOL>
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_side", sideUnknown, [sideUnknown]]];

private _pool = [];
{
    if (isNull _x || {!alive _x} || {side _x isEqualTo _side}) then {continue};
    // Keyed by grid: a radar is a PLACE to the ladder, and the lock needs an id
    // that survives the object being replaced.
    _pool pushBack [format ["radar_%1", mapGridPosition _x], getPosASL _x, side _x];
} forEach (missionNamespace getVariable [QEGVAR(antiship,radars), []]);

// ALiVE's radars are profiles: a profileID is already the stable id the
// ladder wants, and a dead set leaves the profile system on its own.
if (!isNil QEFUNC(adapter_alive,radars)) then {
    {
        _x params ["_id", "_at", "_rside"];
        if (_rside getFriend _side >= 0.6) then {continue};
        _pool pushBack [_id, _at, _rside];
    } forEach (call EFUNC(adapter_alive,radars));
};

if (isNil QGVAR(radarLock)) then { GVAR(radarLock) = createHashMap };

[_pool, _pos, _side, GVAR(radarLock), "radar", "RADAR"] call FUNC(ladderCircle)
