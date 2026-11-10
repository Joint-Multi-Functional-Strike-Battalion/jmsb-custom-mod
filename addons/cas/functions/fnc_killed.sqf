#include "script_component.hpp"
/*
 * Author: YonV
 * One airframe lost, on the server (MPKilled, FUNC(spawnDrone)).
 *
 * THIS IS THE WHOLE REASON THE DRONE IS A REAL AIRCRAFT. A scripted explosion
 * over the target cannot be shot down, so nothing the enemy does about it
 * matters. An airframe that is flown, seen, engaged and struck off a ledger
 * makes the air defence on the ridge worth putting there.
 *
 * THE RESPAWN COUNT DECIDES (user, 2026-11-02: "make sure there is a respawn
 * count for each support, default no respawns"; it replaces Airframes
 * Available): the module's drone lost - on its run or flying home after it
 * (user, 2026-11-02: virtual until tasked) - is a replacement spent, after its
 * Respawn Delay, or - none left - the asset gone from the list (FUNC(gone)).
 * One airframe is counted once.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: What killed it <OBJECT> (optional, for the log)
 * 2: The drone <OBJECT> (optional)
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_killer", objNull, [objNull]], ["_veh", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};

private _callsign = _logic getVariable [QGVAR(callsign), "CAS"];
WARNING_2("%1 shot down by '%2'",_callsign,typeOf _killer);

if (isNull _veh || {_veh getVariable [QGVAR(counted), false]}) exitWith {};
_veh setVariable [QGVAR(counted), true];
[_logic, "shot down"] call FUNC(gone);
