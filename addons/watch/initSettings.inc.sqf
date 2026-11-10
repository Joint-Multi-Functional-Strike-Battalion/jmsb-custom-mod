// The watch HUD's player settings (docs/DESIGN_WATCH_HUD.json, settings_app).

[
    QGVAR(prompt), "LIST",
    ["Prompt mode", "FULL: key hints with words and the context prompt ('9: ADD TO MEDICAL'). REDUCED: key numbers only, no prompt."],
    [JMFSB_CATEGORY, "Watch HUD"], [["full", "reduced"], ["Full", "Reduced"], 0], 0
] call CBA_fnc_addSetting;

[
    QGVAR(shrink), "CHECKBOX",
    ["Shrink at distance", "Beyond 15 m a world panel shrinks to a tag: slot number, state colour, one value."],
    [JMFSB_CATEGORY, "Watch HUD"], true, 0
] call CBA_fnc_addSetting;

[
    QGVAR(autoClear), "CHECKBOX",
    ["Auto-clear", "A watched target that dies, or is lost past 300 m for a minute, comes off. Pinned slots stay."],
    [JMFSB_CATEGORY, "Watch HUD"], true, 0
] call CBA_fnc_addSetting;

[
    QGVAR(shareSeconds), "SLIDER",
    ["Share time", "SHARE on a contact nobody has in sight shows it to every friendly within 2 km for this many seconds."],
    [JMFSB_CATEGORY, "Watch HUD"], [5, 120, 20, 0], 1
] call CBA_fnc_addSetting;

[
    QGVAR(dropMinutes), "SLIDER",
    ["Drop lost contacts after", "Minutes a contact nobody has in sight is kept before it is forgotten."],
    [JMFSB_CATEGORY, "Watch HUD"], [1, 30, 5, 0], 1
] call CBA_fnc_addSetting;

[
    QGVAR(detectRange), "SLIDER",
    ["Engineer detect range", "Metres within which an engineer sees mines and explosives without a detector."],
    [JMFSB_CATEGORY, "Watch HUD"], [5, 50, 15, 0], 1
] call CBA_fnc_addSetting;

[
    QGVAR(squadViewSeconds), "SLIDER",
    ["Squad view time", "Seconds the squad view stays up after F4 (team leads and ATLs)."],
    [JMFSB_CATEGORY, "Watch HUD"], [5, 120, 30, 0], 0
] call CBA_fnc_addSetting;

// HUD ON / OFF PER PROFILE (design hud_settings_page): this player's world
// drawing only - the data still syncs and others are unaffected. A server or
// mission forcing one (CBA) locks it; the settings app shows the lock.
[
    QGVAR(hud_medical), "CHECKBOX",
    ["HUD: Medical", "Draw it in the world (AiTR goggles). Off hides it for you only."],
    [JMFSB_CATEGORY, "Watch HUD"], true, 0
] call CBA_fnc_addSetting;

[
    QGVAR(hud_team_lead), "CHECKBOX",
    ["HUD: Team lead", "Draw it in the world (AiTR goggles). Off hides it for you only."],
    [JMFSB_CATEGORY, "Watch HUD"], true, 0
] call CBA_fnc_addSetting;

[
    QGVAR(hud_engineer), "CHECKBOX",
    ["HUD: Engineer", "Draw it in the world (AiTR goggles). Off hides it for you only."],
    [JMFSB_CATEGORY, "Watch HUD"], true, 0
] call CBA_fnc_addSetting;

[
    QGVAR(hud_recon), "CHECKBOX",
    ["HUD: Recon contacts", "Draw it in the world (AiTR goggles). Off hides it for you only."],
    [JMFSB_CATEGORY, "Watch HUD"], true, 0
] call CBA_fnc_addSetting;

[
    QGVAR(hud_jfo), "CHECKBOX",
    ["HUD: JFO impact areas", "Draw it in the world (AiTR goggles). Off hides it for you only."],
    [JMFSB_CATEGORY, "Watch HUD"], true, 0
] call CBA_fnc_addSetting;

[
    QGVAR(selfAid), "CHECKBOX",
    ["Self aid", "Your own bleeding, pain, consciousness and tourniquets on the device panel."],
    [JMFSB_CATEGORY, "Watch HUD"], false, 0
] call CBA_fnc_addSetting;
