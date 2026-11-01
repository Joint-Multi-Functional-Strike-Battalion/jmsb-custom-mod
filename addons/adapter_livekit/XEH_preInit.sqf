#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// THE EXTENSION: its version, "" when it is not loaded (a Linux player, or a
// BattlEye-protected machine that has not whitelisted it). Asked now, so the
// voice core can be told which system this machine can run before the
// settings are in.
(["version"] call FUNC(ext)) params ["_version", "_ok"];
GVAR(version) = ["", _version] select _ok;

// CLIENT: the echo test - its state, when it entered it, and its tick.
GVAR(echo) = ECHO_NONE;
GVAR(echoSince) = 0;
GVAR(echoPfh) = -1;

// THE ROOM (one per mission; the server names it, XEH_postInit) and this
// machine's place in it: the state, when it entered it, the mix tick.
GVAR(state) = ROOM_NONE;
GVAR(since) = 0;
GVAR(pfh) = -1;
// Per speaker (his UID): the unit and the net he keyed (hook "keyed"), the
// quality the voice core gave him per net ("uid|net", hook "quality"), the
// gain and ear last sent to the extension, and whether he is subscribed.
GVAR(keyed) = createHashMap;
GVAR(q) = createHashMap;
GVAR(sent) = createHashMap;
GVAR(subs) = createHashMap;
GVAR(earPans) = createHashMapFromArray [["L", -1], ["B", 0], ["R", 1]];
// THE JOIN: the number of the last token asked for (an answer to an older
// ask is dropped), the wait before the next try after a failed one, and
// whether a failure or a missing microphone was said already.
GVAR(ask) = 0;
GVAR(retryS) = ROOM_RETRY_S;
GVAR(toldError) = false;
GVAR(toldNoMic) = false;
// SERVER: when each machine last asked for a token (owner -> time).
GVAR(tokenAt) = createHashMap;
// THE MIC: the PTT keys held (in press order, the last wins), TALK LOCAL
// held, whether the mic is open now, the active net (hook "setActive"), and
// the voice core's cut-off level (hook "block").
GVAR(heldPtt) = [];
GVAR(holdLocal) = false;
GVAR(mic) = false;
GVAR(activeNet) = "";
GVAR(level) = BLOCK_NONE;
GVAR(toldNoServer) = false;

// THE ADAPTER (user, 2026-10-31: "livekit was to be the VON"): registered
// whatever the system; the voice core takes it while LiveKit is the system
// chosen (jmfsb_voice_fnc_selectSystem) - which it is wherever the extension
// answers, so that is announced here and the automatic answer asked again,
// and every reader has it before the settings are in. Membership (join /
// leave) needs nothing: one room holds everyone, and who hears whom is the
// mix (FUNC(gainOf)). No channel count to run out of: every RTO net is
// granted. The game VON's Global channel does not exist here.
[ADAPTER_ID, createHashMapFromArray [
    ["join", {}],
    ["leave", {}],
    ["quality", {_this call FUNC(quality)}],
    ["talking", {[] call FUNC(talking)}],
    ["setActive", {_this call FUNC(setActive)}],
    ["current", {GVAR(activeNet)}],
    ["block", {_this call FUNC(block)}],
    ["ptt", {[] call FUNC(ptt)}],
    ["keyed", {_this call FUNC(keyed)}],
    ["reserve", {true}],
    ["channelUse", {[]}],
    ["global", {false}]
]] call EFUNC(voice,registerAdapter);
if (GVAR(version) isNotEqualTo "") then {
    EGVAR(voice,loaded) pushBackUnique ADAPTER_ID;
    [VOICE_SYSTEM_AUTO] call EFUNC(voice,selectSystem);
};

ADDON = true;
