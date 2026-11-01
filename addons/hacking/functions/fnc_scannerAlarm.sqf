#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_scannerAlarm

Description:
    One press of the alarm key. Dialled like a kitchen timer: each press adds
    SCN_ALARM_STEP to the total on the screen, and SCN_ALARM_ARM_DELAY seconds
    after the last press the total arms itself and goes to the server. No
    confirm key, because there is no key to confirm with - stopping pressing IS
    the confirmation.

    There can be any number of armed alarms: dialling a new one never touches
    the ones already running, it just adds another. While a ring is going the
    press means something else entirely - shut up - and dials nothing, so
    silencing an alarm can never accidentally start one.

Parameters:
    None - the dial state lives in GVAR(alarmPending) / GVAR(alarmPressAt).

Author:
    JMSB
---------------------------------------------------------------------------- */

if (time < GVAR(alarmRingUntil)) exitWith { GVAR(alarmRingUntil) = -1 };

GVAR(alarmPending) = GVAR(alarmPending) + SCN_ALARM_STEP;
GVAR(alarmPressAt) = time;

// Every press schedules its own arm check; only the one whose stamp is still
// the latest actually arms, so the timer effectively restarts with each press.
[{
    params ["_stamp"];
    if (GVAR(alarmPressAt) != _stamp || GVAR(alarmPending) <= 0) exitWith {};
    [GVAR(alarmPending)] remoteExecCall [QFUNC(srvAlarmAdd), SERVER_OWNER];
    ["Alarm", format ["Alarm armed: %1 min, all scanners.", GVAR(alarmPending) / 60],
        [0.914, 0.651, 0.235, 1]] call EFUNC(notify,notify);
    GVAR(alarmPending) = 0;
}, [GVAR(alarmPressAt)], SCN_ALARM_ARM_DELAY] call CBA_fnc_waitAndExecute;
