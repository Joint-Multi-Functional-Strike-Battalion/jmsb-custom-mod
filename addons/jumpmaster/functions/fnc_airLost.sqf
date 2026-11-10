#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a JMSB - Jump Aircraft module's aircraft is LOST - destroyed (its
 * MPKilled), or its pilot dead or unable to fly (FUNC(airTick)) - and THE
 * RESPAWN COUNT decides (user, 2026-11-02: "make sure there is a respawn count
 * for each support, default no respawns"; virtual until tasked the same day).
 * A respawn left: one fewer, the row reads REPLACING for the module's Respawn
 * Delay, then the module is virtual again and the next request makes a new
 * aircraft. None left: the jump aircraft is gone - no row in TAC//MSG
 * (FUNC(assets)), every card UNABLE - NO AIRFRAME (FUNC(asset)), and the
 * side's own settings aircraft does not come back. Going home is not a loss
 * (FUNC(airTick) removes it, no respawn used).
 *
 * The aircraft is counted once. A run waiting for its BOARD is CLOSED
 * AIRCRAFT LOST; a run in flight ends by its own watch (FUNC(srvTick) reads
 * QGVAR(lost)). The wreck stays.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: Why, for the RPT <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh, "shot down"] call jmfsb_jumpmaster_fnc_airLost
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_why", "", [""]]];

if (!isServer || {isNull _logic}) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("airLost: refused - remote call from machine %1",remoteExecutedOwner);
};
if (_veh getVariable [QGVAR(lost), false]) exitWith {};
if ((_logic getVariable [QGVAR(veh), objNull]) isNotEqualTo _veh) exitWith {};
_veh setVariable [QGVAR(lost), true];

_logic setVariable [QGVAR(veh), objNull, true];
_logic setVariable [QGVAR(airPhase), AIR_REPLACING, true];
private _callsign = _logic getVariable [QGVAR(callsign), JUMP_CALLSIGN];

// A run that never boarded has nothing to fly.
{
    if ((_x getOrDefault ["logic", objNull]) isEqualTo _logic && {(_x get "phase") isEqualTo PHASE_BOARD}) then {
        [_x] call FUNC(srvRelease);
        [_x, "CLOSED", SAID_LOST] call FUNC(threadState);
    };
} forEach +GVAR(runs);

private _left = _logic getVariable [QGVAR(respawns), MODULE_RESPAWNS];
if (_left <= 0) exitWith {
    _logic setVariable [QGVAR(airPhase), AIR_GONE, true];
    WARNING_2("jump aircraft '%1' %2 - no respawns left, gone from TAC//MSG",_callsign,_why);
};

private _delay = _logic getVariable [QGVAR(respawnDelay), MODULE_RESPAWN_DELAY];
_logic setVariable [QGVAR(respawns), _left - 1, true];
_logic setVariable [QGVAR(replaceAt), CBA_missionTime + _delay, true];
INFO_4("jump aircraft '%1' %2 - a new one can be tasked in %3 s, %4 respawns left after it",_callsign,_why,round _delay,_left - 1);

[{
    params ["_logic"];
    if (isNull _logic) exitWith {};
    if ((_logic getVariable [QGVAR(airPhase), AIR_VIRTUAL]) isNotEqualTo AIR_REPLACING) exitWith {};
    _logic setVariable [QGVAR(airPhase), AIR_VIRTUAL, true];
}, [_logic], _delay] call CBA_fnc_waitAndExecute;
