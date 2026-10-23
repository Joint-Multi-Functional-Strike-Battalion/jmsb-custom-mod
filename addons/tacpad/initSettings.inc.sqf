// CBA Settings [ADDON: jmfsb_tacpad]
// The shell's own settings: whether it draws at all, what it is painted with,
// and whether panels can be moved. Which panels exist is the apps addon's
// business, so those settings live there.
//
// All per-client. Where a player puts their squad list and what colour they
// like it is not a server decision.

[
    QGVAR(enabled), "CHECKBOX",
    ["Enable tacpad", "Draws the tacpad panels on the map screen. Off leaves the vanilla map exactly as it was."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;

// WHERE THE SUITE DRAWS. Native is the map screen, as it always has been.
// Tablet takes every panel off the map and puts the same screens inside a
// device that jmfsb_devices draws - the vanilla map becomes a plain map.
// Owned here rather than by the devices addon because this is the addon that
// has to read it before anything is built; see shared.inc.hpp on the host.
[
    QGVAR(displayMode), "LIST",
    ["Display mode", "NATIVE draws the tacpad on the map screen as it always has. TABLET takes it off the map and puts the same screens inside a device - open it from the ACE self-interaction menu under Equipment, or its key. The vanilla map stays a plain map."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    [["native", "tablet"], ["Native", "Tablet"], 1],
    false,
    {[QGVAR(displayMode_changed), []] call CBA_fnc_localEvent}
] call CBA_fnc_addSetting;

[
    QGVAR(scheme), "LIST",
    [
        "Colour scheme",
        "Four day grounds and four night ones, in matching pairs: JMSB DAY with JMSB NIGHT (the unit's ranger green and tan; night is the default), FIELD GREY with NIGHT / RED, OLIVE with NIGHT OLIVE, SAND with NIGHT SAND. A night scheme is a dark ground with the day scheme's own accent held down to what does not blow your eyes out at 0200. CUSTOM uses the three colours below. Also switchable in-game from the gear under the message reader."
    ],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    [
        ["jmsb", "light", "olive", "sand", "nightJmsb", "dark", "nightOlive", "nightSand", "custom"],
        ["JMSB Day", "Field Grey", "Olive", "Sand", "JMSB Night", "Night / Red", "Night Olive", "Night Sand", "Custom"],
        4
    ],
    false,
    {[QGVAR(scheme_changed), []] call CBA_fnc_localEvent}
] call CBA_fnc_addSetting;

[
    QGVAR(opacity), "SLIDER",
    ["Panel opacity", "How solid a panel's ground is over the map. The text stays fully opaque at any setting - a translucent panel you cannot read is not a panel."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    [0.3, 1, 0.92, 2, true],
    false,
    {[QGVAR(opacity_changed), []] call CBA_fnc_localEvent}
] call CBA_fnc_addSetting;

[
    QGVAR(respectZones), "CHECKBOX",
    ["Keep clear of reserved areas", "Slides a panel out of the game menu, the chat overlay and the map's scale and contour legend when you drop it on one. Off lets you put a panel anywhere, including on top of your own chat."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    true,
    false
] call CBA_fnc_addSetting;

// Custom scheme. Three "r,g,b" values, 0-1 each. Empty is not an error - the
// scheme falls back to the Arma answer for anything it cannot read, so a
// half-filled custom scheme is still a usable one.
[
    QGVAR(customGround), "EDITBOX",
    ["Custom: ground", "Panel background as r,g,b from 0 to 1, e.g. 0.05,0.06,0.05. Used only by the Custom scheme."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    "",
    false,
    {[QGVAR(scheme_changed), []] call CBA_fnc_localEvent}
] call CBA_fnc_addSetting;

[
    QGVAR(customInk), "EDITBOX",
    ["Custom: text", "Text and divider colour as r,g,b from 0 to 1. Used only by the Custom scheme."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    "",
    false,
    {[QGVAR(scheme_changed), []] call CBA_fnc_localEvent}
] call CBA_fnc_addSetting;

[
    QGVAR(customAccent), "EDITBOX",
    ["Custom: accent", "Selection, alerts and FLASH traffic as r,g,b from 0 to 1. Used only by the Custom scheme."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    "",
    false,
    {[QGVAR(scheme_changed), []] call CBA_fnc_localEvent}
] call CBA_fnc_addSetting;

// THE QUICK REPLY ROW. Six phrases under an open thread, and which six is a unit
// decision rather than one this mod gets to make - a section that answers
// "SMOKE OUT" wants that button, and one that never does wants it gone.
//
// An entry that names a reply template - roger, wilco, inprogress, cantco,
// close - sends that template, so the thread's state still moves. Anything else
// is sent as those words, as free text. Either way the button is only drawn when
// the engine would accept it in the thread being read.
[
    QGVAR(quickReplies), "EDITBOX",
    ["Quick replies", "The buttons under an open thread, separated by commas. A template id (roger, wilco, inprogress, cantco, close) sends that reply; anything else is sent as the words themselves. Five per row."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    ["roger, wilco, WAIT ONE, SMOKE OUT, LZ SECURE, NEGATIVE"],
    false
] call CBA_fnc_addSetting;

// UI SIZE. One multiplier over the whole suite - every row, every header, every
// type size and the panels themselves - so a player can take the whole thing
// down a notch.
//
// SEPARATE FROM TEXT SIZE ON PURPOSE. Text size is a legibility choice: bigger
// type, taller rows, fewer of them. This is a scale: the same layout, smaller or
// larger. A player who wants big text on a small suite can have both.
[
    QGVAR(uiScale), "SLIDER",
    ["UI size", "Scales the whole tacpad - panels, rows and type together. The in-game settings screen steps it by 1, 5 or 10 percent; this is the same number."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    [0.5, 2, 1, 2, true],
    false,
    {[QGVAR(uiScale_changed), []] call CBA_fnc_localEvent}
] call CBA_fnc_addSetting;

// Text size. The one lever worth having: what is readable on a 1080p monitor at
// arm's length and what is readable on a 4K one are not the same number, and
// the rows grow with the type rather than clipping it - a bigger setting means
// taller rows, not cramped ones.
[
    QGVAR(textScale), "SLIDER",
    ["Text size", "Scales all tacpad text. Rows and headers grow with it, so a larger setting means fewer rows visible rather than text spilling out of them."],
    ["1st Joint Multi-Functional Strike Battalion", "Tacpad"],
    [0.6, 2.5, 1.2, 2, true],
    false,
    {[QGVAR(scheme_changed), []] call CBA_fnc_localEvent}
] call CBA_fnc_addSetting;
