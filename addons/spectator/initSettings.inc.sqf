[
    QGVAR(enabled),
    "CHECKBOX",
    ["Enable spectator", "Enables spectator for dead players"],
    ["JMSB - Mission & Admin", "Spectator"],
    false,
    1,
    {[_this] call FUNC(toggle)}
] call CBA_fnc_addSetting;

[
    QGVAR(allowUnconscious),
    "CHECKBOX",
    ["Allow spectator for unconscious", "Allows spectator also for unconscious players. Requires enabling spectator."],
    ["JMSB - Mission & Admin", "Spectator"],
    false,
    1,
    {[_this] call FUNC(restart)}
] call CBA_fnc_addSetting;

[
    QGVAR(enabledUnconscious),
    "CHECKBOX",
    ["Enable spectator (CLIENT)", "Enables spectator when unconscious if it's allowed by server setting."],
    ["JMSB - Mission & Admin", "Spectator"],
    true,
    0,
    {[_this] call FUNC(restart)}
] call CBA_fnc_addSetting;

[
    QGVAR(unconsciousDelay),
    "SLIDER",
    ["Unconscious spectator delay", "How much time must pass before unconscious players get spectator."],
    ["JMSB - Mission & Admin", "Spectator"],
    [1, 300, 30, 0],
    1
] call CBA_fnc_addSetting;

[
    QGVAR(sides),
    "LIST",
    ["Sides available for spectating", "Spectator will be able to see and track units from given sides."],
    ["JMSB - Mission & Admin", "Spectator"],
    [[0, 1, 3, 4, 2], ["Friendly", "Player side", "Player group", "str_player", "str_all_voices"], 0],
    1,
    {[_this] call FUNC(restart)}
] call CBA_fnc_addSetting;

[
    QGVAR(sidesUnconscious),
    "LIST",
    ["Sides available for spectating", "Spectator will be able to see and track units from given sides."],
    ["JMSB - Mission & Admin", "Spectator"],
    [[0, 1, 3, 4, 2], ["Friendly", "Player side", "Player group", "str_player", "str_all_voices"], 0],
    1,
    {[_this] call FUNC(restart)}
] call CBA_fnc_addSetting;

[
    QGVAR(civilianSide),
    "CHECKBOX",
    ["Allow civilian spectating", "Allows tracking units from civilian side."],
    ["JMSB - Mission & Admin", "Spectator"],
    false,
    1,
    {[_this] call FUNC(restart)}
] call CBA_fnc_addSetting;

[
    QGVAR(civilianSideUnconscious),
    "CHECKBOX",
    ["Allow civilian spectating", "Allows tracking units from civilian side."],
    ["JMSB - Mission & Admin", "Spectator"],
    false,
    1,
    {[_this] call FUNC(restart)}
] call CBA_fnc_addSetting;

[
    QGVAR(allowAI),
    "CHECKBOX",
    ["Allow AI spectating", "Allows tracking AI units from whitelisted sides."],
    ["JMSB - Mission & Admin", "Spectator"],
    false,
    1,
    {[_this] call FUNC(restart)}
] call CBA_fnc_addSetting;

[
    QGVAR(allowAIUnconscious),
    "CHECKBOX",
    ["Allow AI spectating", "Allows tracking AI units from whitelisted sides."],
    ["JMSB - Mission & Admin", "Spectator"],
    false,
    1,
    {[_this] call FUNC(restart)}
] call CBA_fnc_addSetting;

[
    QGVAR(freeCamera),
    "CHECKBOX",
    ["Allow free camera", "Allows spectator to move his camera freely."],
    ["JMSB - Mission & Admin", "Spectator"],
    false,
    1,
    {[_this] call FUNC(restart)}
] call CBA_fnc_addSetting;

[
    QGVAR(freeCameraUnconscious),
    "CHECKBOX",
    ["Allow free camera", "Allows spectator to move his camera freely."],
    ["JMSB - Mission & Admin", "Spectator"],
    false,
    1,
    {[_this] call FUNC(restart)}
] call CBA_fnc_addSetting;

[
    QGVAR(TPPCamera),
    "CHECKBOX",
    ["Allow TPP Camera", "Allows spectator to use third person camera."],
    ["JMSB - Mission & Admin", "Spectator"],
    false,
    1,
    {[_this] call FUNC(restart)}
] call CBA_fnc_addSetting;

[
    QGVAR(TPPCameraUnconscious),
    "CHECKBOX",
    ["Allow TPP Camera", "Allows spectator to use third person camera."],
    ["JMSB - Mission & Admin", "Spectator"],
    false,
    1,
    {[_this] call FUNC(restart)}
] call CBA_fnc_addSetting;
