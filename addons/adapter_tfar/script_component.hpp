#define COMPONENT adapter_tfar
#define COMPONENT_BEAUTIFIED TFAR Adapter
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_ADAPTER_TFAR
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_ADAPTER_TFAR
    #define DEBUG_SETTINGS DEBUG_SETTINGS_ADAPTER_TFAR
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// THE TFAR SEAM. This addon is the only place TFAR's functions are called for
// voice (docs/DESIGN_RF.md rule 1, docs/DESIGN_VOICE.md). It loads only with
// TFAR (skipWhenMissingDependencies) and then is jmfsb_voice's "tfar" adapter:
// VON stands down, and the core reads nets, net state, the active net, ear,
// mute, quality and talking from here.

// The voice adapter id, the same string jmfsb_voice_system holds under TFAR.
#define VOICE_ID "tfar"

// RADIO CLASS -> RF PROFILE: the profile the class names in config
// (jmfsb_rf_profile, jmfsb_rf_fnc_itemProfile); a TFAR set that names none is
// a handheld (short range) or a manpack (long range on the back - TFAR may
// have them; game voice may not, user 2026-10-21).
#define SR_PROFILE_DEFAULT "handheld"
#define LR_PROFILE_DEFAULT "manpack"
// Long range in a vehicle's rack: the vehicle's own set.
#define VEHICLE_PROFILE "vehicle"

// Node ids: one per player per set, stable across respawn.
#define NODE_SR "sr"
#define NODE_LR "lr"
#define NODE_VEH "veh"
#define NODE_ID_FORMAT "tfar_%1_%2"
#define OWNER_TAG QUOTE(ADDON)

// THE NET PLAN is PAC's (jmfsb_pac_fnc_netPlan: [id, band, "sr" | "lr" |
// "a2g", slot]); here each plan net gets the TFAR set kind that carries it and
// a channel on it. "sr" nets ride the handheld, "lr" and "a2g" nets the long
// range sets. A slotted net (the tfarNets plan) sits on its slot; an unslotted
// one (the VON plan) on the next free channel of its set kind, in plan order.
#define PLAN_SR "sr"
#define PLAN_LR "lr"
#define PLAN_A2G "a2g"
// The voice kinds (jmfsb_voice's contract) a plan kind and a set kind are.
#define KIND_TEAM "team"
#define KIND_C2 "c2"
#define KIND_A2G "a2g"
// RF's own data net, which every set is on.
#define NET_DATA "DATA"
// "No channel" in TFAR (no additional channel), and no voice channel in the
// voice API's nets rows.
#define NO_CHANNEL -1

// How often the client re-reads his radios.
#define POLL_S 1

// --- Voice override ---------------------------------------------------------
// TFAR's per-unit range levers, read by TFAR on the unit it plays as
// (TFAR_currentUnit): sending scales the set's range when the tangent goes
// down (TFAR_fnc_getTransmittingDistanceMultiplicator), receiving divides it
// in the plugin's FREQ update (fnc_sendFrequencyInfo: "smaller value ==
// bigger range"). 1 is TFAR's own range.
#define TF_SEND_VAR "tf_sendingDistanceMultiplicator"
#define TF_RECV_VAR "tf_receivingDistanceMultiplicator"
// A cut link is not range zero (TFAR has no "off"), it is this share of it:
// a few metres of a handheld, nothing at radio distance.
#define VOICE_CUT_FACTOR 0.001
// RF's "does not know" (jmfsb_rf_fnc_quality).
#define QUALITY_UNKNOWN -1
#define QUALITY_FULL 1
// Setting defaults: quality at or below which voice is cut (0 = RF's own
// threshold, SNR under it), and the share of range left at the lowest quality
// above the cut.
#define DEFAULT_VOICE_CUT 0
#define DEFAULT_VOICE_FLOOR 0.25
// TFAR's radio type in OnTangent / OnBeforeTangent: 0 short range, 1 long.
#define TFAR_TYPE_SR 0
// The id this adapter's TFAR event handlers are registered under.
#define TFAR_EH_ID QUOTE(ADDON)

// --- Ear and mute (the voice API's setEar / setMute) -------------------------
// TFAR's stereo setting: 0 both, 1 left, 2 right - the voice API's ears.
#define TFAR_STEREO_EARS ["B", "L", "R"]
#define EAR_BOTH "B"
// Mute is the set's volume at 0 (TFAR has one volume per set, so it mutes
// both its nets); unmute puts back what it was, else this (TFAR's 0..10).
#define VOLUME_MUTED 0
#define VOLUME_DEFAULT 7

// --- TFAR's own radio UI ----------------------------------------------------
// TFAR's client settings that put its radio popups on screen, overridden for
// the session while "Hide TFAR's radio UI" is on (fnc_tfarUi). Both are read by
// TFAR at the moment it would show the hint:
//   TFAR_showTransmittingHint   - the "transmitting on ch n, freq" popup
//                                 (core/functions/fnc_doSRTransmit.sqf, doLRTransmit,
//                                 and their End: hint time 0 = no hint)
//   TFAR_showChannelChangedHint - the radio/channel/frequency card on a channel
//                                 key or dialog change
//                                 (events/keys/fnc_processSWChannelKeys.sqf,
//                                 events/ui/fnc_setChannelViaDialog.sqf)
#define TFAR_UI_SETTINGS ["TFAR_showTransmittingHint", "TFAR_showChannelChangedHint"]
// TFAR events after which TFAR draws the radio card with no setting asking
// (cycling radios, the speaker and additional-channel buttons of its own
// dialogs): the card is taken down a frame later with TFAR_fnc_hideHint.
#define TFAR_UI_EVENTS ["OnSWChange", "OnLRChange", "OnSWchannelSet", "OnLRchannelSet", "OnSWspeakersSet", "OnLRspeakersSet"]

// --- Our PTT ----------------------------------------------------------------
#include "\a3\ui_f\hpp\definedikcodes.inc"
// [our action, TFAR's own keybind it stands in for, name, TFAR's default key].
// Ours is UNBOUND by default; it takes TFAR's default key only when TFAR's own
// keybind for the same tangent has no key, so one key never keys twice. The
// defaults are TFAR's (core/functions/fnc_initKeybinds.sqf, CBA order
// [shift, ctrl, alt]).
#define PTT_SR "sr"
#define PTT_SR_ALT "srAlt"
#define PTT_LR "lr"
#define PTT_LR_ALT "lrAlt"
#define NO_KEY [0, [false, false, false]]
#define PTT_KEYS [ \
    [PTT_SR, "SWTransmit", "Radio: transmit on the active net", [DIK_CAPSLOCK, [false, false, false]]], \
    [PTT_SR_ALT, "SWTransmitAdditional", "Radio: transmit on the alternate net", [DIK_T, [false, false, false]]], \
    [PTT_LR, "LRTransmit", "Radio: transmit on the long range net", [DIK_CAPSLOCK, [false, true, false]]], \
    [PTT_LR_ALT, "LRTransmitAdditional", "Radio: transmit on the long range alternate net", [DIK_T, [false, true, false]]] \
]
// Net up / down on the active set ("cycle the fill"), unbound by default.
#define NET_STEP_KEYS [ \
    [NODE_SR, 1, "netNextSr", "Radio: next net"], \
    [NODE_SR, -1, "netPrevSr", "Radio: previous net"], \
    [NODE_LR, 1, "netNextLr", "Radio: next long range net"], \
    [NODE_LR, -1, "netPrevLr", "Radio: previous long range net"] \
]

// --- Nets over frequencies ----------------------------------------------------
// TFAR's channel counts and frequency bands (core/defines.hpp:
// TFAR_MAX_CHANNELS, TFAR_MIN/MAX_SW_FREQ, TFAR_MAX_LR_CHANNELS,
// TFAR_MIN/MAX_ASIP_FREQ, TFAR_FREQ_ROUND_POWER).
#define SR_CHANNELS 8
#define LR_CHANNELS 9
#define SR_FREQ_MIN 30
#define SR_FREQ_MAX 512
#define LR_FREQ_MIN 30
#define LR_FREQ_MAX 87
#define FREQ_STEPS 10
// A frequency STRING as a whole number of 0.1 MHz steps, so "51.1", "51.10"
// and "51,1" compare equal (TFAR's own TFAR_FREQUENCYSTRING_TO_FREQNUMBER).
#define FREQ_KEY(freq) (round (parseNumber (((freq) splitString ",.") joinString ".") * FREQ_STEPS))
// A net with no frequency in the plan gets one from its id: a string hash
// (kept under 2^24 so float maths stays exact), one 0.1 MHz slot in the band.
#define HASH_MOD 65521
#define HASH_MUL 31
// The name a channel no plan net holds is hashed from (fnc_sideDefaults).
#define CHANNEL_NAME_FORMAT "%1 CH %2"
// The PAC plan's TFAR frequency lists, one entry per channel (kept in the
// database for this; DIVINER and the website write them).
#define PLAN_SR_FREQS "jmfsbFR_radio_tfarSrFreqs"
#define PLAN_LR_FREQS "jmfsbFR_radio_tfarLrFreqs"
// TFAR's side default frequency lists, read by its client init when it issues
// a radio (core/functions/fnc_ClientInit.sqf), per band and side.
#define TFAR_DEFAULTS_SR ["TFAR_defaultFrequencies_sr_west", "TFAR_defaultFrequencies_sr_east", "TFAR_defaultFrequencies_sr_independent"]
#define TFAR_DEFAULTS_LR ["TFAR_defaultFrequencies_lr_west", "TFAR_defaultFrequencies_lr_east", "TFAR_defaultFrequencies_lr_independent"]
