#include "script_component.hpp"
/*
 * Author: JMSB
 * Reads the module and arms air defence. PLACING THE MODULE IS THE ENABLE -
 * with no module this system does nothing at all.
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

if (GVAR(moduleUp)) exitWith {
    WARNING("a second Air Defence module was placed - ignored, one module runs this system");
};
GVAR(moduleUp) = true;

GVAR(sitesPerSide) = _logic getVariable ["sitesPerSide", 2];
GVAR(launchers) = _logic getVariable ["launchers", 3];
GVAR(spacing) = _logic getVariable ["spacing", 2500];
GVAR(teamsPerSide) = _logic getVariable ["teamsPerSide", 6];
GVAR(security) = _logic getVariable ["security", 1];
GVAR(openGround) = _logic getVariable ["openGround", 35];
// NO profileSites ANY MORE. The attribute offered battery hardware to ALiVE's
// runtime profiler, which deletes what it profiles - that is what left the
// sites standing empty. Air defence is a handful of statics; it stays live.
GVAR(rearmEvery) = _logic getVariable ["rearmEvery", AD_REARM_DEFAULT];
// Per side, keyed the way FUNC(sideKit) asks for it. The three commanders are
// three different armies; one class list for the whole map could not express
// Patriots on BLUFOR and Russian hardware on OPFOR.
//
// WRITTEN OUT, not built with format. Nine getVariable calls is duller than a
// loop over ["West", "East", "Guer"], but a name assembled at runtime appears
// nowhere in the source - so nothing can check the attribute is read, and a
// typo in either half becomes a silently empty setting. The plumbing check
// caught exactly that here.
// Module-set TAOR markers, per side. Parsed once; markers that do not exist
// are dropped here rather than tripping every consumer.
private _fnc_markers = {
    params ["_csv"];
    ((_csv splitString " ,") select {_x isNotEqualTo ""})
        select {markerShape _x isNotEqualTo ""}
};
GVAR(taors) = createHashMap;
GVAR(taors) set [str west, [_logic getVariable ["taorWest", ""]] call _fnc_markers];
GVAR(taors) set [str east, [_logic getVariable ["taorEast", ""]] call _fnc_markers];
GVAR(taors) set [str independent, [_logic getVariable ["taorGuer", ""]] call _fnc_markers];

GVAR(classes) = createHashMap;
GVAR(classes) set [str west, [
    _logic getVariable ["radarWest", ""],
    _logic getVariable ["launcherWest", ""],
    _logic getVariable ["manpadWest", ""],
    _logic getVariable ["manpadManWest", ""]
]];
GVAR(classes) set [str east, [
    _logic getVariable ["radarEast", ""],
    _logic getVariable ["launcherEast", ""],
    _logic getVariable ["manpadEast", ""],
    _logic getVariable ["manpadManEast", ""]
]];
GVAR(classes) set [str independent, [
    _logic getVariable ["radarGuer", ""],
    _logic getVariable ["launcherGuer", ""],
    _logic getVariable ["manpadGuer", ""],
    _logic getVariable ["manpadManGuer", ""]
]];

// Nothing starts until the adapter says ALiVE is up: every commander, TAOR and
// objective this reads comes from it. Both paths are covered - a module is
// normally placed long before ALiVE finishes initialising, but one armed
// afterwards would otherwise wait forever on an event that has already fired.
if (EGVAR(adapter_alive,ready)) exitWith {
    [] call FUNC(start);
};

[QEGVAR(adapter_alive,ready), { [] call FUNC(start) }] call CBA_fnc_addEventHandler;
