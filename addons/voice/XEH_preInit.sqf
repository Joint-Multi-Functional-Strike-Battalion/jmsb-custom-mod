#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// WHICH SYSTEM CARRIES THE VOICE (user, 2026-10-20): VON only when neither TFAR
// nor ACRE is loaded. Decided once, here, from this machine's own CfgPatches
// (server and clients load the same mods). Under TFAR or ACRE nothing of VON is
// started (XEH_postInit): the core only mirrors that radio's adapter for the
// UIs (fnc_externalTick), and calls, contacts and sounds answer empty.
private _tfar = TFAR_PATCHES select {isClass (configFile >> "CfgPatches" >> _x)};
private _acre = ACRE_PATCHES select {isClass (configFile >> "CfgPatches" >> _x)};
GVAR(system) = SYSTEM_VON;
if (_acre isNotEqualTo []) then {GVAR(system) = SYSTEM_ACRE};
if (_tfar isNotEqualTo []) then {GVAR(system) = SYSTEM_TFAR};
GVAR(active) = GVAR(system) isEqualTo SYSTEM_VON;
if (!GVAR(active)) then {
    INFO_2("voice: %1 loaded (%2) - VON stands down, the core serves that radio's nets",GVAR(system),_tfar + _acre);
};
if (_tfar isNotEqualTo [] && _acre isNotEqualTo []) then {
    WARNING("voice: TFAR and ACRE both loaded - TFAR's adapter is the one taken");
};
// External-radio mode: when the adapter's nets are next read (fnc_externalTick).
GVAR(extNetsAt) = 0;

// THE ADAPTER: hooks of the backend that carries the audio. adapter_von
// registers "von" in its preInit (it requires this addon, so this runs first);
// under TFAR / ACRE adapter_tfar / adapter_acre register "tfar" / "acre".
// Until one registers, every hook is a no-op with a neutral answer.
GVAR(adapterDefaults) = createHashMapFromArray [
    ["join", {}],
    ["leave", {}],
    ["quality", {}],
    ["talking", {[]}],
    ["channel", {NO_CHANNEL}],
    ["setActive", {false}],
    ["current", {""}],
    ["block", {}],
    ["ptt", {[false, ""]}],
    ["keyed", {}],
    ["audience", {
        params ["_unit", "_net"];
        ([_net, _unit] call FUNC(members)) - [_unit]
    }],
    ["selfTest", {}],
    // external radio only (HOOKS_REQUIRED_EXTERNAL)
    ["nets", {[]}],
    ["netState", {[]}],
    ["setEar", {false}],
    ["setMute", {false}],
    ["linkQuality", {QUALITY_FULL}]
];
GVAR(adapter) = +GVAR(adapterDefaults);
GVAR(adapterId) = "";

// SERVER-PUBLISHED, read everywhere (see fnc_serverTick / fnc_srvPublish).
// Public variables keep a JIP value that arrived before this ran.
if (isNil QGVAR(roster)) then {GVAR(roster) = []};      // [[unit, uid, radio nets in his fill, emcon], ...]
if (isNil QGVAR(callPub)) then {GVAR(callPub) = [[], []]}; // [call table, callbacks]
if (isNil QGVAR(customPub)) then {GVAR(customPub) = []};  // RTO nets, [[id, name, squads, uids, owner uid, owner name], ...]
// ...and what they say, as read by jmfsb_voice_fnc_receiveRoster / receiveCalls.
GVAR(rosterIndex) = createHashMap;  // uid -> roster row
GVAR(callTable) = [];               // [[id, slot, from, members, ringing, priority, startedAt, live, bumping], ...]
GVAR(callbackTable) = [];           // [[from, to, requestedAt, state], ...]

// THE PAC PLAN, cached by jmfsb_voice_fnc_planRefresh on every machine.
GVAR(plan) = [];
GVAR(planKinds) = createHashMap;    // plan net id -> "team" | "c2" | "a2g" | "custom"
GVAR(planSlots) = createHashMap;    // "sr<slot>" | "lr<slot>" -> plan net id (tfarNets plan only)
GVAR(planSquad) = createHashMap;    // "<SQUAD>|<kind>" -> net, from jmfsb_pac_fnc_netPlanSquad

// SERVER STATE.
GVAR(calls) = createHashMap;        // call id -> call hashmap
GVAR(slots) = [];                   // CALL_SLOTS call ids, "" = free
for "_i" from 1 to CALL_SLOTS do {GVAR(slots) pushBack ""};
GVAR(callbacks) = [];               // [[from, to, requestedAt, state], ...]
GVAR(joined) = createHashMap;       // uid -> nets the adapter has him joined to
GVAR(teamNets) = createHashMap;     // TEAM net ids made in RF
GVAR(customNets) = createHashMap;   // RTO net id -> [name, squads, uids, owner uid, owner name] (FUNC(srvNetAdd))
GVAR(published) = [];               // [calls, callbacks] last sent

// CLIENT STATE (the local player).
GVAR(myNodes) = [];                 // his RF node ids
GVAR(sent) = createHashMap;         // node id -> registration last sent
GVAR(activeNetId) = "";            // the active net
GVAR(globalOn) = false;            // a leader or admin on Global (FUNC(global))
GVAR(beforeCall) = "";              // active net before a call took it
GVAR(wantActive) = "";              // net to make active as soon as it can be
GVAR(wantTeamUntil) = 0;            // until when FUNC(checkActive) lands him on TEAM once it is listed (FUNC(toTeam))
GVAR(muted) = createHashMap;        // net -> true
GVAR(ears) = createHashMap;         // net -> "L" | "B" | "R"
GVAR(myNets) = [];                  // jmfsb_voice_fnc_nets rows, last tick
GVAR(eff) = createHashMap;          // "uid|net" -> quality after grace
GVAR(lastGood) = createHashMap;     // "uid|net" -> [time, quality]
GVAR(applied) = createHashMap;      // "uid|net" -> what the adapter was last told
GVAR(talkers) = [];                 // [[unit, net], ...] last frame
GVAR(staticNext) = createHashMap;   // "uid|net" -> [next static clip time, heard quality, sound id]
GVAR(myCalls) = createHashMap;      // call id -> [state, member count, bumping]
GVAR(callSeq) = 0;
GVAR(blocked) = false;             // radio silence (EMCON 3)
GVAR(level) = BLOCK_NONE;          // cut-off level (fnc_blockLevel), what the adapter was told
GVAR(blockReason) = "";
GVAR(pttDown) = false;             // his own push-to-talk, last frame
GVAR(keyNet) = "";                 // the net his key sends on now, "" when not keyed
GVAR(keyLive) = false;             // ...and he is transmitting on one of his nets
GVAR(keyAudience) = [];            // who was told of his key-down

#include "initSettings.inc.sqf"

ADDON = true;
