#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_boot

Description:
    The server's boot sequence, in order, narrated. Every step logs through
    FUNC(bootLog) so the whole thing can be read in the .rpt, on the
    dedicated console, or on screen in a hosted game:

        1/6  structure from the mission's config
        2/6  what was edited or imported in game, from the profile, over it
        3/6  structure from the service (sync = "service", through the
             ghostd_pacdb extension): adopted, or the mission's pushed up
             when the database has none; then the structure into effect
             (deck, slot table, radio plan, mailboxes) and orders cached
        4/6  store from the profile
        5/6  store from the service: adopted, or created on first save
        6/6  saved to the profile ONLY - the boot never writes the database
             it has just read (that is what wiped it); published; structure
             and settings sent to clients; ready

    THE PROFILE IS ALWAYS THE STORE; the service is on top of it. With
    sync = "off" steps 3 and 5 say so and the unit's database is an
    offline tool that reaches the game by clipboard (STRUCTURE IN / OUT).

    Spawned from XEH_postInit because the service steps wait. Everything
    that must not run before the data is there waits on jmfsb_pac_ready.

Parameters:
    None

Returns:
    Nothing

Author:
    YonV
---------------------------------------------------------------------------- */

if (!isServer) exitWith {};

// ONLY A MISSION THAT DECLARES TAC//PAC BOOTS IT. Without CfgGFA_PAC there is
// no unit here - the empty editor map the maker opens first, the main-menu
// scene, any mission that does not use PAC - and the store must not be touched
// nor the database reached (user, 2026-09-05: "the connection to the storage
// should only happen if the framework mission is being loaded"). The mod stays
// loaded and inert; READY is set so nothing waits on a boot that will not come.
if (!isClass (missionConfigFile >> "CfgGFA_PAC")) exitWith {
    GVAR(ready) = true;
    publicVariable QGVAR(ready);
    INFO("no CfgGFA_PAC in this mission - TAC//PAC is idle, no store, no database");
};

GVAR(bootLog) = [];
GVAR(bootT0) = diag_tickTime;         // FUNC(bootLog) stamps every .rpt line with the time since this
GVAR(bootDocs) = [];
GVAR(bootStep) = 0;
publicVariable QGVAR(bootDocs);
publicVariable QGVAR(bootStep);
private _service = (GVAR(settings) getOrDefault ["sync", "off"]) isEqualTo "service";
private _unit = GVAR(settings) getOrDefault ["unitId", ""];

private _fnc_counts = {
    format ["%1 rank(s), %2 skill(s), %3 award(s), %4 status(es), %5 role(s), %6 net(s), radio plan %7, %8 squad(s), %9 OPORD(s)",
        count (GVAR(structure) getOrDefault ["ranks", createHashMap]),
        count (GVAR(structure) getOrDefault ["skills", createHashMap]),
        count (GVAR(structure) getOrDefault ["awards", createHashMap]),
        count (GVAR(structure) getOrDefault ["statuses", createHashMap]),
        count (GVAR(structure) getOrDefault ["roles", createHashMap]),
        count (GVAR(structure) getOrDefault ["nets", createHashMap]),
        ["none", "yes"] select (count (GVAR(structure) getOrDefault ["radio", createHashMap]) > 0),
        count ((GVAR(structure) getOrDefault ["orbat", createHashMap]) getOrDefault ["groups", []]),
        count (GVAR(structure) getOrDefault ["opords", createHashMap])]
};

// ---- 1/6 structure, mission --------------------------------------------------
// The radio plan is read off the globals the mission's own preInit set - or
// did not: a mission whose plan lives in the database sets none.
[] call FUNC(radioFromMission);

// The mission's own contribution was recorded by FUNC(loadStructure), before
// this function merged anything over it - see GVAR(fromMission) there.
GVAR(structureHash) = [] call FUNC(structureHash);
["1/6", format ["structure from mission config: %1, hash %2, unit '%3'", call _fnc_counts, GVAR(structureHash), _unit]] call FUNC(bootLog);

// ---- 2/6 structure, profile --------------------------------------------------
// EDITS MADE IN GAME AND IMPORTS: the profile keeps every section that was
// edited (FUNC(structurePersist)) or imported whole (FUNC(structureImport)),
// and they go over the mission's config here. The database, when there is
// one, goes over both in 3/6.
private _edited = profileNamespace getVariable [PAC_KEY_STRUCTURE, createHashMap];
if (_edited isEqualType createHashMap && {count _edited > 0}) then {
    GVAR(structureEdited) = _edited;
    {
        // "_settings": the settings that came with an import; the rest of the
        // "_" keys are bookkeeping, not sections
        if (_x isEqualTo "_settings") then {
            if (_y isEqualType createHashMap) then {
                {
                    if !(_x in ["unitId", "serverId", "sync"]) then {GVAR(settings) set [_x, _y]};
                } forEach _y;
            };
            continue;
        };
        if ((_x select [0, 1]) isEqualTo "_") then {continue};
        // roles: the profile may hold only the roles edited in game, over the mission's
        if (_x isEqualTo "roles" && {_y isEqualType createHashMap}) then {
            private _roles = GVAR(structure) getOrDefault ["roles", createHashMap];
            {_roles set [_x, _y]} forEach _y;
            GVAR(structure) set ["roles", _roles];
        } else {
            GVAR(structure) set [_x, _y];
        };
    } forEach _edited;
    [] call FUNC(rolesFromMission);      // fields a stored role lacks come from its class, if the mission has one
    GVAR(structureHash) = [] call FUNC(structureHash);
    ["2/6", format ["in-game edits and imports from the profile applied over the mission's config: %1 - now %2, hash %3", keys _edited, call _fnc_counts, GVAR(structureHash)]] call FUNC(bootLog);
} else {
    ["2/6", "nothing edited or imported in game yet - the mission's config stands"] call FUNC(bootLog);
};

// ---- 3/6 structure, service --------------------------------------------------
GVAR(svcUp) = false;
if (_service) then {
    // WHERE THE SERVICE IS: the CBA server settings first (a hosted server can
    // take those), else what the extension finds in the server's environment
    // or pacdb.json. Settings are in by postInit; the wait is a guard.
    private _t0 = diag_tickTime;
    waitUntil {sleep 0.1; (missionNamespace getVariable ["CBA_settings_ready", false]) || {diag_tickTime - _t0 > 10}};
    private _from = [] call FUNC(svcConfigure);
    ["3/6", switch (_from) do {
        case "setting": {"database address: the CBA server setting 'Database' (Addon Options > 1st Joint Multi-Functional Strike Battalion PAC > Service), handed to the extension - a mongodb+srv:// string is Atlas directly, an http:// one the pacdb service"};
        case "environment": {"database address: no CBA setting - the extension uses GHOSTD_PACDB_URL / GHOSTD_PACDB_KEY from the server's environment, or pacdb.json in its root"};
        default {"database address: the CBA setting could NOT be handed to the extension - is ghostd_pacdb_x64.dll / .so loaded?"};
    }] call FUNC(bootLog);
    // THE ADDRESS THIS SERVER CALLS OUT FROM, when the admin asked for it -
    // what goes in an Atlas access-list entry, and a verdict on TLS beside it.
    // Off by default: a request to a third party is not something a boot should
    // make on its own. The answer comes back through the ExtensionCallback
    // handler (XEH_postInit) a moment later, as "network check: ...".
    if (missionNamespace getVariable [QGVAR(netCheck), false]) then {
        ["3/6", "network check on: asking what address this server calls out from, and whether TLS works here - the answer follows as a 'network check' line"] call FUNC(bootLog);
        "ghostd_pacdb" callExtension ["netcheck", []];
    };

    ["3/6", format ["service: reading the config, one document per file - '%1.settings' .ranks .skills .awards .statuses .admins .nets .radio .orbat .templates .schemes, every '%1.role.*' and every '%1.opord.*' (each up to %2 s)", _unit, PAC_SVC_TIMEOUT]] call FUNC(bootLog);
    ([] call FUNC(svcStructure)) params ["_doc", "_status"];
    // FUNC(bootDoc) publishes the checklist at most every PAC_BOOT_PUBLISH_EVERY
    // seconds; this is the last word on it, so no client is left on a stale tick.
    publicVariable QGVAR(bootDocs);
    publicVariable QGVAR(bootStep);
    switch (_status) do {
        case "ok": {
            if ([_doc] call FUNC(structureAdopt)) then {
                GVAR(svcUp) = true;
                ["3/6", format ["service: config ADOPTED - %1, hash %2 (the database wins over the mission's config and the profile)", call _fnc_counts, GVAR(structureHash)]] call FUNC(bootLog);
            } else {
                if (missionNamespace getVariable [QGVAR(svcRequired), false]) then {
                    ["the config documents came back in the wrong shape"] call FUNC(bootFail);
                } else {
                    ["3/6", "service: config documents are the wrong shape - REFUSED, keeping what this server has"] call FUNC(bootLog);
                };
            };
        };
        case "empty": {
            GVAR(svcUp) = true;
            private _sent = [] call FUNC(svcPushStructure);
            ["3/6", format ["service: no config documents yet - this server's config PUSHED UP as the first, %1 document(s)", _sent]] call FUNC(bootLog);
        };
        default {
            if (missionNamespace getVariable [QGVAR(svcRequired), false]) then {
                // SAY WHAT THE DATABASE SAID. "did not answer in time" covered a
                // refused password for a day (user, 2026-10-08: Atlas answered
                // "Unable to authenticate" and the block still blamed the clock).
                private _said = missionNamespace getVariable [QGVAR(svcLastError), ""];
                private _why = switch (true) do {
                    case (_said isEqualTo ""): {"the database did not answer in time"};
                    case ((toLower _said) find "authenticat" >= 0): {format ["the database REFUSED THE USER OR PASSWORD - check the connection string (%1)", _said]};
                    case ((toLower _said) find "invalid request uri" >= 0): {format ["the address is not a mongodb+srv:// string - quotes or a stray character in it? (%1)", _said]};
                    default {format ["the database answered with an error: %1", _said]};
                };
                [_why] call FUNC(bootFail);
            } else {
                ["3/6", "service: NOT ANSWERING - running on this server's config and the profile"] call FUNC(bootLog);
            };
        };
    };
} else {
    ["3/6", "service: off (sync is not 'service') - the database is an offline tool; STRUCTURE IN on the admin page brings its config in"] call FUNC(bootLog);
};

// THE STRUCTURE INTO EFFECT: deck, slot table, radio plan, mailboxes; and the
// orders it carries cached, so the app still shows an order the mission dropped.
[true] call FUNC(structureApply);
{
    private _copy = +_y;
    _copy set ["archivedAt", [] call FUNC(stamp)];
    GVAR(opordArchive) set [_x, _copy];
} forEach (GVAR(structure) getOrDefault ["opords", createHashMap]);
["3/6", format ["orders cached: %1 in the archive, current '%2'", count GVAR(opordArchive), GVAR(settings) getOrDefault ["currentOpord", ""]]] call FUNC(bootLog);

// ---- 4/6 store, profile ------------------------------------------------------
[] call FUNC(storeLoad);
["4/6", format ["store from the profile: %1 player(s), %2 session(s), %3 window(s), %4 cached order(s), %5 log row(s)%6",
    count GVAR(players), count GVAR(sessions), count GVAR(windows), count GVAR(opordArchive), count GVAR(log),
    ["", " - STORE LOOKS LOST, read-only"] select GVAR(readOnly)]] call FUNC(bootLog);

// ---- 5/6 store, service ------------------------------------------------------
if (_service && GVAR(svcUp)) then {
    ["5/6", format ["service: asking for '%1' (the store)", _unit]] call FUNC(bootLog);
    ([_unit] call FUNC(svcLoad)) params ["_doc", "_status"];
    switch (_status) do {
        case "ok": {
            // THE DATABASE STORE IS THE SOURCE OF TRUTH for sync = "service"
            // and wins over the profile, always. (A "newer local wins" guard
            // was tried 2026-09-05 and reverted: the profile is shared across
            // missions, so a sync = "off" run that saved a smaller store with
            // a newer timestamp made that guard discard the real database
            // roster - "the storage did not load". A rank set in game reaches
            // the database through the edit's own save, the SAVE button, and
            // the forced save at mission end.)
            private _remoteAt = _doc getOrDefault ["exportedAt", "?"];
            if ([_doc] call FUNC(storeAdopt)) then {
                ["5/6", format ["service: store ADOPTED - %1 player(s), %2 session(s), saved %3 (the database wins over the profile)", count GVAR(players), count GVAR(sessions), _remoteAt]] call FUNC(bootLog);
            } else {
                ["5/6", "service: store document is the wrong shape - REFUSED, keeping the profile copy"] call FUNC(bootLog);
            };
        };
        case "empty": {
            ["5/6", "service: no store document yet - the database store is created the first time an admin presses SAVE (or at mission end); the boot no longer writes it"] call FUNC(bootLog);
        };
        default {
            GVAR(svcUp) = false;
            ["5/6", "service: NOT ANSWERING for the store - running on the profile copy; saves will still be attempted"] call FUNC(bootLog);
        };
    };
} else {
    ["5/6", ["service: off", "service: skipped (the structure step found nothing to talk to)"] select _service] call FUNC(bootLog);
};

// ---- 6/6 save, publish, ready ------------------------------------------------
// PROFILE ONLY - NEVER THE DATABASE. The boot has just READ the store from the
// database in step 5; writing it back here is exactly what wiped it - any hiccup
// (a slow read, an empty profile left by another mission) and a smaller local
// store overwrote the real one. The database is written only when an admin
// presses SAVE, and at mission end for play time (user, 2026-09-05).
private _wrote = [true, false] call FUNC(storeSave);
[] call FUNC(publish);

// The structure and the settings go to every client once - JIP gets them with
// the mission - so a client on a config-less mission has what the server has.
GVAR(structureSvc) = GVAR(structure);
GVAR(settingsSvc) = GVAR(settings);
publicVariable QGVAR(structureSvc);
publicVariable QGVAR(settingsSvc);
publicVariable QGVAR(bootLog);
["structure"] call FUNC(hostRefresh);     // the host does not hear its own publicVariable

GVAR(ready) = true;
publicVariable QGVAR(ready);
// THE BANNER. The boot log is six lines among thousands in an .rpt; an admin
// checking "did the database load?" should be able to see the answer while
// scrolling past. Drawn only when the service actually answered - a banner that
// appears either way answers nothing.
if (GVAR(svcUp)) then {
    {diag_log text _x} forEach [
        "",
        "    +--------------------------------------------------------+",
        "    |  ####  #  #  ####  ####  ####      ####  ####  ####    |",
        "    |  #     #  #  #  #  #      ##       #  #  #  #  #       |",
        "    |  # ##  ####  #  #  ####   ##       ####  ####  #       |",
        "    |  #  #  #  #  #  #     #   ##       #     #  #  #       |",
        "    |  ####  #  #  ####  ####   ##       #     #  #  ####    |",
        "    |                                                        |",
        "    |            D A T A B A S E   L O A D E D               |",
        "    +--------------------------------------------------------+",
        format ["      unit '%1' - %2 player(s), structure hash %3", GVAR(settings) getOrDefault ["unitId", "?"], count GVAR(players), GVAR(structureHash)],
        format ["      config and store came from the database. %1", call _fnc_counts],
        ""
    ];
};

["6/6", format ["READY - profile %1%2; %3 player(s) on the roster, structure hash %4", ["NOT WRITTEN (read-only)", "written"] select _wrote, ["", " + service"] select GVAR(svcUp), count GVAR(players), GVAR(structureHash)]] call FUNC(bootLog);
