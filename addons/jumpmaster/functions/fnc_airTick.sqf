#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the watch on a JMSB - Jump Aircraft module's aircraft while it
 * exists, every AIR_TICK s (user, 2026-11-02: "all support aircraft needs to
 * be virtual till tasked"). Made by FUNC(airUp); by the module's
 * QGVAR(airPhase):
 *
 *   station, run   orbiting for the BOARD, or flying a run (FUNC(srvLaunch) ..
 *                  FUNC(srvEnd)) - nothing here but the loss check
 *   home           flying back to the module (FUNC(airHome)): inside
 *                  AIR_HOME_RING m of it, or past its AIR_HOME_TIME, and with
 *                  no player aboard, crew and airframe are deleted - no wreck -
 *                  and the module is virtual again, ready for the next request
 *
 * LOST in any phase - destroyed, its pilot dead, or unable to fly - is
 * FUNC(airLost)'s: the respawn count. The watch ends with the aircraft.
 *
 * Arguments:
 * 0: [module logic, aircraft] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(airTick), AIR_TICK, [_logic, _veh]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]]];

private _fnc_delete = {
    {_veh deleteVehicleCrew _x} forEach (crew _veh);
    deleteVehicle _veh;
};

if (isNull _logic) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    if (!isNull _veh && {(crew _veh) findIf {isPlayer _x} < 0}) then {call _fnc_delete};
};
if ((_logic getVariable [QGVAR(veh), objNull]) isNotEqualTo _veh) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
};
// Deleted by something else (a Zeus, a clean-up): virtual again, not a loss.
if (isNull _veh) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    _logic setVariable [QGVAR(veh), objNull, true];
    _logic setVariable [QGVAR(airPhase), AIR_VIRTUAL, true];
};

if (!alive _veh || {!alive driver _veh} || {!canMove _veh}) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [_logic, _veh, ["cannot fly", "shot down"] select (!alive _veh)] call FUNC(airLost);
};

if ((_logic getVariable [QGVAR(airPhase), AIR_VIRTUAL]) isNotEqualTo AIR_HOME) exitWith {};
private _late = CBA_missionTime > (_logic getVariable [QGVAR(homeBy), 0]);
if (_veh distance2D _logic > AIR_HOME_RING && !_late) exitWith {};
// Never with a player aboard: he gets out first.
if ((crew _veh) findIf {isPlayer _x} > -1) exitWith {};

[_handle] call CBA_fnc_removePerFrameHandler;
call _fnc_delete;
_logic setVariable [QGVAR(veh), objNull, true];
_logic setVariable [QGVAR(airPhase), AIR_VIRTUAL, true];
private _where = ["", " where it was (late)"] select _late;
INFO_2("jump aircraft '%1' home - removed%2, virtual again",_logic getVariable [ARR_2(QGVAR(callsign),JUMP_CALLSIGN)],_where);
