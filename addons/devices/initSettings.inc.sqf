// CBA Settings [ADDON: jmfsb_devices]
//
// Which host the suite draws on - map or device - is the shell's setting
// (jmfsb_tacpad_displayMode), because the shell has to read it before anything
// is built. What is here is how the device is drawn once it is the host.

// HOW MUCH OF THE MONITOR THE TABLET TAKES. 1 is as large as the screen allows
// - the device body touching the top and bottom of a 16:9 monitor. Smaller
// leaves the world visible round it, for anyone who reads it as a window.
// THE FOUR SOFT KEYS printed on the tablet frame go straight to an app - which
// app is the player's to say, here or on the tablet (SETTINGS > DEVICE KEYS).
// The choices are SOFT_KEY_IDS / SOFT_KEY_NAMES in script_component.hpp, so
// the tablet's settings page offers the same list.
//
// Four declarations rather than a loop: the plumbing check reads QGVAR(name)
// off this file to prove every setting has a reader, and a name built with
// format is invisible to it. The same goes for the six walking-view buttons
// at the foot of this file.
#define SOFT_KEY_HELP "Which app this key, printed on the tablet frame, opens when you click it or press its device key (numpad 1-4 by default, Device button F1-F4 in Configure Addons). Pressing it again closes the app. The keyboard F1-F4 keys are not used."

[
    QGVAR(keyF1), "LIST",
    ["F1 key on the tablet opens", SOFT_KEY_HELP],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [SOFT_KEY_IDS, SOFT_KEY_NAMES, 1],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(keyF2), "LIST",
    ["F2 key on the tablet opens", SOFT_KEY_HELP],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [SOFT_KEY_IDS, SOFT_KEY_NAMES, 2],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(keyF3), "LIST",
    ["F3 key on the tablet opens", SOFT_KEY_HELP],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [SOFT_KEY_IDS, SOFT_KEY_NAMES, 3],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(keyF4), "LIST",
    ["F4 key on the tablet opens", SOFT_KEY_HELP],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [SOFT_KEY_IDS, SOFT_KEY_NAMES, 12],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(tabletFill), "SLIDER",
    ["Tablet size", "How much of the monitor the tablet fills when it is open. 1 is as large as the screen allows; smaller leaves the world visible around it."],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [0.5, 1, 1, 2, true],
    false,
    {[QGVAR(tabletFill_changed), []] call CBA_fnc_localEvent}
] call CBA_fnc_addSetting;

// HOW TALL A SIDE DEVICE IS, as a fraction of the monitor's height. The phone
// is fixed at a fifth by the design; a side device sits against the edge of
// the screen the player chose and can be as tall as they like it. Read by
// FUNC(overlayLayout) on every placement, so a change lands on the next tick.
// THE PHONE'S SIZE. A fifth of the screen was the spec's number and read as a
// postage stamp on a 1440p monitor (user screenshot, 2026-10-19: "make the
// phone a bit wider, do not stretch") - so it is a slider, default three
// tenths, and the frame keeps its aspect whatever the number.
[
    QGVAR(phoneFill), "SLIDER",
    ["Phone size", "How tall the phone's walking view is, as a fraction of the screen's height. The frame keeps its shape; this only scales it."],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [0.15, 0.5, 0.3, 2, true],
    false
] call CBA_fnc_addSetting;

// HOW CLOSE THE PHONE'S MAP IS. Map scale: smaller is closer. The default
// shows a few hundred metres round the man - his own icon and his squad's,
// not the province.
[
    QGVAR(phoneZoom), "SLIDER",
    ["Phone map zoom", "How far the phone and side devices' map is zoomed in. Smaller is closer. The map always stays centred on you."],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [0.005, 0.1, 0.015, 3, false],
    false
] call CBA_fnc_addSetting;

// THE SIDE DEVICE'S SIZE. Default 0.42, a fifth up on the first 0.35 (user,
// 2026-10-21: "the side devices default needs to be 20% larger").
[
    QGVAR(sideFill), "SLIDER",
    ["Side device size", "How tall a side device is, as a fraction of the screen's height."],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [0.2, 0.8, 0.42, 2, true],
    false
] call CBA_fnc_addSetting;

// HOW SOLID THE WALKING VIEW IS (docs/DESIGN_PHONE_WALKING.md: "Opacity
// setting 0.4 - 1"). Phone and side devices alike, frame and screen together.
// Read by FUNC(overlayPlace); a change lands on the next tick.
[
    QGVAR(overlayOpacity), "SLIDER",
    ["Device opacity", "How solid the phone or side device is on screen while walking. 1 is fully opaque."],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [0.4, 1, 1, 2, true],
    false
] call CBA_fnc_addSetting;

// THE WALKING VIEW'S SIX FRAME BUTTONS (BUTTON_IDS in script_component.hpp):
// what each does when its keybind - "Device button F1" and on, numpad 1-4, 0
// and . by default - is pressed while the phone or side device is up. The
// defaults are the voice keys of docs/DESIGN_VOICE.md: F1 accept a call, F2
// ear / quick add, F3 mute the active net, F4 decline / hang up, the arrows
// the active net left / right. Each stays the player's to change, here or on
// the tablet, SETTINGS > DEVICE KEYS. While the RADIO app is open on the
// device they are its soft keys and cursor whatever they are set to.
#define BUTTON_HELP "What this button printed on the phone and side device frames does on the walking view. Press it with its keybind (Configure Addons, Device button ...; numpad 1-4, 0 and . by default). While the RADIO app is open on the device the buttons are its soft keys and cursor instead."

[
    QGVAR(buttonF1), "LIST",
    ["Device button F1", BUTTON_HELP],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [BUTTON_IDS, BUTTON_NAMES, 1],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(buttonF2), "LIST",
    ["Device button F2", BUTTON_HELP],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [BUTTON_IDS, BUTTON_NAMES, 2],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(buttonF3), "LIST",
    ["Device button F3", BUTTON_HELP],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [BUTTON_IDS, BUTTON_NAMES, 3],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(buttonF4), "LIST",
    ["Device button F4", BUTTON_HELP],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [BUTTON_IDS, BUTTON_NAMES, 4],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(buttonLeft), "LIST",
    ["Device button left", BUTTON_HELP],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [BUTTON_IDS, BUTTON_NAMES, 5],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(buttonRight), "LIST",
    ["Device button right", BUTTON_HELP],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [BUTTON_IDS, BUTTON_NAMES, 6],
    false
] call CBA_fnc_addSetting;

// THE TABLET'S FRAME (FUNC(open)): Auto gives the UAV tablet to a player with
// the UAV skill and the large one to everyone else; Large or UAV forces one.
// Changed with the tablet open, it reopens in the new frame (FUNC(tabletReframe)).
[
    QGVAR(tabletFrame), "LIST",
    ["Tablet frame", "Which frame the tablet wears: Auto (the UAV tablet with grips for the UAV skill, the large tablet otherwise), or always the large or always the UAV tablet. The screen is the same size in both."],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [TABLET_FRAME_IDS, TABLET_FRAME_NAMES, 0],
    false,
    {[] call FUNC(tabletReframe)}
] call CBA_fnc_addSetting;

// THE GRID READOUT on the phone and side devices (FUNC(overlayGrid)): an 8 or
// 10 figure grid, the player's own choice (user, 2026-10-21: "8 or 10 player
// choice") - 8 by default.
[
    QGVAR(gridDigits), "LIST",
    ["Device grid digits", "How many figures the GPS grid on the phone, side devices and tablet bar shows: 8 (10 m square, the default) or 10 (1 m)."],
    ["1st Joint Multi-Functional Strike Battalion", "Devices"],
    [GRID_DIGIT_CHOICES, GRID_DIGIT_NAMES, 0],
    false
] call CBA_fnc_addSetting;
