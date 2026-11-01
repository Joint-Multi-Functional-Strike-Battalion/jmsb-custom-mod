#include "script_component.hpp"

// THE SERVER FLIES THE RUN; the leader only asks - by remoteExec to
// FUNC(srvLaunch) / FUNC(srvAbort), which check the leader is the sender's own
// unit (review S7).
//
// EACH MAN IS BOARDED, LIT, PUT OUT AND TOLD WHERE HE IS LOCAL - a player on
// his own machine, an AI on his leader's or a headless client's: the server
// sends FUNC(board), FUNC(light), FUNC(jump) and FUNC(say) there by
// remoteExec, and each takes it only from the server. The launch, abort,
// board, jumpOut, light and tell CBA events are gone: any client could raise
// them to put anyone aboard, throw anyone out or abort any squad's run.

if (!hasInterface) exitWith {};

[APP_ID, FUNC(app)] call EFUNC(tacpad,registerApp);

// The paper map carries the flight path like the tablet's.
addMissionEventHandler ["Map", {
    params ["_opened"];
    if (_opened) then {
        [(findDisplay IDD_MAP) displayCtrl IDC_HOST_MAP] call FUNC(attach);
    };
}];
