#include "script_component.hpp"
/*
 * Author: YonV
 * One aircraft down. Tells the side and its thread, and the respawn count
 * decides what comes next (user, 2026-11-02: "make sure there is a respawn
 * count for each support, default no respawns"; FUNC(replace)): with a
 * respawn left the row reads REPLACING for the module's Respawn Delay - a
 * synced aircraft is rebuilt on its stand then (FUNC(respawn)), the way a
 * Simplex support replaces its vehicle, and a class module's next tasking
 * after the delay makes a new airframe over the module (user, 2026-11-02:
 * virtual until tasked); with none the asset is gone. The sortie's own watch sees the wreck and ends the sortie
 * (FUNC(finish)), which does not count it a second time.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: What killed it <OBJECT> (optional, default objNull)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh, _killer] call jmfsb_support_air_fnc_lost
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_killer", objNull, [objNull]]];

if (isNull _logic) exitWith {};

WARNING_3("%1 lost '%2' to '%3'",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],typeOf _veh,typeOf _killer);

// The MPKilled handlers run this on the server only, wherever the aircraft
// was local - a synced aircraft a player took the stick of still counts and
// is still announced.
if (!isServer) exitWith {};
// One airframe, one count: a write-off that is then shot down is not lost
// twice.
if (_veh getVariable [QGVAR(counted), false]) exitWith {};
_veh setVariable [QGVAR(counted), true];

// THE ASSET'S THREAD (2026-11-01): a sortie that was flying ends CLOSED with
// the loss; an aircraft lost before it flew the task (on the stand, waiting
// to launch) could not take it - DECLINED.
private _flying = !((_logic getVariable [QGVAR(status), STATUS_IDLE]) in [STATUS_IDLE, STATUS_LAUNCHING]);
private _state = ["DECLINED", "CLOSED"] select _flying;

// THE LOSS IS A FLASH MESSAGE IN ITS THREADS before they close (user,
// 2026-11-05), raised through the core's event so the handler finds them.
private _fnc_tell = {
    params ["_rest"];
    [QEGVAR(support,aircraftEvent), [_veh, format [EVENT_DOWN, mapGridPosition _veh, _rest], true]] call CBA_fnc_localEvent;
};
if !([_logic] call FUNC(replace)) exitWith {
    private _line = format ["is down at %1 - no replacement", mapGridPosition _veh];
    [EVENT_NO_REPLACE] call _fnc_tell;
    [_logic, _line, "high"] call FUNC(say);
    [_logic, _state, _line] call FUNC(threadState);
};

private _delay = _logic getVariable [QGVAR(respawnDelay), MODULE_RESPAWN_DELAY];
private _line = format ["is down at %1 - replacement in %2 sec", mapGridPosition _veh, round _delay];
[format [EVENT_REPLACE_IN, round _delay]] call _fnc_tell;
[_logic, _line, "high"] call FUNC(say);
[_logic, _state, _line] call FUNC(threadState);

if (_veh isEqualTo (_logic getVariable [QGVAR(synced), objNull])) then {
    [FUNC(respawn), [_logic, _veh], _delay] call CBA_fnc_waitAndExecute;
};
