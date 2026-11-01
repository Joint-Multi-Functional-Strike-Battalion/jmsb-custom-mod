#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_hacking_fnc_alarmArm

Description:
    Arms an alarm from a client, and says so.

    THE ROSTER IS THE SERVER'S - see FUNC(alarmAdd) - because an alarm has to
    ring whether or not the man who set it is still around. This is the client
    half: it sends, and it confirms, so pressing an interaction entry produces
    something on screen rather than silence and a hope.

    Called from the ACE self-interaction menu and from anywhere else that wants
    to arm without knowing about the network.

Parameters:
    0: NUMBER - seconds from now.
    1: STRING - ignored; the server names the setter from the sender
       (review S7). Callers may still pass it.

Returns:
    BOOL - true if it was sent.

Example:
    [300] call jmfsb_hacking_fnc_alarmArm

Author:
    JMSB
---------------------------------------------------------------------------- */
params [["_delay", 0, [0]]];

if (!hasInterface || _delay <= 0) exitWith {false};

// By remoteExec, so the server knows who set it (review S7).
[_delay] remoteExecCall [QFUNC(srvAlarmAdd), SERVER_OWNER];

["Alarm", format ["Armed for %1 minutes.", (round (_delay / 6)) / 10], [0.6, 1, 0.6, 1]] call EFUNC(notify,notify);

true
