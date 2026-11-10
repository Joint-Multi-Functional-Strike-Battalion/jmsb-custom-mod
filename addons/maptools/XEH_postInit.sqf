#include "script_component.hpp"

if (!hasInterface) exitWith {};

// A press on the map that closes an open app belongs to the app - see
// FUNC(hasInput). Stamped here whichever of the two handlers runs first.
[QEGVAR(tacpad,appClosed), {
    GVAR(closedFrame) = diag_frameNo;
    GVAR(closedTime) = diag_tickTime;
}] call CBA_fnc_addEventHandler;

// AN APP OPENING TAKES THE MARKER CARD DOWN (2026-11-01): the app is drawn
// over the map, and a card left standing on top of it covers the app.
[QEGVAR(tacpad,appOpened), {
    [] call FUNC(markerCardClose);
}] call CBA_fnc_addEventHandler;

// ACE's marker dialog finishing its own set-up - the point and the channel
// list are put right for a dialog this addon opened (FUNC(markerAceInit)).
// An event nobody raises without ACE.
[ACE_EDITING_EVENT, {_this call FUNC(markerAceInit)}] call CBA_fnc_addEventHandler;

// THE DEVICE'S MAP TAKES DOUBLE-CLICKS WITH THE TOOLS PANEL HIDDEN TOO
// (2026-11-01). The panel hangs the tools on the host map when it is built,
// and TOOLS on the strip can keep it from being built at all; a marker must
// still be placeable. Attaching twice is a no-op.
[{
    if (HOST_NATIVE) exitWith {};
    [(HOST_DISPLAY) displayCtrl IDC_HOST_MAP] call FUNC(attach);
}, ATTACH_TICK, []] call CBA_fnc_addPerFrameHandler;

// THE VANILLA MAP CARRIES THE DRAWINGS whether or not the tacpad suite is on
// it, so what was measured on the tablet is still there on the paper map. The
// TOOLS panel attaches to whichever host map it is drawn on as well; attaching
// twice is a no-op.
//
// CLOSING THE MAP STOPS THE TOOL - the drawings stay. A tool left taking
// clicks on a map nobody is looking at is the bug the PLP front end had.
addMissionEventHandler ["Map", {
    params ["_opened"];
    if (_opened) then {
        [(findDisplay IDD_MAP) displayCtrl IDC_HOST_MAP] call FUNC(attach);
    } else {
        [] call FUNC(stop);
        [findDisplay IDD_MAP] call FUNC(markerCardClose);
    };
}];
