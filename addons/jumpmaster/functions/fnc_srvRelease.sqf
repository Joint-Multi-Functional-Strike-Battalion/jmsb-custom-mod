#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a run gives its aircraft back - over (FUNC(srvEnd)), never launched
 * (FUNC(srvLaunch)), stood down before WHEELS UP or BOARD (FUNC(srvAbort)), or
 * its aircraft lost before BOARD (FUNC(airLost)). The run leaves the list,
 * the squad's published run is cleared (its row and reach read free again),
 * and a JMSB - Jump Aircraft module's aircraft (user, 2026-11-02) is sent home
 * to be removed (FUNC(airHome) - virtual until tasked) and the module is free:
 * after its cooldown when it flew, at once when it never did.
 *
 * Arguments:
 * 0: The run <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_st] call jmfsb_jumpmaster_fnc_srvRelease
 *
 * Public: No
 */

params [["_st", createHashMap, [createHashMap]]];

if (!isServer) exitWith {};
if (isRemoteExecuted) exitWith {
    WARNING_1("srvRelease: refused - remote call from machine %1",remoteExecutedOwner);
};

private _at = GVAR(runs) findIf {(_x get "thread") isEqualTo (_st get "thread")};
if (_at >= 0) then {GVAR(runs) deleteAt _at};

private _group = _st getOrDefault ["group", grpNull];
if (!isNull _group) then {_group setVariable [QGVAR(run), [], true]};

private _logic = _st getOrDefault ["logic", objNull];
if (isNull _logic) exitWith {};
if !(_logic getVariable [QGVAR(busy), false]) exitWith {};

_logic setVariable [QGVAR(busy), false, true];
_logic setVariable [QGVAR(run), [], true];
// THE TASK IS OVER, HOWEVER IT ENDED (user, 2026-11-02: virtual until
// tasked): its aircraft flies home to the module and is removed there.
[_logic] call FUNC(airHome);
if (_st getOrDefault ["flown", false]) then {
    _logic setVariable [QGVAR(readyAt), CBA_missionTime + (_logic getVariable [QGVAR(cooldown), 0]), true];
};
