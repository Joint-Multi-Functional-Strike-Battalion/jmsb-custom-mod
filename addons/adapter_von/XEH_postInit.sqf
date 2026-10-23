#include "script_component.hpp"

// TFAR or ACRE loaded: voice stood down (jmfsb_voice_active), nothing here runs.
if (!EGVAR(voice,active)) exitWith {};

// SERVER: the C2 and A2G custom channels, made first so they get the lowest
// free ids. CALL channels are made on their first call.
if (isServer) then {
    {
        [_x] call FUNC(ensureChannel);
    } forEach FIXED_KEYS;
    [] call FUNC(countChannels);
    [QGVAR(testChannel), {_this call FUNC(testChannel)}] call CBA_fnc_addEventHandler;
};

// CLIENT: Side and Command voice off, Global voice for admins only, the
// cut-offs - checked every second (an admin logs in). Once the mission
// display is up: the VON toggle blocked, Push To Talk and VON volume checked.
if (hasInterface) then {
    [FUNC(channels), CHANNELS_TICK_S] call CBA_fnc_addPerFrameHandler;
    [{!isNull (findDisplay DISPLAY_MISSION)}, {[] call FUNC(warn)}] call CBA_fnc_waitUntilAndExecute;
    [QGVAR(testResult), {_this call FUNC(testResult)}] call CBA_fnc_addEventHandler;
};
