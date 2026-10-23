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

// Scanner stopwatch. Declared here so the screen can read it on the very
// first frame, before anyone has touched the keybind.
GVAR(timerState) = SCN_T_IDLE;
GVAR(timerHeld) = 0;
GVAR(timerFrom) = 0;

// Scanner alarms. The armed list is server-owned and publicVariable'd - an
// alarm has to outlive its setter, and every screen has to show the same
// countdown. Everything else is local: the total being dialled in, and how long
// this handset keeps ringing.
GVAR(alarms) = [];
GVAR(alarmPending) = 0;
GVAR(alarmPressAt) = -1;
GVAR(alarmRingUntil) = -1;
GVAR(alarmBeepPFH) = -1;
if (isServer) then { GVAR(alarmNextId) = 0 };

// When the handset layer was last raised, so the tick knows when to renew.
GVAR(scannerRaisedAt) = -1e9;

ADDON = true;
