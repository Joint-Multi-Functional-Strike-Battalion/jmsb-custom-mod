// CBA Settings [ADDON: jmfsb_adminpanel]
//
// DELIBERATELY ALMOST EMPTY. The console is drawn from the tacpad's settings -
// scheme, opacity, UI size - because a suite with two colour pickers has two
// colour pickers to keep in step. What is here is the one thing the tacpad has
// no opinion about: whether this addon is switched on at all.

[
    QGVAR(enabled), "CHECKBOX",
    ["Enable admin console", "Registers the admin console keybinds and the #jmfsb admin commands. Off leaves the addon loaded and inert - it does not grant or revoke anybody's admin access either way."],
    ["JMSB - Mission & Admin", "Admin Console"],
    true,
    true
] call CBA_fnc_addSetting;

// WHO CAN OPEN IT, beyond the mission's own list. JMSB's admin flag is what
// #login and the server host set, and honouring it means a host who is already
// an admin does not have to edit a mission file to use the console on it.
// A TESTING SWITCH, OFF BY DEFAULT (user, 2026-09-05: "set the default to
// off"). On, every player passes the admin check - console, TAC//PAC page,
// and every server-side door that re-checks the caller - for a quick look at
// the pages without setting an admin list up. Off (the default), admin is
// the real thing: the TAC//PAC admins list, the mission's list, and jmfsb's
// admin flag. Turn it on for testing, never for an op.
[
    QGVAR(everyoneAdmin), "CHECKBOX",
    ["Everyone is an admin (testing)", "Every player passes the admin check - the console, the TAC//PAC page and the server-side edits behind them. A testing switch, OFF by default (user, 2026-09-05): turn it on for a look, off for an op. The server reads it once when the mission loads; a change needs a restart. Off, admin is the server's own list - the mod's list, TAC//PAC's admins, grants made in the console - and #login."],
    ["JMSB - Mission & Admin", "Admin Console"],
    false,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(honourJmfsbAdmin), "CHECKBOX",
    ["JMSB admins may open it", "Lets anyone the server flags as an admin (#login, the host, TAC//PAC's admins) open the console, as well as the uids in the console's own list. Off means that list is the only way in. Only the console's screen: every action behind it is checked again by the server."],
    ["JMSB - Mission & Admin", "Admin Console"],
    true,
    true
] call CBA_fnc_addSetting;
