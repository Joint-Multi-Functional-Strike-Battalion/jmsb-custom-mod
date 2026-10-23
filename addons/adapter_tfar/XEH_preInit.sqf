#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// What this client last told RF about each of its nodes:
// node id -> [register args, state pairs]
GVAR(sent) = createHashMap;
// The kind of set ("sr" | "lr" | "veh") whose tangent is down, "" for none,
// and the net it keys.
GVAR(txKind) = "";
GVAR(txNet) = "";
// Kind of set -> its current channel (0-based), for a set whose channel
// carries no net.
GVAR(channels) = createHashMap;
// Sets this client has already offered the plan's fill to (str of TFAR's
// handle), so a set is filled once, when it first appears.
GVAR(filled) = createHashMap;
// Kind of set -> nets a fill loaded that the plan does not name, so their
// channels still read back as nets.
GVAR(fillNets) = createHashMap;
// TFAR's own UI settings as the player has them, while ours overrides them;
// read only once every setting has its value (CBA_settingsInitialized), so
// what is kept is the player's and not a default.
GVAR(tfarUiKept) = createHashMap;
GVAR(uiReady) = false;
// Our PTT action whose key is down, "" for none.
GVAR(pttHeld) = "";

// THE VOICE API'S VIEW, refreshed by fnc_poll (each second, and at once on a
// change made here): the nets his sets hear (each set's active and additional
// channel) as jmfsb_voice_fnc_nets rows, their netState rows, the net the main
// PTT keys, and where each net sits: net -> [set kind, radio, additional].
GVAR(nets) = [];
GVAR(rows) = [];
GVAR(current) = "";
GVAR(slots) = createHashMap;
// The set kind whose active net is the voice API's active net ("sr" first).
GVAR(activeKind) = NODE_SR;
// A set's volume before a mute (str of TFAR's handle -> 0..10).
GVAR(volumes) = createHashMap;
// Other speakers who pushed their key-down to us: uid -> [unit, net].
GVAR(heard) = createHashMap;

#include "initSettings.inc.sqf"

// jmfsb_voice's adapter. The voice core (required, so its preInit ran first)
// takes "tfar" only while TFAR is the system it found loaded.
if (EGVAR(voice,system) isEqualTo VOICE_ID) then {
    [VOICE_ID, createHashMapFromArray [
        ["nets", {+GVAR(nets)}],
        ["netState", {+GVAR(rows)}],
        ["talking", {_this call FUNC(talking)}],
        ["current", {GVAR(current)}],
        ["setActive", {_this call FUNC(setActive)}],
        ["ptt", {[GVAR(txKind) isNotEqualTo "", GVAR(txNet)]}],
        ["setEar", {_this call FUNC(setEar)}],
        ["setMute", {_this call FUNC(setMute)}],
        ["linkQuality", {_this call FUNC(linkQuality)}],
        ["selfTest", {_this call FUNC(selfTest)}]
    ]] call EFUNC(voice,registerAdapter);
};

ADDON = true;
