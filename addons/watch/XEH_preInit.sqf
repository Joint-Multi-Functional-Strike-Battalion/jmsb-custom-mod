#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// The profiles (FUNC(register)), each player's slots per profile -
// [target, pinned, lost since] - and the profile the panel shows.
GVAR(profiles) = createHashMap;
GVAR(slots) = createHashMap;
GVAR(current) = "";

// The shared contacts: the server's entries (hashValue -> entry), the list it
// publishes to every client, this machine's map tracks, and the threats this
// engineer has already reported.
GVAR(contacts) = createHashMap;
GVAR(contactList) = [];
GVAR(markers) = [];
GVAR(threatsSent) = [];
// Context actions other addons give the action key when nothing is looked at
// (FUNC(actionKey)) - C2's report.
GVAR(fallbacks) = createHashMap;
// The squad view is up until this mission time (FUNC(squadView)).
GVAR(squadUntil) = -1;
// The world panels' controls on the mission display - [backdrop, text,
// trace strips] each - and how many were shown last frame (FUNC(hudDraw)).
GVAR(hudPool) = [];
GVAR(hudShown) = 0;
// The slot the device's F-keys act on, per profile (FUNC(selected)).
GVAR(selected) = createHashMap;

// THE WATCH SECTION OF THE TABLET'S SETTINGS APP (FUNC(settingsRows)); the
// slot rows it last drew, by key, for their buttons.
GVAR(settingsSlots) = createHashMap;
if (!isNil QEGVAR(tacpad_apps,settingsSections)) then {
    EGVAR(tacpad_apps,settingsSections) pushBack ["watch", "WATCH HUD", {[] call FUNC(settingsRows)}];
};

// THE WATCH PANEL ON THE TABLETS - the vehicle tablet's included - while a
// profile is on (the condition is asked each time the map opens).
if (!isNil QEFUNC(tacpad,register)) then {
    ["watch", "WATCH", PANEL_PLACE, FUNC(panel), FUNC(panel), TICK_SECONDS, true, {[] call FUNC(current) isNotEqualTo ""}] call EFUNC(tacpad,register);
};

ADDON = true;
