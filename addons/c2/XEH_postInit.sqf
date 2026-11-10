#include "script_component.hpp"

// The leaders' tablets save and delete; the server keeps the list.
[QGVAR(save), FUNC(save)] call CBA_fnc_addEventHandler;
[QGVAR(delete), FUNC(delete)] call CBA_fnc_addEventHandler;

if (!hasInterface) exitWith {};

[APP_ID, FUNC(app)] call EFUNC(tacpad,registerApp);
addMissionEventHandler ["Draw3D", {[] call FUNC(draw)}];
[FUNC(tick), TICK_SECONDS] call CBA_fnc_addPerFrameHandler;

// The action key near a measure reports the last event (jmfsb_watch).
if (!isNil QEGVAR(watch,fallbacks)) then {
    EGVAR(watch,fallbacks) set [QUOTE(COMPONENT), FUNC(report)];
};
