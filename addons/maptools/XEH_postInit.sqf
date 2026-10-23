#include "script_component.hpp"

if (!hasInterface) exitWith {};

// A press on the map that closes an open app belongs to the app - see
// FUNC(hasInput). Stamped here whichever of the two handlers runs first.
[QEGVAR(tacpad,appClosed), {
    GVAR(closedFrame) = diag_frameNo;
}] call CBA_fnc_addEventHandler;

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
    };
}];
