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
// field. All three call the same function; see FUNC(applyOnClient).
//
// The groups addon calls it too, at the end of its own role setup, so PAC's
// answer goes on after the role's defaults and not under them.
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
        [] call FUNC(applyOnClient);
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
// before the boot so nothing can arrive unheard.
addMissionEventHandler ["ExtensionCallback", {
    params ["_name", "_function", "_data"];
    if (_name isNotEqualTo "ghostd_pacdb") exitWith {};
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
        // The answer to the boot's network check - the address Atlas will see,
        // and whether TLS works from this machine. Asked only when the admin
        // turned the setting on; see initSettings.inc.sqf.
        case "netcheck": {INFO_1("network check: %1",_data)};
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
    [true, true] call FUNC(storeSave);
    ["mission end"] call FUNC(backupDump);
    INFO("mission ended - store written to profile and database (play-time commit)");
}];

// A player is seeded the moment they arrive rather than when somebody first
// edits them, so the Unassigned filter in the admin panel is a list of people
// who have actually been on the server.
// NEW PLAYERS: settings newPlayers (2026-09-10). "auto" seeds a record the
// moment they arrive, as always; "apply" does not - they apply from the
// tacpad's PAC tile (or the website) and an admin accepts them under
// APPLICATIONS, which is what seeds the record. Somebody already on the
// roster is never touched by the setting.
addMissionEventHandler ["PlayerConnected", {
    params ["", "_uid", "_name"];
    private _mode = toLower (GVAR(settings) getOrDefault ["newPlayers", "auto"]);
    if (_mode isEqualTo "apply" && {!(_uid in GVAR(players))}) then {
        INFO_2("%1 (%2) connected and is not on the roster - newPlayers is 'apply', no record seeded",_name,_uid);
    } else {
        [_uid, _name] call FUNC(record);
    };
    [_uid, _name] call FUNC(sessionStart);
    [] call FUNC(publish);
}];

// ATTENDANCE. A disconnect closes the session; a heartbeat keeps lastSeenAt
// honest for the server that dies without one. Sessions still open from a
// previous run - nobody has connected yet, so every open row is stale - are
// closed at their lastSeenAt, which is the best answer there is. An op window
// left open is NOT closed: windows are started and stopped by an admin, and a
// server restart mid-op should not end the op.
addMissionEventHandler ["PlayerDisconnected", {
    params ["", "_uid"];
    [_uid] call FUNC(sessionEnd);
}];

{
    if ((_x # 4) isEqualTo "") then {_x set [4, _x # 3]};
} forEach GVAR(sessions);

GVAR(windowOpen) = "";
{
    if ((_x # 3) isEqualTo "" && {(_x # 4) isEqualTo "manual"}) then {GVAR(windowOpen) = _x # 0};
} forEach GVAR(windows);

[] spawn {
    while {true} do {
        sleep PAC_HEARTBEAT;
        [] call FUNC(sessionTick);
    };
};
