#include "script_component.hpp"
/*
 * Author: YonV
 * Seconds for a jump aircraft class to fly a distance at PLANE_START_SPEED of
 * its top speed - its cruise (FUNC(spawnAircraft)). By default the run-in
 * (RUN_IN m): a side's own aircraft from WHEELS UP to the red light. A
 * module's (virtual until tasked, user 2026-11-02) from the module to the red
 * light. Cheap - the class alone, no aircraft - so the reach card and the
 * WILCO can say it before anything flies.
 *
 * Arguments:
 * 0: Aircraft class <STRING>
 * 1: Distance, m (optional, default RUN_IN) <NUMBER>
 *
 * Return Value:
 * Seconds, ETA_UNKNOWN (-1) when the class has no top speed <NUMBER>
 *
 * Example:
 * ["B_T_VTOL_01_infantry_F"] call jmfsb_jumpmaster_fnc_runEta
 *
 * Public: No
 */

params [["_cls", "", [""]], ["_dist", RUN_IN, [0]]];

private _ms = getNumber (configFile >> "CfgVehicles" >> _cls >> "maxSpeed") / KMH_PER_MS * PLANE_START_SPEED;
if (_ms <= 0) exitWith {ETA_UNKNOWN};

_dist / _ms
