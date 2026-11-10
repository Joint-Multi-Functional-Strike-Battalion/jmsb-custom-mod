#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a JMSB - Jump Aircraft module's task is over - the run flown, or
 * stood down, aborted or never boarded (FUNC(srvRelease) for every ending) -
 * and its aircraft goes home (user, 2026-11-02: "all support aircraft needs to
 * be virtual till tasked"): back to AIR_ALT m, to the module, where its watch
 * (FUNC(airTick)) removes it - inside AIR_HOME_RING m with nobody aboard, or
 * AIR_HOME_TIME s from now wherever it is. Its escorts go with it. Going home
 * uses no respawn; the next request makes a fresh, full aircraft.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic] call jmfsb_jumpmaster_fnc_airHome
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("airHome: refused - remote call from machine %1",remoteExecutedOwner);
};
if !((_logic getVariable [QGVAR(airPhase), AIR_VIRTUAL]) in [AIR_STATION, AIR_RUN]) exitWith {};
private _veh = _logic getVariable [QGVAR(veh), objNull];
if (!alive _veh) exitWith {};

(getPosATL _logic) params ["_mx", "_my"];
[_veh, AIR_ALT] call EFUNC(support,flyAt);
[_veh, [_mx, _my, 0], "NORMAL"] call EFUNC(support_air,moveTo);
_logic setVariable [QGVAR(homeBy), CBA_missionTime + AIR_HOME_TIME];
_logic setVariable [QGVAR(airPhase), AIR_HOME, true];
INFO_1("jump aircraft '%1' task over - RTB to the module",_logic getVariable [ARR_2(QGVAR(callsign),JUMP_CALLSIGN)]);
