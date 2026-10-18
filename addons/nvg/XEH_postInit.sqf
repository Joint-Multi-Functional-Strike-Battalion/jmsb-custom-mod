#include "script_component.hpp"

["visionMode", {
    params ["_unit", "_visionMode"];
    [] spawn jmfsb_nvg_fnc_setNvgEffect;
}, true] call CBA_fnc_addPlayerEventHandler;

// THE TUBE MASK ("NVG full screen" off). Client-side, and on events only: each
// of these can change whether the mask is up or which one it is. The setting's
// own change runs FUNC(updateMask) too (initSettings.inc.sqf).
if (!hasInterface) exitWith {};

{
    [_x, {[] call FUNC(updateMask)}] call CBA_fnc_addPlayerEventHandler;
} forEach ["visionMode", "loadout", "weapon", "unit", "vehicle", "cameraView", "featureCamera"];

// Remote control and UAV views move the camera without any of the above.
addMissionEventHandler ["PlayerViewChanged", {[] call FUNC(updateMask)}];

// The goggle may already be on and in NVG when the mission starts.
[] call FUNC(updateMask);

// CBA's picture-in-picture scopes in the goggle's mode - see FUNC(syncPipVision).
[LINKFUNC(syncPipVision), PIP_TICK, []] call CBA_fnc_addPerFrameHandler;
