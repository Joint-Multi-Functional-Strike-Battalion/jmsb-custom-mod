#include "script_component.hpp"

if (!isServer) exitWith {};

// The machine that made a drone names its launcher here (FUNC(init)).
[QGVAR(deployed), {_this call FUNC(deploy)}] call CBA_fnc_addEventHandler;

// A client's mode switch (the DRONES board) reaches FUNC(setMode) by
// remoteExecCall, so the server can check who sent it - no CBA event here.

// The jammer's noise in RF: links near a powered jammer drone degrade.
[{_this call FUNC(noise)}] call EFUNC(rf,addNoiseSource);

// Cleanup and power state.
[LINKFUNC(tick), TICK_S, []] call CBA_fnc_addPerFrameHandler;
