#include "script_component.hpp"
/*
 * Author: YonV
 * Reads the module and arms qrf. PLACING THE MODULE IS THE ENABLE - with no
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
    WARNING("a second JMSB - QRF module was placed - ignored, one module runs this system");
};
GVAR(moduleUp) = true;

GVAR(holdTime) = _logic getVariable ["holdTime", 60];
GVAR(minPlayers) = _logic getVariable ["minPlayers", 1];
GVAR(squadsMin) = _logic getVariable ["squadsMin", 2];
GVAR(squadsMax) = _logic getVariable ["squadsMax", 5];
GVAR(asymMortarChance) = _logic getVariable ["asymMortarChance", 50];
GVAR(cooldown) = _logic getVariable ["cooldown", 1800];

// Nothing starts until the adapter says ALiVE is up, because every WHERE this
// system uses is read from it. Both paths are covered: a module is normally
// placed long before ALiVE finishes initialising, but one armed afterwards
// would otherwise wait forever on an event that has already fired.
// Without ALiVE the adapter PBO is skipped and its flag never exists; the
// jmfsb_qrf markers still work, so start on those alone - once the mission is
// running (user, 2026-11-02: "works with or without"): this module fires
// before postInit, which would otherwise reset the watch list under it.
//
// The same branch when ALiVE is loaded with no commanders (user, 2026-11-02:
// "same as not loaded"): the adapter's fallback, once it gives up.
private _without = {
    ["QRF", "watching jmfsb_qrf markers, the mission's enemy answers"] call EFUNC(common,aliveLoaded);
    [{time > 0}, { [] call FUNC(start) }] call CBA_fnc_waitUntilAndExecute;
};
if (isNil QEFUNC(adapter_alive,whenReady)) exitWith {
    call _without;
};
// Now when the adapter is ready already, and once only - not the ready CBA
// event any client could raise again (review R1).
[{ [] call FUNC(start) }, [], _without] call EFUNC(adapter_alive,whenReady);
