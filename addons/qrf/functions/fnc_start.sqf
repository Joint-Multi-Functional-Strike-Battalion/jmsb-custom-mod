#include "script_component.hpp"
/*
 * Author: JMSB
 * Gathers the objectives worth watching and starts the capture check.
 *
 * Called by FUNC(moduleController) once ALiVE is up - never on its own. The
 * module is the enable, so a mission with no module never reaches here.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Example:
 * [] call jmfsb_qrf_fnc_start
 */

if (!isServer) exitWith {};

[] call FUNC(gather);

// Gathered again once ALiVE is up, when this started without it. The ready
// hook runs once (review R1: it was a CBA event any client could raise to
// re-run it); the adapter is ready only once.
if (!isNil QEFUNC(adapter_alive,whenReady) && {!(missionNamespace getVariable [QEGVAR(adapter_alive,ready), false])}) then {
    [{ [] call FUNC(gather) }] call EFUNC(adapter_alive,whenReady);
};

[LINKFUNC(check), QRF_TICK, []] call CBA_fnc_addPerFrameHandler;
