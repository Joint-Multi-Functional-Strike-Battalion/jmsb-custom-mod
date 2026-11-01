#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A -- Tinkered with by YonV tinkered with by YonV
 * This function add eventhandlers.
 *
 * Example:
 * call jmfsb_init_fnc_eventHandlers
 *
 * Public: No
 */

INFO("InitEventHandlers","Creating Global EventHandlers");

// Player Events
if (GVAR(isPlayer)) then {
    INFO("InitEventHandlers","Creating Client EventHandlers");

    // Attendance comes back by remoteExec (FUNC(attendance)), not a CBA
    // event (review S7).

    // Map drawing restriction: DIRECT channel only, admins exempt
    call EFUNC(init,mapDrawing);

    // ACM Events
    INFO("InitEventHandlers","Creating ACM Server EventHandlers");

    ["ACM_casualtyEvacuated", {
        params ["_unit", "_originalUnit"];
        // By remoteExec, so the server knows who sent it (review R1).
        [_unit, _originalUnit] remoteExecCall [QFUNC(srvEvacuated), SERVER_OWNER];
        [_originalUnit] call EFUNC(groups,removeFromGroup);
        call EFUNC(init,playerpost);
        call EFUNC(groups,initGroupMenu);
    }] call CBA_fnc_addEventHandler;
};

// Server Events
if (!isServer) exitWith {};
INFO("InitEventHandlers","Creating Server EventHandlers");

// A client's RPT line comes by remoteExec to jmfsb_diag_fnc_srvLog, tagged with
// its sender - not the "jmfsb_log_text" CBA event, which let any client write
// any line into the server's RPT (review R1).

// Attendance is read where the connection log is kept and sent back to the
// machine that asked, an admin or a Zeus: by remoteExec to
// FUNC(srvAttendance), which checks the sender (review S7).

// The connection log is written by the server's own handler, straight to
// FUNC(logPlayer) - not the "jmfsb_log_player" CBA event, which let any client
// forge attendance (review R1).
addMissionEventHandler ["PlayerConnected", {
    params ["", "_uid", "_name"];
    [_uid, _name] call FUNC(logPlayer);
}];

// ACM: a client's evacuation reaches the server by remoteExec to
// FUNC(srvEvacuated), which checks the sender - not the
// "YMF_casualtyEvacuatedserver" CBA event (review R1).




