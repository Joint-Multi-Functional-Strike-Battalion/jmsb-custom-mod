#include "script_component.hpp"

// CLIENT-SIDE ONLY. A dedicated server or headless client has no screen to draw
// on, and nothing here is ever sent over the network.
if (!hasInterface) exitWith {};

// ONE Draw3D handler, and it only draws from the caches below.
addMissionEventHandler ["Draw3D", {[] call FUNC(draw)}];

// Who and what is in range - twice a second.
[{[] call FUNC(updateCandidates)}, CANDIDATE_TICK, []] call CBA_fnc_addPerFrameHandler;

// Line of sight to each of them, a slice at a time.
[{[] call FUNC(updateVisibility)}, VIS_TICK, []] call CBA_fnc_addPerFrameHandler;

// This player's radio frequency, for everyone's net card - sent only when it changes.
[LINKFUNC(publishFreq), FREQ_TICK, []] call CBA_fnc_addPerFrameHandler;

// CTRL + SHIFT + N: N is the goggle key, so the clip-on's power sits on it.
[
    "1st Joint Multi-Functional Strike Battalion",
    QGVAR(power),
    ["ECOTI - power on/off", "Switches the clip-on thermal overlay on the NVG on or off."],
    {[] call FUNC(togglePower)},
    {false},
    [DIK_N, [true, true, false]]
] call CBA_fnc_addKeybind;
