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
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    true,
    false
] call CBA_fnc_addSetting;

// THE RANGES, BY WHAT IS LOOKED AT (user, 2026-10-24: "reduce the AiTR range
// down to 100 for people AI and 250 for players, 250 for vehicles, but if you
// use our vector push it out to 750 meters"). Nothing beyond its range is
// drawn; through a Vector every class reaches the Vector range.
[
    QGVAR(rangeAi), "SLIDER",
    ["Range: AI on foot (m)", "How far the clip-on picks up a man who is not a player."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    [10, 1500, 100, 0],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(rangePlayer), "SLIDER",
    ["Range: players on foot (m)", "How far the clip-on picks up another player."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    [10, 1500, 250, 0],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(rangeVehicle), "SLIDER",
    ["Range: vehicles and animals (m)", "How far the clip-on picks up a vehicle or an animal."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    [10, 3000, 250, 0],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(rangeVector), "SLIDER",
    ["Range through a Vector (m)", "Looking through a [JMSB] Vector Designator (or any ACE Vector), every class reaches this far."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    [50, 3000, 750, 0],
    false
] call CBA_fnc_addSetting;

// NOTHING RIGHT BESIDE HIM (user, 2026-10-25: "turn off the boxes within
// 10 m ... add a keybind to toggle it"). The key flips hideNear.
[
    QGVAR(hideNear), "CHECKBOX",
    ["Hide close boxes", "No AiTR box on anyone or anything closer than the distance below. Toggle it with the 'AiTR - hide close boxes on/off' key."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    true,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(hideNearDistance), "SLIDER",
    ["Hide close boxes inside (m)", "With 'Hide close boxes' on, nothing this close or closer is boxed."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    [1, 50, 10, 0],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(windowSize), "SLIDER",
    ["Thermal window size", "Radius of the round thermal window, as a fraction of the screen height. Nothing is drawn outside it. A JMSB goggle set to NVG full screen has no window - the whole screen is thermal."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    [0.1, 0.5, 0.375, 3],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(nearDistance), "SLIDER",
    ["Full contrast distance (m)", "Inside this a box is drawn at full contrast. Past it, out to the sensor range, it fades."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    [10, 300, 75, 0],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(lineWidth), "SLIDER",
    ["Box line width (px)", "How thick box lines are drawn, in screen pixels."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    [1, 8, 3, 0],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(colorPlayer), "COLOR",
    ["Own faction colour", "Anyone of your own faction, and vehicles they crew."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    [0.2, 0.45, 1],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(colorFriendly), "COLOR",
    ["Same side colour", "Another faction on your side or a friendly one, and vehicles they crew."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    [0.2, 0.9, 0.3],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(colorEnemy), "COLOR",
    ["Armed colour", "Anyone hostile to your side, a civilian carrying a weapon, and vehicles they crew. Unarmed civilians are white; empty vehicles, animals and anyone of no side are yellow."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    [1, 0.3, 0.25],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(labels), "CHECKBOX",
    ["AiTR labels", "Under each box, what it is, one thing about it and its range - PERSON | ARMED | 240 m."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    true,
    false
] call CBA_fnc_addSetting;

// THE COMPASS (user, 2026-10-19: "a compass on the top like DUI has"). Only
// while AiTR is drawing; off, the overlay is boxes and labels alone.
[
    QGVAR(compass), "CHECKBOX",
    ["Show AiTR compass", "A line compass across the top of the screen while AiTR is on, your heading marked in the TAC//PAD accent colour."],
    ["JMSB - Gear & Vision", "AiTR (ECOTI)"],
    true,
    false
] call CBA_fnc_addSetting;
