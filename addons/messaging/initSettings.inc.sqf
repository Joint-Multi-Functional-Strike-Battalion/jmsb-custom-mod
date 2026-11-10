// CBA Settings [ADDON: jmfsb_messaging]
// Everything here is server-forced: what a mailbox is called and whether a
// report reaches ALiVE are mission decisions, not client preferences.

[
    QGVAR(enabled), "CHECKBOX",
    ["Enable messaging", "Off refuses every submission and leaves the store empty. Nothing else in the mod depends on it being on."],
    ["JMSB - Tablet & Map", "Messaging"],
    true,
    true
] call CBA_fnc_addSetting;

// THE DEFAULT NETS ARE threads.json's DECLARED CHANNELS, all nine, ids
// verbatim - the dotted names carry the spec's one level of nesting in the
// name itself. Everyone can read every net (the user's access rule);
// subscriptions are how a man hides the ones he does not need. The role
// gates and archive retention the spec attaches to them are deliberately not
// implemented - user-ruled 2026-08-13.
[
    QGVAR(namedBoxes), "EDITBOX",
    ["Shared mailboxes", "Comma-separated names of mailboxes anybody can address. A thread sent to one is filed there rather than mailed to a person. Empty means personal and group boxes only."],
    ["JMSB - Tablet & Map", "Messaging"],
    "C2, C2.reports, FIRES, FIRES.cas, FIRES.arty, FIRES.trans, MEDICAL, MEDICAL.mist, MEDICAL.medevac",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(commandGroup), "EDITBOX",
    ["Command group", "Group name, as shown on its roster row, that a report reaches when its ROUTING line is ticked. Empty disables the tick."],
    ["JMSB - Tablet & Map", "Messaging"],
    "",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(idleClose), "SLIDER",
    ["Idle close (min)", "A thread nobody has touched for this long closes itself. 0 never closes one."],
    ["JMSB - Tablet & Map", "Messaging"],
    [0, 240, 60, 0, true],
    true
] call CBA_fnc_addSetting;

// THE SPECTRUM'S OPINION OF THE DATA LINK. The radios are already jammed by
// jmfsb_jamming; this is the same field applied to the tablet, at the same
// thresholds the EW scanner reads out - see FUNC(linkState).
[
    QGVAR(ewLink), "CHECKBOX",
    ["EW link state", "Jamming affects the data link: inside a jammer's falloff a send transmits late, inside its core it is refused outright. Receiving is never blocked. The bands are the EW scanner's own, so the handset and the reader agree. Off: messaging ignores jamming entirely."],
    ["JMSB - Tablet & Map", "Messaging"],
    true,
    true
] call CBA_fnc_addSetting;

// TROOPS IN CONTACT. Carried over from the cTab template of the same name: it
// was never really a message, it was an alarm that happened to be typed into a
// message form, and it is the one report that reaches people who were not
// addressed.
[
    QGVAR(ticBroadcast), "CHECKBOX",
    ["TIC alerts the side", "A CONTACT REPORT (TIC) reaches every player on the sender's side and raises the shared alert bus, on top of whoever it was addressed to."],
    ["JMSB - Tablet & Map", "Messaging"],
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(ticMarker), "CHECKBOX",
    ["TIC drops a map marker", "Marks the contact grid for the sender's side."],
    ["JMSB - Tablet & Map", "Messaging"],
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(ticMarkerType), "EDITBOX",
    ["TIC marker type", "CfgMarkers class for the marker a TIC drops. loc_Attack is the crossed-swords task icon - a contact is an event, not a unit symbol, and o_inf put a red infantry counter on the map for something nobody had identified yet."],
    ["JMSB - Tablet & Map", "Messaging"],
    "loc_Attack",
    true
] call CBA_fnc_addSetting;

[
    QGVAR(ticMarkerColor), "EDITBOX",
    ["TIC marker colour", "CfgMarkerColors class for the marker a TIC drops."],
    ["JMSB - Tablet & Map", "Messaging"],
    "ColorRed",
    true
] call CBA_fnc_addSetting;

// ALiVE forwarding. The messaging addon never names an ALiVE symbol - it asks
// the adapter, which is the only addon allowed to know ALiVE exists.
[
    QGVAR(aliveReports), "CHECKBOX",
    ["Post reports to ALiVE", "A template marked reportable - CONTACTREP and SITREP - is also filed with ALiVE's C2ISTAR as a spotrep or sitrep, with a companion map marker. Needs ALiVE - without it nothing is posted, said once in the server RPT."],
    ["JMSB - Tablet & Map", "Messaging"],
    true,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(aliveLocality), "LIST",
    ["ALiVE report locality", "Who an ALiVE-posted report and its marker are visible to."],
    ["JMSB - Tablet & Map", "Messaging"],
    [["GLOBAL", "SIDE", "GROUP"], ["Everyone", "Sender's side", "Sender's group"], 1],
    true
] call CBA_fnc_addSetting;

[
    QGVAR(sitrepMarkerType), "EDITBOX",
    ["SITREP marker type", "CfgMarkers class for the marker that accompanies an ALiVE-posted SITREP."],
    ["JMSB - Tablet & Map", "Messaging"],
    "b_inf",
    true
] call CBA_fnc_addSetting;

// TEST TRAFFIC. Off by default and client-side: an empty reader looks the same
// whether the engine works or the client never asked, so there has to be a way
// to put three known threads in it without writing them by hand every time.
[
    QGVAR(seedTest), "CHECKBOX",
    ["Seed test traffic", "Posts three sample threads - a FLASH CASEVAC, a SITREP and a CONTACTREP - shortly after you join, so the reader has something in it. For testing the UI; leave off on an operation."],
    ["JMSB - Tablet & Map", "Messaging"],
    false,
    false
] call CBA_fnc_addSetting;
