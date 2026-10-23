#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// Which thread the docked reader is showing, "" for the list. Client state,
// not the engine's - the reader is a view onto the index, not a second store.
GVAR(readerThread) = "";
GVAR(readerLog) = false;

// Which net tab the reader is on. "ALL" is every mailbox the player can see.
GVAR(readerNet) = "ALL";

// Which section of the settings app is open. It survives the app being closed
// and reopened, because reopening it is how it changes section.
GVAR(settingsSection) = "scheme";

// SECTIONS ANOTHER ADDON ADDS TO THE SETTINGS APP, in rail order after this
// addon's own: [key, rail label, code answering the rows]. The rows are the
// ones FUNC(appSettings) draws - [label, value, action, down action, locked,
// glyphs]. jmfsb_devices adds DEVICES and DEVICE KEYS in its own preInit.
GVAR(settingsSections) = [];

// The ACE report the squad app has selected but not sent yet, as three indices
// into GREEN / YELLOW / RED / BLACK. It survives the app closing, because
// changing one of the three reopens the app.
GVAR(aceDraft) = [0, 0, 0];

// The man picked out in the squad table. Selection is what the MESSAGE button
// addresses and what the accent edge marks.
GVAR(squadSelected) = objNull;

// Which squads the platoon view has open, groupId to bool. A squad not in here
// answers its default - the leader's own open, the rest folded - so the map is
// only ever what somebody actually toggled.
GVAR(platoonOpen) = createHashMap;

// THE TIMER, as three numbers and nothing else. Seconds banked while it was
// stopped, the mission time it was last started at (-1 for stopped), and the
// mark it counts down to (0 for a stopwatch). Held here rather than in a running
// handler so the clock is right whether or not anything has been ticking - see
// FUNC(timerState).
GVAR(timerAccum) = 0;
GVAR(timerSince) = -1;
GVAR(timerTarget) = 0;

// THE TWO VALUES THE ALARM PAGE HOLDS BETWEEN OPENINGS. A custom delay in
// seconds, and a time of day in seconds past midnight. Kept here rather than in
// the app because setting forty-seven minutes and losing it to a map close is
// how a player decides a screen is not worth using.
GVAR(alarmCustom) = 900;
GVAR(alarmAt) = 4 * 3600 + 30 * 60;

// Bumped by every change, so a ring armed for a countdown that has since been
// stopped, reset or moved knows it is stale when it fires.
GVAR(timerToken) = 0;

// TILES OTHER ADDONS ADD to the band (FUNC(tileData)): id -> code answering
// a list of tile entries, [] when it has none to show. jmfsb_devices' VEHICLE
// tile, which exists only on the vehicle tablet, comes in this way.
GVAR(tileProviders) = createHashMap;
// Provider tile ids the role gate lets through: tiles their own device gates
// already (the VEHICLE tile is the vehicle tablet's alone), so a mission's
// role tiles[] - written before the id existed - cannot hide them.
GVAR(tileUngated) = [];

// Registered in preInit so the shell knows the whole suite before a map can be
// opened. Whether any of them is actually drawn is the player's setting, read
// by the shell at build time - registering is not the same as showing.
//
// Order here is the order they claim their idc blocks, and the order the shell
// builds them in.
["tiles", "LIVE TILES", DEFAULT_TILES, FUNC(panelTiles), FUNC(panelTiles), 2] call EFUNC(tacpad,register);
["squad", "SQUAD", DEFAULT_SQUAD, FUNC(panelSquad), FUNC(panelSquad), 2] call EFUNC(tacpad,register);
["reader", "TAC//MSG - READER", DEFAULT_READER, FUNC(panelReader), FUNC(panelReader), 3] call EFUNC(tacpad,register);
// MAP TOOLS ANSWERS TO ITS OWN SWITCH. Three rows of four buttons is a lot of
// map to give up, so the TOOLS button in the strip under the reader turns the
// bar off without touching the rest of the suite - see FUNC(panelToolsBtn).
// Shown by default, so a mission that never presses it is unchanged.
// The tools are jmfsb_maptools' and this is their front end. Not a required
// addon: a build without it has no strip, rather than a strip of dead buttons.
["tools", "MAP TOOLS", DEFAULT_TOOLS, FUNC(panelTools), {}, 2, true, {
    !isNil QEFUNC(maptools,start) && {missionNamespace getVariable [QGVAR(toolsShown), true]}
}] call EFUNC(tacpad,register);
// THE TWO STRIPS ARE BUTTONS, NOT PANELS - registered chromeless, so no title
// bar, no rule and no title. A header reading SETTINGS over a cell reading
// SETTINGS is the same word twice, and on a control this short the bar was half
// its height. The empty title is what a chromeless panel gets asked for.
//
// jmfsb_adminpanel registers a third between them when it is loaded.
["toolsbtn", "", DEFAULT_TOOLSBTN, FUNC(panelToolsBtn), {}, 2, false] call EFUNC(tacpad,register);
["settings", "", DEFAULT_SETTINGS, FUNC(panelSettings), {}, 2, false] call EFUNC(tacpad,register);
["hide", "", DEFAULT_HIDE, FUNC(panelHide), {}, 2, false] call EFUNC(tacpad,register);

// Under the strips, chromeless like them, and refreshed on a two-second tick so
// the hold after a press counts itself down rather than sitting there looking
// broken.
["tic", "", DEFAULT_TIC, FUNC(panelTic), FUNC(panelTic), 2, false] call EFUNC(tacpad,register);

// SHOW ALL is the only thing the master hide switch leaves behind, so it is the
// only pinned panel. The settings strip used to be pinned for it, which meant
// hiding the suite left a gear on the map with nothing to configure.
EGVAR(tacpad,pinned) pushBackUnique "hide";

// TAC//INTEL's open folder and open file, per client. Which drawer somebody has
// pulled out is theirs and nobody else's - the files themselves are the unit's.
GVAR(intelFolder) = "";
GVAR(intelEntry) = "";

ADDON = true;
