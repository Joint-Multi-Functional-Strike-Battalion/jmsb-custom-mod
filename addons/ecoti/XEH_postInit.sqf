#include "script_component.hpp"

// BUILDING MARKS (user, 2026-11-06): the server's list, published for every
// AiTR (FUNC(markSet)). A client that publishes over the copy gets the
// server's back - only a copy that differs, so the server's own echo is
// never answered (the teleport list's loop, 2026-11-06).
if (isServer) then {
    if (isNil {localNamespace getVariable QGVAR(marks)}) then {
        localNamespace setVariable [QGVAR(marks), []];
    };
    [] call FUNC(markPublish);
    QGVAR(marks) addPublicVariableEventHandler {
        params ["", ["_value", []]];
        if (_value isEqualTo (localNamespace getVariable [QGVAR(marks), []])) exitWith {};
        WARNING("building marks overwritten by a client - publishing the server's own");
        [] call FUNC(markPublish);
    };
};

// THE OTHER DRAWING IS CLIENT-SIDE ONLY. A dedicated server or headless client
// has no screen to draw on.
if (!hasInterface) exitWith {};

// A ZEUS MARKS A BUILDING with ZEN's module and dialog (FUNC(zenMark)); the
// Eden module also places from Zeus, with its defaults.
if (isClass (configFile >> "CfgPatches" >> "zen_custom_modules")) then {
    [
        "1st Joint Multi-Functional Strike Battalion",
        "AiTR building mark",
        {_this call FUNC(zenMark)},
        "\a3\ui_f\data\map\markers\military\box_ca.paa"
    ] call zen_custom_modules_fnc_register;
};

// A PLAYER MARKS THE BUILDING UNDER HIS CROSSHAIR, the colour asked on numpad
// 6-9 on the phone or side device (FUNC(markKey)). Unbound by default.
[
    "1st Joint Multi-Functional Strike Battalion",
    QGVAR(markKey),
    ["AiTR - mark building", "Marks the building under your crosshair for every AiTR. Pick the colour on numpad 6-9 on your phone or side device (0 / . for more); CLEAR takes a mark off. Without a device up, each press steps to the next colour."],
    {[] call FUNC(markKey)},
    {false}
] call CBA_fnc_addKeybind;

// ONE Draw3D handler, and it only draws from the caches below.
addMissionEventHandler ["Draw3D", {[] call FUNC(draw)}];

// Draw3D stops while the map is up, so the hide over the map and the tablet
// runs on EachFrame instead (FUNC(hideCovered)).
addMissionEventHandler ["EachFrame", {[] call FUNC(hideCovered)}];

// Who and what is in range - twice a second.
[{[] call FUNC(updateCandidates)}, CANDIDATE_TICK, []] call CBA_fnc_addPerFrameHandler;

// The side's open LZs and DZs (user, 2026-11-02) - twice a second.
[{[] call FUNC(updateZones)}, CANDIDATE_TICK, []] call CBA_fnc_addPerFrameHandler;

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

// Unbound by default: set it in Controls > Configure Addons.
[
    "1st Joint Multi-Functional Strike Battalion",
    QGVAR(hideNearKey),
    ["AiTR - hide close boxes on/off", "No AiTR boxes inside the 'Hide close boxes inside' distance (Addon Options > AiTR (ECOTI)), or boxes on everyone again."],
    {[] call FUNC(toggleHideNear)},
    {false}
] call CBA_fnc_addKeybind;
