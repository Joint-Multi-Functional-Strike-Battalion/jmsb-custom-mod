#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// WHICH SYSTEM CARRIES THE VOICE (user, 2026-10-20; the choice a setting,
// 2026-10-30): the automatic answer - LiveKit when adapter_livekit announces
// itself here (its preInit), else game VON - now, so every reader has one
// before the settings are in. The setting (jmfsb_voice_defaultSystem) is read
// at CBA_settingsInitialized, below, before anything of any system starts
// (XEH_postInit gates on it there too). TFAR and ACRE are no longer choices
// (DEC1, 2026-10-31).
GVAR(loaded) = [];

// THE ADAPTER: hooks of the backend that carries the audio. adapter_von
// registers "von" and adapter_livekit "livekit", each in its preInit (they
// require this addon, so this runs first); every one is kept
// (GVAR(adapters)) and FUNC(applyAdapter) takes the system's. Until then
// every hook is a no-op with a neutral answer.
GVAR(adapters) = createHashMap;     // adapter id -> its hooks
GVAR(adapterIds) = [];              // ...in the order they registered
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
    ["audience", {_this call FUNC(audience)}],
    ["selfTest", {}]
];
GVAR(adapter) = +GVAR(adapterDefaults);
GVAR(adapterId) = "";
// The automatic answer now; the setting's once it is in. Registered here, in
// preInit, so it runs before every postInit's CBA_settingsInitialized handler
// (the adapters', this addon's) - they read jmfsb_voice_system / _active.
// THE SERVER'S CHOICE IS EVERYONE'S (FUNC(followServer)): it publishes it, a
// client takes it ("none" when it cannot run it), and every client-side start
// waits for jmfsb_voice_systemReady rather than the settings.
[SYSTEM_AUTO] call FUNC(selectSystem);
["CBA_settingsInitialized", {
    [GVAR(defaultSystem)] call FUNC(selectSystem);
    [] call FUNC(followServer);
}] call CBA_fnc_addEventHandler;

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
GVAR(slots) = [];                   // call ids per slot, "" = free: CALL_SLOTS, more on the voice server (FUNC(srvSlot))
for "_i" from 1 to CALL_SLOTS do {GVAR(slots) pushBack ""};
GVAR(callbacks) = [];               // [[from, to, requestedAt, state], ...]
GVAR(joined) = createHashMap;       // uid -> nets the adapter has him joined to
GVAR(teamNets) = createHashMap;     // TEAM net ids made in RF
GVAR(customNets) = createHashMap;   // RTO net id -> [name, squads, uids, owner uid, owner name] (FUNC(srvNetAdd))
GVAR(published) = [];               // [calls, callbacks] last sent

// CLIENT STATE (the local player).
GVAR(myNodes) = [];                 // his RF node ids
GVAR(batteryWarned) = -1;           // the battery warning last said, an index into BATTERY_WARN_LEVELS (FUNC(batteryTick))
GVAR(sent) = createHashMap;         // node id -> registration last sent
GVAR(activeNetId) = "";            // the active net
GVAR(globalOn) = false;            // a leader or admin on Global (FUNC(global))
GVAR(beforeCall) = "";              // active net before a call took it
GVAR(wantActive) = "";              // net to make active as soon as it can be
GVAR(wantTeamUntil) = 0;            // until when FUNC(checkActive) lands him on TEAM once it is listed (FUNC(toTeam))
GVAR(muted) = createHashMap;        // net -> true
GVAR(ears) = createHashMap;         // net -> "L" | "B" | "R"
GVAR(pttNets) = createHashMap;      // PTT key 2..4 -> net id, or PTT_OFF (FUNC(pttKey))
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
