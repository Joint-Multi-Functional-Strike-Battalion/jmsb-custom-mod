// CBA Settings [ADDON: jmfsb_ecoti]
//
// OPERATING VALUES ONLY - how far the sensor reaches, how big the window is,
// where contrast starts to fall, how thick it draws, and the colour each side is drawn in. WHICH goggles carry ECOTI is the goggle's own
// config (jmfsb_ecoti_enabled = 1), never a setting.
//
// All client-side: every one of them changes only what this player sees.

// THE SWITCH (user, 2026-10-17: "a setting to disable AiTR" - "per user"). Off,
// nothing is drawn and nothing is scanned for this player, on every goggle; the
// goggles' NVG and thermal are untouched.
[
    QGVAR(aitr), "CHECKBOX",
    ["Enable AiTR", "Off: no AiTR boxes, labels or net cards for you, on any goggle. Your goggles' night vision and thermal are unaffected."],
    ["1st Joint Multi-Functional Strike Battalion", "ECOTI"],
    true,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(range), "SLIDER",
    ["Sensor range (m)", "How far the clip-on picks up heat. Nothing beyond it is drawn."],
    ["1st Joint Multi-Functional Strike Battalion", "ECOTI"],
    [50, 1500, 600, 0],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(windowSize), "SLIDER",
    ["Thermal window size", "Radius of the round thermal window, as a fraction of the screen height. Nothing is drawn outside it. A JMSB goggle set to NVG full screen has no window - the whole screen is thermal."],
    ["1st Joint Multi-Functional Strike Battalion", "ECOTI"],
    [0.1, 0.5, 0.375, 3],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(nearDistance), "SLIDER",
    ["Full contrast distance (m)", "Inside this a box is drawn at full contrast. Past it, out to the sensor range, it fades."],
    ["1st Joint Multi-Functional Strike Battalion", "ECOTI"],
    [10, 300, 75, 0],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(lineWidth), "SLIDER",
    ["Box line width (px)", "How thick box lines are drawn, in screen pixels."],
    ["1st Joint Multi-Functional Strike Battalion", "ECOTI"],
    [1, 8, 3, 0],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(colorPlayer), "COLOR",
    ["Own faction colour", "Anyone of your own faction, and vehicles they crew."],
    ["1st Joint Multi-Functional Strike Battalion", "ECOTI"],
    [0.2, 0.45, 1],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(colorFriendly), "COLOR",
    ["Same side colour", "Another faction on your side or a friendly one, and vehicles they crew."],
    ["1st Joint Multi-Functional Strike Battalion", "ECOTI"],
    [0.2, 0.9, 0.3],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(colorEnemy), "COLOR",
    ["Armed colour", "Anyone hostile to your side, a civilian carrying a weapon, and vehicles they crew. Unarmed civilians are white; empty vehicles, animals and anyone of no side are yellow."],
    ["1st Joint Multi-Functional Strike Battalion", "ECOTI"],
    [1, 0.3, 0.25],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(labels), "CHECKBOX",
    ["AiTR labels", "Under each box, what it is, one thing about it and its range - PERSON | ARMED | 240 m."],
    ["1st Joint Multi-Functional Strike Battalion", "ECOTI"],
    true,
    false
] call CBA_fnc_addSetting;
