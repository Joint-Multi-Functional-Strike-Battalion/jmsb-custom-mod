// CBA Settings [ADDON: jmfsb_notify]
// Client-side display preferences only - anything mission-specific belongs on
// the module that raises the notification, not here.

[
    QGVAR(enabled), "CHECKBOX",
    ["Enable stacked notifications", "Off falls back to the plain hint the caller would otherwise have used."],
    ["1st Joint Multi-Functional Strike Battalion", "Notifications"],
    true,
    false   // per-client
] call CBA_fnc_addSetting;

// HIDDEN IS NOT DISABLED. Enabled-off still speaks, as a plain hint; this one
// says nothing on screen at all. The reader's LOG view keeps the record either
// way, so a player who hides the popups can still page back through them.
[
    QGVAR(hidden), "CHECKBOX",
    ["Hide notifications", "Shows no popup and no hint. Notifications are still kept in the tacpad reader's LOG view."],
    ["1st Joint Multi-Functional Strike Battalion", "Notifications"],
    false,
    false
] call CBA_fnc_addSetting;

[
    QGVAR(corner), "LIST",
    ["Corner", "Which corner the stack grows from."],
    ["1st Joint Multi-Functional Strike Battalion", "Notifications"],
    [[0, 1, 2, 3], ["Top left", "Top right", "Bottom left", "Bottom right"], 1],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(maxVisible), "SLIDER",
    ["Max on screen", "Notifications shown at once; the rest queue until a slot frees."],
    ["1st Joint Multi-Functional Strike Battalion", "Notifications"],
    [1, SLOT_COUNT, 4, 0, true],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(duration), "SLIDER",
    ["Duration (sec)", "How long a notification stays before it fades out."],
    ["1st Joint Multi-Functional Strike Battalion", "Notifications"],
    [2, 30, 8, 0, true],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(width), "SLIDER",
    ["Width", "Width of the stack as a fraction of the safe zone."],
    ["1st Joint Multi-Functional Strike Battalion", "Notifications"],
    [0.1, 0.5, 0.22, 2, true],
    false
] call CBA_fnc_addSetting;

// The row grows with the type rather than clipping it, so this scales the whole
// notification, not just the letters inside a fixed box.
[
    QGVAR(fontSize), "SLIDER",
    ["Text size", "Scales the notification text. The panel grows with it, so a larger size means taller notifications rather than cramped ones."],
    ["1st Joint Multi-Functional Strike Battalion", "Notifications"],
    [0.5, 3, 1, 2, true],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(font), "LIST",
    ["Font", "Typeface for notifications. The monospace and console faces suit a technical readout; the Purista faces are what Arma's own UI uses."],
    ["1st Joint Multi-Functional Strike Battalion", "Notifications"],
    [
        ["RobotoCondensed", "RobotoCondensedBold", "PuristaMedium", "PuristaBold", "EtelkaNarrowMediumPro", "EtelkaMonospacePro", "LucidaConsoleB", "TahomaB"],
        ["Roboto Condensed", "Roboto Condensed Bold", "Purista Medium", "Purista Bold", "Etelka Narrow", "Etelka Monospace", "Lucida Console", "Tahoma Bold"],
        0
    ],
    false
] call CBA_fnc_addSetting;
