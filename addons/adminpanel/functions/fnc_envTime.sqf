#include "script_component.hpp"
/*
 * Author: JMSB
 * Server side of SET TIME: the clock to the given hour and minute, today, and
 * the speed of time. setDate and setTimeMultiplier run on the server and the
 * engine carries them to every client.
 *
 * Arguments:
 * 0: Hour <NUMBER>
 * 1: Minute <NUMBER>
 * 2: Time multiplier <NUMBER>
 * 3: Admin who set it <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [6, 30, 1, "YonV"] call jmfsb_adminpanel_fnc_envTime
 *
 * Public: No
 */

params ["_hour", "_minute", "_speed", "_by"];

if (!isServer) exitWith {};

private _date = date;
_date set [3, _hour];
_date set [4, _minute];
setDate _date;
setTimeMultiplier _speed;

INFO_4("time set to %1:%2 x%3 by %4",_hour,_minute,_speed,_by);
