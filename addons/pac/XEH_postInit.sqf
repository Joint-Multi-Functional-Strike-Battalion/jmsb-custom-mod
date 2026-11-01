#include "script_component.hpp"

// STRUCTURE IS READ EVERYWHERE, the store only on the server. A client needs the
// structure to draw a roster row - it turns a rankId into an abbrev and an
// insignia - and it is compiled config, identical on every machine, soa client
// reading it for itself is cheaper than the server sending it.
[] call FUNC(loadStructure);

// The "opord" and "mettc" message templates, unless the mission's deck has
// them. Every machine, because messaging renders from a registry that must
// be the same everywhere.
[] call FUNC(registerTemplates);

// THE APP, on anything with a screen. Registered with the tacpad the way every
// other app is; the tile is in tacpad_apps' own tile list, guarded on this addon
// being loaded.
if (hasInterface && {!isNil "jmfsb_tacpad_fnc_registerApp"}) then {
    ["pac", FUNC(app)] call jmfsb_tacpad_fnc_registerApp;
};

// A PLAYER PUTS THEIR OWN RANK AND SKILLS ON, from the published roster, at
// three moments: first spawn, every respawn, and every time the server
// publishes - which is how an admin's edit reaches somebody already in the
// field. Spawn and respawn run FUNC(applyOnClient): rank, skills, and the
// server's seeding, slotting and kept loadout. A publish runs only
// FUNC(reapplyLocal) - rank and skills - so nobody's gear resets because
// somebody else joined or was edited.
//
// The groups addon calls applyOnClient too, at the end of its own role setup,
// so PAC's answer goes on after the role's defaults and not under them.
if (hasInterface) then {
    // THE SERVER'S STRUCTURE AND SETTINGS WIN over what this machine compiled
    // from its own mission config - which, on a mission whose config lives in
    // the database, is nothing but three settings. A JIP client has them
    // before this runs; a first client gets them a moment later.
    [] call FUNC(takeServer);
    // The boot overlay is for a mission that actually boots - not the empty
    // editor map or the main menu, which declare no CfgGFA_PAC.
    if (isClass (missionConfigFile >> "CfgGFA_PAC")) then {[] spawn FUNC(bootScreen)};
    // THE ONE DIALOG REDRAWS ITSELF when what it reads is republished - a
    // table page, never a form being typed into (FUNC(uiRefresh)).
    // An arsenal list edited or arsenalMode changed reaches every open
    // arsenal too (jmfsb_groups_fnc_buildArsenal listens).
    QGVAR(structureSvc) addPublicVariableEventHandler {
        [] call FUNC(takeServer);
        ["structure"] call FUNC(uiRefresh);
        [QGVAR(arsenalChanged), []] call CBA_fnc_localEvent;
    };
    QGVAR(settingsSvc) addPublicVariableEventHandler {
        [] call FUNC(takeServer);
        ["settings"] call FUNC(uiRefresh);
        [QGVAR(arsenalChanged), []] call CBA_fnc_localEvent;
    };

    // The admin panel's session skills (FUNC(sessionSkills)) - re-applied when
    // the list arrives, whichever of it and the server's nudge lands first.
    QGVAR(session) addPublicVariableEventHandler {
        if (!isNull player) then {[player] call FUNC(applyTemp)};
    };
    QGVAR(roster) addPublicVariableEventHandler {
        // The spawn work runs here only if this life has not had it yet -
        // the player's row was not on the roster when he spawned.
        if (!isNull player && {!(player getVariable [QGVAR(spawnApplied), false])}) then {
            [] call FUNC(applyOnClient);
        } else {
            [] call FUNC(reapplyLocal);
        };
        ["roster"] call FUNC(uiRefresh);
    };
    QGVAR(summary) addPublicVariableEventHandler {
        ["summary"] call FUNC(uiRefresh);
    };

    addMissionEventHandler ["EntityRespawned", {
        params ["_new"];
        if (_new isEqualTo player) then {
            // The admin panel's session skills last the whole mission now
            // (FUNC(sessionSkills), by Steam id) - a respawn keeps them.
            [] call FUNC(applyOnClient);
        };
    }];

    [] spawn {
        waitUntil {sleep 1; !isNull player && {alive player} && {missionNamespace getVariable [QGVAR(ready), false]}};
        [] call FUNC(applyOnClient);
    };
};

if (!isServer) exitWith {};

// THE PLAN'S NETS INTO RF, once now; FUNC(radioApply) again on every change.
[] call FUNC(netPlanSync);

// THE STORE AND THE DATABASE ARE THE MISSION'S, NOT THE GAME'S. Only a mission
// that declares CfgGFA_PAC registers the boot, the mission-end save, the connect
// handlers and the heartbeat below. The empty editor map the maker opens first,
// the main menu, any non-PAC mission: none of them run a line of store code, so
// none can write the shared profile store or reach the database. This is the
// other half of the wipe fix - an empty mission used to reach the mission-end
// save with an empty roster and blank the profile, and the next boot then
// carried that emptiness at the database (user, 2026-09-05: "opening an empty
// mission wiped the db ... the db load must start with the mission, not the game").
if (!isClass (missionConfigFile >> "CfgGFA_PAC")) exitWith {
    GVAR(ready) = true;
    publicVariable QGVAR(ready);
    INFO("no CfgGFA_PAC in this mission - the store and database are idle");
};

// THE SERVICE'S ANSWERS. The pacdb extension (tools/pacdb) replies through
// this event, in chunks; FUNC(svcLoad) waits on the state it sets. Registered
// before the boot so nothing can arrive unheard. A get or list's last
// answer pays the request's debt (GVAR(svcOwed)), so the next can go.
addMissionEventHandler ["ExtensionCallback", {
    params ["_name", "_function", "_data"];
    if (_name isNotEqualTo "ghostd_pacdb") exitWith {};
    if (_function in ["get.end", "get.error", "list", "list.error"]) then {
        GVAR(svcOwed) = (GVAR(svcOwed) - 1) max 0;
    };
    switch (_function) do {
        case "get.begin": {
            private _n = parseNumber _data;
            GVAR(svcChunks) = [];
            for "_i" from 1 to _n do {GVAR(svcChunks) pushBack ""};
        };
        case "get.chunk": {
            private _k = _data find "|";
            if (_k < 0) exitWith {};
            private _i = parseNumber (_data select [0, _k]);
            if (_i >= 0 && {_i < count GVAR(svcChunks)}) then {GVAR(svcChunks) set [_i, _data select [_k + 1]]};
        };
        case "get.end": {GVAR(svcState) = ["ok", "empty"] select (_data isEqualTo "empty")};
        case "list": {GVAR(svcChunks) = [_data]; GVAR(svcState) = "ok"};
        case "list.error": {
            GVAR(svcState) = "error";
            GVAR(svcLastError) = _data;   // the boot repeats it in the FAILED block
            WARNING_1("service list failed: %1",_data);
        };
        case "get.error": {
            GVAR(svcState) = "error";
            GVAR(svcLastError) = _data;
            WARNING_1("service get failed: %1",_data);
        };
        case "put.end": {TRACE_1("service put",_data)};
        case "put.error": {WARNING_1("service put failed: %1",_data)};
        case "ping": {INFO_1("pacdb extension: %1",_data)};
    };
}];

// THE BOOT, in order, in FUNC(boot) - spawned because the service step waits.
[] spawn FUNC(boot);

// MISSION END IS A FORCED SAVE. The debounce protects frames during play; the
// last thirty seconds of an op are worth a hitch nobody is left to feel.
//
// addMissionEventHandler, not a CBA event - vanilla plumbing, per the handoff.
// MISSION END IS THE PLAY-TIME COMMIT: the one automatic database write, and it
// writes the WHOLE store (players, sessions, windows, the action log) so play
// time and actions accumulated this session are put down and nothing already in
// the database is dropped (user, 2026-09-05: "updating play time should be the
// only exception ... make sure play time and actions do NOT get overwritten").
addMissionEventHandler ["Ended", {
    // nothing real to write or dump if the boot never loaded the store
    if !(GVAR(storeReady)) exitWith {WARNING("mission ended before the store was loaded - nothing written")};
    [true, true] call FUNC(storeSave);
    ["mission end"] call FUNC(backupDump);
    INFO("mission ended - store written to profile and database (play-time commit)");
}];

// A player is seeded the moment they arrive rather than when somebody first
// edits them, so the Unassigned filter in the admin panel is a list of people
// who have actually been on the server (FUNC(playerJoin), which also applies
// settings newPlayers).
//
// NOT BEFORE THE STORE IS LOADED. Until the boot opens GVAR(storeReady) the
// store in memory is empty; a connect then is queued and the boot replays it
// once the store is in. Handling it at once wrote that empty store over the
// profile.
//
// NOT A HEADLESS CLIENT (review L1): it connects like a player and would be
// seeded as one.
addMissionEventHandler ["PlayerConnected", {
    params ["", "_uid", "_name", "", "", "_idstr"];
    if ((getUserInfo _idstr) param [PAC_USERINFO_IS_HC, false]) exitWith {};
    if !(GVAR(storeReady)) exitWith {GVAR(bootQueue) pushBack [true, _uid, _name]};
    [_uid, _name] call FUNC(playerJoin);
}];

// ATTENDANCE. A disconnect closes the session; a heartbeat keeps lastSeenAt
// honest for the server that dies without one. Sessions left open by a
// previous run are closed by the boot, after it has loaded them (FUNC(boot)
// step 6), as is the manual op window restored.
addMissionEventHandler ["PlayerDisconnected", {
    params ["", "_uid"];
    if !(GVAR(storeReady)) exitWith {GVAR(bootQueue) pushBack [false, _uid, ""]};
    [_uid] call FUNC(sessionEnd);
}];

// THE HEARTBEAT: attendance (FUNC(sessionTick)), the roster's totals
// (FUNC(rosterTotals) - a publish when the promotion-due list changed), and a
// save the debounce held back, so an edit is never left only in memory.
[] spawn {
    while {true} do {
        sleep PAC_HEARTBEAT;
        if !(GVAR(storeReady)) then {continue};
        [] call FUNC(sessionTick);
        if ([] call FUNC(rosterTotals)) then {[] call FUNC(publish)};
        if (GVAR(dirty) && {!GVAR(readOnly)}) then {[] call FUNC(storeSave)};
    };
};
