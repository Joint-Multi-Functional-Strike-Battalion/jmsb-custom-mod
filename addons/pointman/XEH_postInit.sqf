#include "script_component.hpp"

if (!hasInterface) exitWith {};

[APP_ID, FUNC(app)] call EFUNC(tacpad,registerApp);

// THE PAPER MAP CARRIES THE ROUTE whether or not the tablet is open, the way
// the map tools' drawings are on both; the tablet's map is attached by the
// tick when one is up. Attaching twice is a no-op.
addMissionEventHandler ["Map", {
    params ["_opened"];
    if (_opened) then {
        [(findDisplay IDD_MAP) displayCtrl IDC_HOST_MAP] call FUNC(attach);
    };
}];

// Arrival, and the tablet's map.
[LINKFUNC(tick), PM_TICK, []] call CBA_fnc_addPerFrameHandler;
