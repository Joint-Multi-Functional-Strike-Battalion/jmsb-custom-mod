#include "script_component.hpp"
/*
 * Author: YonV
 * Reads the module and arms leader chain. PLACING THE MODULE IS THE ENABLE - with no
 * module this system does nothing at all.
 *
 * The attributes are operation values only: how many, how often, how likely.
 * WHERE and WHO are never asked for; they come from ALiVE's commanders, their
 * TAORs and their objectives - or, without ALiVE, from the mission itself
 * (see the bottom of this file).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};
if (!isServer) exitWith {};

// One module runs this system. A second would re-arm it and place everything
// twice over, so it says so in the log rather than quietly doing it.
if (GVAR(moduleUp)) exitWith {
    WARNING("a second JMSB - Leader Chain module was placed - ignored, one module runs this system");
};
GVAR(moduleUp) = true;

// Module-set ground, if any - markers that do not exist are dropped here.
GVAR(taorMarkers) = ((_logic getVariable ["taor", ""]) splitString " ,")
    select { _x isNotEqualTo "" && {markerShape _x isNotEqualTo ""} };

GVAR(poolCut) = _logic getVariable ["poolCut", 25];
GVAR(rotateEvery) = _logic getVariable ["rotateEvery", 1200];
GVAR(trapChance) = _logic getVariable ["trapChance", 50];
GVAR(pops) = _logic getVariable ["pops", 3];

// Nothing starts until the adapter says ALiVE is up, because every WHERE this
// system uses is read from it. Both paths are covered: a module is normally
// placed long before ALiVE finishes initialising, but one armed afterwards
// would otherwise wait forever on an event that has already fired.
// The adapter's whenReady runs it now in that case, and once only - not the
// ready CBA event any client could raise again (review R1).
//
// WITHOUT ALiVE IT STILL RUNS (user, 2026-11-02: "works with or without").
// Placing this module is the statement that the mission is an insurgency, so
// the mission's enemy is the insurgent side - or the side of a man synchronised
// to the module, whose faction then names the leaders' too. Ground is the
// module's TAOR field or the jmfsb_taor markers, the safe houses are in the
// map's towns. Started once the mission is running: this module fires before
// postInit, which would otherwise reset the chain's lists under it.
//
// The same branch when ALiVE is loaded with no commanders (user, 2026-11-02:
// "same as not loaded"): the adapter's fallback, once it gives up.
GVAR(syncedMan) = (_units select {_x isKindOf "CAManBase"}) param [0, objNull];
private _without = {
    ["Leader chain", "the mission's enemy, in the map's towns"] call EFUNC(common,aliveLoaded);
    [{time > 0}, { [] call FUNC(start) }] call CBA_fnc_waitUntilAndExecute;
};
if (isNil QEFUNC(adapter_alive,whenReady)) exitWith {
    call _without;
};
[{ [] call FUNC(start) }, [], _without] call EFUNC(adapter_alive,whenReady);
