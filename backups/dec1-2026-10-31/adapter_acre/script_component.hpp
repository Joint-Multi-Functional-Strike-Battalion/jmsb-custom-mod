#define COMPONENT adapter_acre
#define COMPONENT_BEAUTIFIED ACRE Adapter
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_ADAPTER_ACRE
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_ADAPTER_ACRE
    #define DEBUG_SETTINGS DEBUG_SETTINGS_ADAPTER_ACRE
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// THE ACRE SEAM for voice and RF. Loads only with ACRE2. Then it is
// jmfsb_voice's "acre" adapter: VON stands down and the core reads nets, net
// state, the active net, ear, mute and talking from here, through ACRE's
// public API only (acre_api_fnc_*, and ACRE's own speaking events). Radios
// are still programmed by jmfsb_gear_fnc_setupRadios from the PAC plan.

// The voice adapter id, the same string jmfsb_voice_system holds under ACRE.
#define VOICE_ID "acre"

// ACRE base radio class -> RF profile id. Anything not listed is legacy.
#define ACRE_PROFILES [ \
    ["ACRE_PRC343", "legacy"], \
    ["ACRE_PRC152", "handheld"], \
    ["ACRE_PRC148", "handheld"], \
    ["ACRE_PRC117F", "manpack"], \
    ["ACRE_PRC77", "manpack"] \
]
#define ACRE_PROFILE_DEFAULT "legacy"
#define NODE_ID_FORMAT "acre_%1_%2"
#define NET_DATA "DATA"
#define OWNER_TAG QUOTE(ADDON)
#define POLL_S 1

// THE PAC PLAN'S ACRE TIERS (what jmfsb_gear_fnc_setupRadios programs): the
// radio classes of each tier and its channel rows [channel (1-based), freq,
// label, (mW)]. A radio's net is the label of the channel it is on, in its
// tier; a channel with no label is "<TIER> CH <n>".
#define TIERS [ \
    ["sr", "jmfsbFR_radio_srRadios", "jmfsbFR_radio_srChannels"], \
    ["mr", "jmfsbFR_radio_mrRadios", "jmfsbFR_radio_mrChannels"], \
    ["lr", "jmfsbFR_radio_lrRadios", "jmfsbFR_radio_lrChannels"] \
]
#define TIER_LR "lr"
#define TIER_NONE "radio"
#define NET_FORMAT "%1 CH %2"
// The voice kinds (jmfsb_voice's contract): a plan net's own (PAC plan kind
// sr -> team, lr -> c2, a2g -> a2g), else long range c2 and the rest team.
#define PLAN_SR "sr"
#define PLAN_A2G "a2g"
#define KIND_TEAM "team"
#define KIND_C2 "c2"
#define KIND_A2G "a2g"
#define NO_CHANNEL -1

// ACRE's speaking type for a radio transmission (SPEAKING_TYPE_RADIO in
// ACRE2's main\script_macros.hpp).
#define ACRE_SPEAKING_RADIO 1

// Ear: ACRE's spatial zone of a radio <-> the voice API's ear.
#define ACRE_SPATIAL [["LEFT", "L"], ["CENTER", "B"], ["RIGHT", "R"]]
#define EAR_BOTH "B"
// Mute is the radio's volume at 0 (ACRE: 0..1); unmute puts back what it was,
// else full.
#define VOLUME_MUTED 0
#define VOLUME_FULL 1
// Quality is ACRE's own signal model's: the voice API's quality reads this.
#define QUALITY_FULL 1
