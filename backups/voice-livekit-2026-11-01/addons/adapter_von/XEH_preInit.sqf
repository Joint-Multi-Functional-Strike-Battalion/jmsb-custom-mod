#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// SERVER: custom channel key -> custom id (1..10), and the same published to
// everyone as [[key, id], ...]. A JIP value that arrived first is kept.
GVAR(customs) = createHashMap;
if (isNil QGVAR(channelMap)) then {GVAR(channelMap) = []};

// CLIENT: per speaker the channel his volume was last set for, the quality
// the voice core gave for him per net ("uid|net"), and the speakers who
// pushed their key-down (uid -> [unit, channel, net]) until their key-up.
GVAR(talkCh) = createHashMap;
GVAR(q) = createHashMap;
GVAR(keyed) = createHashMap;
// The cut-off level the voice core gave (fnc_block), and the mission's voice
// state of Vehicle / Direct while a cut-off holds them (channel -> voice).
GVAR(level) = BLOCK_NONE;
GVAR(saved) = createHashMap;
GVAR(toldToggle) = false;
// Global opened to a leader by the tablet's GLOBAL button (FUNC(global)).
GVAR(globalOn) = false;
GVAR(test) = createHashMap;
// The mic's channel: the active net's channel as the voice core last set it
// (fnc_setActive), the PTT keys and TALK LOCAL while held, and where an open
// mic sits when none is - LOCAL by default, so voice activation never opens a
// net by surprise (fnc_openChannel).
GVAR(activeCh) = CH_NONE;
GVAR(heldPtt) = [];                 // PTT keys 1..4 held now, in press order: the last pressed wins
GVAR(holdLocal) = false;
GVAR(openNet) = false;
// A PTT 2-4 key whose net VON refused (fnc_applyOpen): the channel whose voice
// is held off meanwhile, [channel, its voice before] ([] none), and the key
// last told why (KEY_NONE: none), so it is said once per press.
GVAR(holdOff) = [];
GVAR(refusedKey) = KEY_NONE;

#include "initSettings.inc.sqf"

// The default voice adapter (jmfsb_voice requires nothing of us; we require
// it). Always registered; the voice core takes it only while VON is the
// system chosen (jmfsb_voice_fnc_selectSystem), and nothing of VON is started
// otherwise (XEH_postInit).
["von", createHashMapFromArray [
    ["join", {_this call FUNC(join)}],
    ["leave", {_this call FUNC(leave)}],
    ["quality", {_this call FUNC(quality)}],
    ["talking", {_this call FUNC(talking)}],
    ["channel", {_this call FUNC(channel)}],
    ["setActive", {_this call FUNC(setActive)}],
    ["current", {_this call FUNC(current)}],
    ["block", {_this call FUNC(block)}],
    ["ptt", {_this call FUNC(ptt)}],
    ["keyed", {_this call FUNC(keyed)}],
    ["audience", {_this call FUNC(audience)}],
    ["selfTest", {_this call FUNC(selfTest)}],
    ["channelUse", {_this call FUNC(channelUse)}],
    ["global", {_this call FUNC(global)}],
    ["reserve", {_this call FUNC(reserve)}]
]] call EFUNC(voice,registerAdapter);

ADDON = true;
