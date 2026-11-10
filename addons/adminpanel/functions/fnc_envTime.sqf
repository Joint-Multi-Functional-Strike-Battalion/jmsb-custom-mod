#include "script_component.hpp"
/*
 * Author: YonV
 * Server side of SET TIME, by remoteExec from FUNC(envApply): the clock to the
 * given hour and minute, today, and the speed of time. setDate and
 * setTimeMultiplier run on the server and the engine carries them to every
 * client. Only an admin by the server's records may (review S7).
 *
 * Arguments:
 * 0: Hour <NUMBER>
 * 1: Minute <NUMBER>
 * 2: Time multiplier <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [6, 30, 1] remoteExecCall ["jmfsb_adminpanel_fnc_envTime", 2]
 *
 * Public: No
 */

params [["_hour", 0, [0]], ["_minute", 0, [0]], ["_speed", 1, [0]]];

if (!isServer || {!([] call EFUNC(common,senderIsAdmin))}) exitWith {};
([] call EFUNC(common,sender)) params ["", "_admin"];
private _by = [name _admin, "server"] select isNull _admin;

private _date = date;
_date set [3, _hour];
_date set [4, _minute];
setDate _date;
setTimeMultiplier _speed;

INFO_4("time set to %1:%2 x%3 by %4",_hour,_minute,_speed,_by);
