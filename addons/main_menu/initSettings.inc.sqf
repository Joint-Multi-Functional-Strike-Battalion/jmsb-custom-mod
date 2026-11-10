// CBA Settings [ADDON: jmfsb_main_menu]

// The three main menu quick connect buttons. 1 is the left button, 2 the
// centre, 3 the right - keyed on position because the name is a setting now and
// can say anything.
//
// An empty address or a port of 0 hides that button. An empty name leaves
// whatever the config called it. The colour is the button's background - the
// hover colour is Arma's own and is not set here.
//
// ALL CLIENT-SIDE, AND READ FROM THE PROFILE. preInit does not run until a
// mission starts, so on the main menu these variables do not exist yet.
// FUNC(cacheServers) mirrors them into profileNamespace, which does survive a
// restart, and XEH_mainDisplay reads that - so a change here reaches the menu on
// the next launch, not this one. XEH_preInit does that wiring on one
// CBA_SettingChanged handler; nothing in this file needs to know about it.
//
// The passwords are plain text in the profile. They were plain text in the PBO
// before; being editable without a rebuild is the gain, being secret was never
// on offer.

[
    QGVAR(server1Name), "EDITBOX",
    ["1 - Left button name", "What the left button says. Empty leaves whatever the config called it."],
    ["JMSB - Mission & Admin", "Main Menu"],
    "JMSB Training Server",
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server1Address), "EDITBOX",
    ["1 - Left button address", "Host or IP the left button connects to. Empty removes the button."],
    ["JMSB - Mission & Admin", "Main Menu"],
    "172.93.101.237",
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server1Port), "EDITBOX",
    ["1 - Left button port", "Port for the left button. 0 or empty removes the button."],
    ["JMSB - Mission & Admin", "Main Menu"],
    "2402",
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server1Password), "EDITBOX",
    ["1 - Left button password", "Sent with the connection. Empty for an open server. Stored in your profile in plain text."],
    ["JMSB - Mission & Admin", "Main Menu"],
    "aitd",
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server1Colour), "COLOR",
    ["1 - Left button colour", "Background of the left button. the unit's tan by default."],
    ["JMSB - Mission & Admin", "Main Menu"],
    [0.761, 0.659, 0.471, 1],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server2Name), "EDITBOX",
    ["2 - Centre button name", "What the centre button says. Empty leaves whatever the config called it."],
    ["JMSB - Mission & Admin", "Main Menu"],
    "JMSB Operations Server",
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server2Address), "EDITBOX",
    ["2 - Centre button address", "Host or IP the centre button connects to. Empty removes the button."],
    ["JMSB - Mission & Admin", "Main Menu"],
    "172.93.101.237",
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server2Port), "EDITBOX",
    ["2 - Centre button port", "Port for the centre button. 0 or empty removes the button."],
    ["JMSB - Mission & Admin", "Main Menu"],
    "2302",
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server2Password), "EDITBOX",
    ["2 - Centre button password", "Sent with the connection. Empty for an open server. Stored in your profile in plain text."],
    ["JMSB - Mission & Admin", "Main Menu"],
    "aitd",
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server2Colour), "COLOR",
    ["2 - Centre button colour", "Background of the centre button. the unit's tan by default."],
    ["JMSB - Mission & Admin", "Main Menu"],
    [0.761, 0.659, 0.471, 1],
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server3Name), "EDITBOX",
    ["3 - Right button name", "What the right button says. Empty leaves whatever the config called it."],
    ["JMSB - Mission & Admin", "Main Menu"],
    "JMSB Events Server",
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server3Address), "EDITBOX",
    ["3 - Right button address", "Host or IP the right button connects to. Empty removes the button."],
    ["JMSB - Mission & Admin", "Main Menu"],
    "172.93.101.237",
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server3Port), "EDITBOX",
    ["3 - Right button port", "Port for the right button. 0 or empty removes the button."],
    ["JMSB - Mission & Admin", "Main Menu"],
    "2502",
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server3Password), "EDITBOX",
    ["3 - Right button password", "Sent with the connection. Empty for an open server. Stored in your profile in plain text."],
    ["JMSB - Mission & Admin", "Main Menu"],
    "aitd",
    false
] call CBA_fnc_addSetting;

[
    QGVAR(server3Colour), "COLOR",
    ["3 - Right button colour", "Background of the right button. the unit's tan by default."],
    ["JMSB - Mission & Admin", "Main Menu"],
    [0.761, 0.659, 0.471, 1],
    false
] call CBA_fnc_addSetting;
