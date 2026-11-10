// The C2 measures' world drawing for this player (design hud_settings_page).
// LOAs and no-fire areas are locked on (design locked_by_default) and draw
// whatever this says.
[
    QGVAR(hud), "CHECKBOX",
    ["HUD: C2 measures", "Draw phase lines, boundaries, routes, objectives and points in the world (AiTR goggles). LOAs and no-fire areas always draw."],
    [JMFSB_CATEGORY, "Watch HUD"], true, 0
] call CBA_fnc_addSetting;
