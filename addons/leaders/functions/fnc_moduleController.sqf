#include "script_component.hpp"
/*
 * Author: JMSB
 * Reads the module and arms leader chain. PLACING THE MODULE IS THE ENABLE - with no
 * module this system does nothing at all.
 *
 * The attributes are operation values only: how many, how often, how likely.
 * WHERE and WHO are never asked for; they come from ALiVE's commanders, their
 * TAORs and their objectives.
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
if (isNil QEFUNC(adapter_alive,whenReady)) exitWith {};
[{ [] call FUNC(start) }] call EFUNC(adapter_alive,whenReady);
