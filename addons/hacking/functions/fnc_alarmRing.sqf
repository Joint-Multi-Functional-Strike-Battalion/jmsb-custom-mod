#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_alarmRing

Description:
    An alarm has gone off. The server sends this by remoteExec, and it runs only
    when it came from the server (review S7). It runs on every machine - the whole point of the
    thing is that one person sets it and the entire server's phones go - but a
    phone only rings if you are carrying one, so a player carrying no scanner
    hears nothing, exactly as if their pocket were empty.

    What counts as a scanner is the Scanner Items setting, which is wider than
    the terminal on purpose - an alarm you can set on a device but never hear
    from it is a clock with no bell.

    The ring is a beep on a slow loop until GVAR(alarmRingUntil) (the tacpad
    TIMER reads it too), and it gives up on its own after SCN_ALARM_RING
    seconds because an alarm nobody dismisses has still done its job. A second
    alarm landing mid-ring just pushes the deadline back; there is one beeper,
    not one per alarm.

Parameters:
    _name : STRING - who set it.

Author:
    JMSB
---------------------------------------------------------------------------- */
params [["_name", "someone", [""]]];

// Sent by the server alone (FUNC(alarmAdd)), by remoteExec: a client cannot
// ring every scanner on the net (review S7).
if (!hasInterface || {!([] call EFUNC(common,fromServer))}) exitWith {};

if !([player] call FUNC(hasScanner)) exitWith {};

GVAR(alarmRingUntil) = time + SCN_ALARM_RING;
["Alarm", format ["%1's alarm is going off.", _name], [0.816, 0.271, 0.227, 1]]
    call EFUNC(notify,notify);

if (GVAR(alarmBeepPFH) != -1) exitWith {};
GVAR(alarmBeepPFH) = [{
    params ["", "_handle"];
    if (time >= GVAR(alarmRingUntil)) exitWith {
        GVAR(alarmBeepPFH) = -1;
        [_handle] call CBA_fnc_removePerFrameHandler;
    };
    // playSoundUI rather than playSound for the volume knob: the beep obeys
    // the client's GVAR(alarmVolume) setting, and at 0 the ring is blink-only.
    if (GVAR(alarmVolume) > 0) then {
        playSoundUI ["3DEN_notificationWarning", GVAR(alarmVolume)];
    };
}, 1.2, []] call CBA_fnc_addPerFrameHandler;
