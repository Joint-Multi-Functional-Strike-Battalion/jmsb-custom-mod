#include "script_component.hpp"

ADDON = false;
LOG(MSG_INIT);

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// When this operator last broke into a net, newest last. Trimmed to the memory
// window on every read - see FUNC(netFailChance).
GVAR(netHistory) = [];

// The server's last answer to "what RF nodes can my set hear" (FUNC(rfReach)),
// and when it came - read by the tacpad HACK board.
GVAR(rfReach) = [];
GVAR(rfReachTime) = -1;

#include "initSettings.inc.sqf"

// Scanner alarms. The armed list is the server's, kept in localNamespace
// (review S7), with a public copy here for the screens - an alarm has to
// outlive its setter, and every screen has to show the same countdown.
// Everything else is local: the total being dialled in, and how long this
// handset keeps ringing.
GVAR(alarms) = [];
GVAR(alarmPending) = 0;
GVAR(alarmPressAt) = -1;
GVAR(alarmRingUntil) = -1;
GVAR(alarmBeepPFH) = -1;
if (isServer) then {
    localNamespace setVariable [QGVAR(alarms), []];
    localNamespace setVariable [QGVAR(alarmNextId), 0];
};


ADDON = true;
