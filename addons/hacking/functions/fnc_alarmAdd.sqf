#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: arms one alarm. The list is kept here rather than on the setter's
 * machine, for the reason alarm clocks are not worn on the wrist of the person
 * who set them: the wake-up has to happen whether or not that person is still
 * around. Each entry carries an id so a clear can pull it out from under its
 * own waiter, which then finds its id gone and does nothing.
 *
 * Firing removes the entry first and rings second, so a ring can never be
 * doubled by a clear racing it.
 *
 * The list is in localNamespace, published by FUNC(alarmPublish); the delay
 * is clamped and the armed count capped (review S7). Reached from clients
 * through FUNC(srvAlarmAdd), which names the setter from the sender.
 *
 * Arguments:
 * 0: Seconds from now <NUMBER>
 * 1: Who set it, for the ring notification <STRING>
 *
 * Return Value:
 * Armed <BOOL>
 *
 * Example:
 * [300, "Smith"] call jmfsb_hacking_fnc_alarmAdd
 *
 * Public: No
 */

params [["_delay", 0, [0]], ["_name", "someone", [""]]];

if (!isServer || _delay <= 0) exitWith {false};

private _alarms = localNamespace getVariable [QGVAR(alarms), []];
if (count _alarms >= SCN_ALARM_MAX_ARMED) exitWith {
    WARNING_2("alarmAdd: refused for %1 - %2 alarms armed already",_name,count _alarms);
    false
};

private _id = localNamespace getVariable [QGVAR(alarmNextId), 0];
localNamespace setVariable [QGVAR(alarmNextId), _id + 1];
private _at = CBA_missionTime + (SCN_ALARM_MIN_DELAY max _delay min SCN_ALARM_MAX_DELAY);

_alarms pushBack [_id, _at, _name];
localNamespace setVariable [QGVAR(alarms), _alarms];
[] call FUNC(alarmPublish);

[{
    params ["_id", "_at"];
    CBA_missionTime >= _at || {((localNamespace getVariable [QGVAR(alarms), []]) findIf {(_x select 0) == _id}) == -1}
}, {
    params ["_id", "", "_name"];
    private _list = localNamespace getVariable [QGVAR(alarms), []];
    private _i = _list findIf {(_x select 0) == _id};
    if (_i == -1) exitWith {};      // cleared while it waited
    _list deleteAt _i;
    [] call FUNC(alarmPublish);
    [_name] remoteExecCall [QFUNC(alarmRing), 0];
}, [_id, _at, _name]] call CBA_fnc_waitUntilAndExecute;

true
