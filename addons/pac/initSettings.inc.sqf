// CBA Settings [ADDON: jmfsb_pac] - page "JMSB - Mission & Admin", "TAC//PAC Service" (was its own page from 2026-09-05; the
// options were split into seven JMSB pages on 2026-10-24: "the big single page is hard to tell folks where to find things")
//
// THE ONE EXCEPTION to "TAC//PAC has no CBA settings" (user, 2026-09-05:
// "that needs to be in cba, a lot of hosted servers do not give the right to
// create files", "this will run on a hosted server"): where the database is.
// A rented game server lets an admin set a server setting - in game from
// Addon Options while logged in, or in the server's cba_settings.sqf - and
// can run nothing beside Arma. So the ghostd_pacdb extension carries the
// MongoDB driver itself: the setting takes the Atlas connection string and
// the server talks to the database directly, nothing else running anywhere.
// (An http:// address instead means the pacdb service, for a unit that runs
// one; the key is only for that.) The server hands the value to the
// extension at boot (FUNC(svcConfigure)); left empty, the extension falls
// back to GHOSTD_PACDB_URL / GHOSTD_PACDB_KEY in the server's environment,
// then pacdb.json in its root.
//
// KNOW WHAT A CBA SETTING IS: server settings are sent to every client, so
// the connection string here is on every player's machine. Make it worthless
// off the server: an Atlas database user with rights on this one database
// only (readWrite on jmfsbd), and Atlas Network Access allowing the game
// server's IP alone - tools/pacdb/README.md.

[
    QGVAR(serviceUrl), "EDITBOX",
    ["Database", "The MongoDB connection string - mongodb+srv://user:password@cluster.../ from Atlas (Database > Connect > Drivers) - the server talks to it directly, nothing else runs. Or http://host:8085 for a pacdb service. Used with sync = ""service"" in the mission's CfgGFA_PAC; read once, at mission start. Empty: the server's GHOSTD_PACDB_URL, or pacdb.json in its root. LEAVE IT EMPTY ON A LIVE SERVER: CBA copies every server setting to every player, password included - use GHOSTD_PACDB_URL."],
    ["JMSB - Mission & Admin", "TAC//PAC Service"],
    "",
    true,
    {},
    true
] call CBA_fnc_addSetting;

// TEST AS A STEAM ID IN THE EDITOR. getPlayerUID is "" in the editor and in
// singleplayer, so a tester's own record never matches a real Steam-id record
// (user, 2026-09-05). Put your 17-digit Steam id here and, in the editor, you
// ARE that operator - the database's record for you loads and your edits land
// on it. Empty (the default), and the editor uses a throwaway per-profile id.
// Ignored in a real multiplayer game, where getPlayerUID is your Steam id.
[
    QGVAR(testUid), "EDITBOX",
    ["Test as Steam id (editor only)", "Editor and singleplayer have no Steam id. Put yours here (17 digits) to test as your real operator - the database record for you loads. Empty = a throwaway test id. Does nothing in multiplayer."],
    ["JMSB - Mission & Admin", "TAC//PAC Service"],
    "",
    true
] call CBA_fnc_addSetting;

// WHERE THIS SERVER CALLS OUT FROM. An Atlas access-list entry is an IP, and a
// rented box does not tell you which one it leaves by - a container's own
// address is a private one and no use here (user, 2026-09-06). With this on,
// the boot asks an outside reflector and writes the answer to the .rpt, with a
// verdict on TLS beside it: the plain-HTTP leg still answers when TLS is the
// thing that is broken, so the pair says whether a failure is the network or
// the machine's certificate store.
//
// OFF BY DEFAULT, and deliberately so: it is a request to a third party, made
// from your server, and most boots have no use for one. Turning it on tells
// that service your server's address - which is the whole point of asking.
// DATABASE REQUIRED. A mission whose config lives in the database has no
// arsenal, no nets, no roles and no ranks without it. Booting anyway gives a
// server full of people with no gear and no radios, and an admin working out
// over twenty minutes that a connection string is wrong. On, the boot stops
// and says so; off (the default, and right for a mission that still ships a
// config folder) it carries on with the server's own config.
[
    QGVAR(svcRequired), "CHECKBOX",
    ["Database required", "For a mission that ships no config folder. If the database cannot be read at mission start, TAC//PAC stops and writes a PAC BOOT FAILED block to the .rpt instead of running unconfigured. Leave off for a mission that carries its own config\\ files - it will fall back to those."],
    ["JMSB - Mission & Admin", "TAC//PAC Service"],
    false,
    true
] call CBA_fnc_addSetting;

[
    QGVAR(serviceKey), "EDITBOX",
    ["Service key", "Only for an http:// pacdb service: the X-Api-Key it expects. Leave empty with a mongodb+srv:// connection string. Better empty always: every player receives this setting - use GHOSTD_PACDB_KEY on the server."],
    ["JMSB - Mission & Admin", "TAC//PAC Service"],
    "",
    true,
    {},
    true
] call CBA_fnc_addSetting;
