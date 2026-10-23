#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

// node id -> the register arguments last sent
GVAR(sent) = createHashMap;

// THE VOICE API'S VIEW, refreshed by fnc_voiceView (each poll, and at once on
// a change made here): his radios' nets as jmfsb_voice_fnc_nets rows, their
// netState rows, the net of the radio in hand, and net -> radio id.
GVAR(nets) = [];
GVAR(rows) = [];
GVAR(current) = "";
GVAR(slots) = createHashMap;
// Who is heard on a radio now: uid -> [unit, net] (ACRE's remote speaking
// events), and the net his own radio transmission is on ("" none).
GVAR(heard) = createHashMap;
GVAR(txNet) = "";
// A radio's volume before a mute: radio id -> 0..1.
GVAR(volumes) = createHashMap;

// jmfsb_voice's adapter. The voice core (required, so its preInit ran first)
// takes "acre" only while ACRE is the system it found loaded.
if (EGVAR(voice,system) isEqualTo VOICE_ID) then {
    [VOICE_ID, createHashMapFromArray [
        ["nets", {+GVAR(nets)}],
        ["netState", {+GVAR(rows)}],
        ["talking", {_this call FUNC(talking)}],
        ["current", {GVAR(current)}],
        ["setActive", {_this call FUNC(setActive)}],
        ["ptt", {[GVAR(txNet) isNotEqualTo "", GVAR(txNet)]}],
        ["setEar", {_this call FUNC(setEar)}],
        ["setMute", {_this call FUNC(setMute)}],
        ["linkQuality", {QUALITY_FULL}],
        ["selfTest", {_this call FUNC(selfTest)}]
    ]] call EFUNC(voice,registerAdapter);
};

ADDON = true;
