#define COMPONENT voice
#define COMPONENT_BEAUTIFIED Voice
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_VOICE
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_VOICE
    #define DEBUG_SETTINGS DEBUG_SETTINGS_VOICE
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// VOICE (docs/DESIGN_VOICE.md). RF decides who hears whom; the voice adapter
// (adapter_von by default) carries the audio. This addon never names a VON
// command: everything engine-specific goes through the adapter's hooks.

// --- Which system carries the voice (user, 2026-10-20) ---------------------------
// Our game VoIP (VON) runs only when no radio mod is loaded. With TFAR or ACRE
// in CfgPatches jmfsb_voice_system is "tfar" / "acre" on that machine,
// jmfsb_voice_active ("VON is running") is false, and neither this addon nor
// adapter_von sets up anything of VON. The core then runs in EXTERNAL-RADIO
// mode: nets, net state, the active net, ear / mute, quality and talking come
// from that radio's adapter (adapter_tfar / adapter_acre); calls, callbacks,
// contacts and our sounds are VON-only and answer empty.
#define SYSTEM_VON          "von"
#define SYSTEM_TFAR         "tfar"
#define SYSTEM_ACRE         "acre"
#define TFAR_PATCHES        ["task_force_radio", "tfar_core"]
#define ACRE_PATCHES        ["acre_main"]
#define OTHER_VOICE_MODS    (TFAR_PATCHES + ACRE_PATCHES)

// --- Adapter hooks ----------------------------------------------------------
#define DEFAULT_ADAPTER     SYSTEM_VON
#define HOOKS_REQUIRED      ["join", "leave", "quality", "talking"]
// An external radio's adapter (id "tfar" / "acre", taken only while that
// system is the one loaded) has no join / leave: the radio's own channels are
// its membership. Required: "nets" [] -> [[net, name, kind, -1], ...] (the
// local player's), "netState" [] -> [[net, name, kind, active, muted, ear,
// reachable], ...], "talking" [] -> [[unit, net], ...] (others). Optional:
// "current", "setActive", "ptt", "setEar" [net, ear] -> bool, "setMute"
// [net, muted] -> bool, "linkQuality" [speaker, net] -> 0..1, "selfTest".
#define HOOKS_REQUIRED_EXTERNAL ["nets", "netState", "talking"]
// External-radio mode: talking is read this often, the nets every CLIENT_TICK_S.
#define EXTERNAL_TICK_S     0.1
#define QUALITY_FULL        1
// An external "netState" row is netState's own row less its talkers column.
#define EXTERNAL_STATE_COLS 7
// Optional hooks: "channel" [net] -> voice channel number (-1 none),
// "setActive" [net] -> bool, "current" [] -> net id, "block" [level],
// "ptt" [] -> [down, net] (the local player's own key, every frame),
// "keyed" [unit, net, on] (a remote speaker keyed / unkeyed, pushed by him),
// "audience" [unit, net] -> units (who the backend lets hear him on it).
#define HOOK(name)          (GVAR(adapter) getOrDefault [name, {}])
#define NO_CHANNEL          -1

// --- Who may transmit (the "block" hook's level) -------------------------------
// Each level includes the ones below it. Radio silence (EMCON 3) closes the
// radio nets (Group and the custom channels); unconscious closes every radio,
// the Vehicle intercom too; dead or out of air closes Direct as well.
#define BLOCK_NONE          0
#define BLOCK_SILENCE       1
#define BLOCK_RADIO         2
#define BLOCK_ALL           3
// A net no level closes (Global, or not one of ours).
#define BLOCK_NEVER         4
#define LIFE_INCAPACITATED  "INCAPACITATED"
#define BLOCK_TITLE         "RADIO"
#define REASON_SILENCE      "Radio silence (EMCON 3)."
#define REASON_UNCONSCIOUS  "Unconscious: no radio."
#define REASON_DEAD         "Dead: no voice."
#define REASON_NO_AIR       "No air: you cannot talk."
#define REASON_NO_SET       "No radio set for %1."
// The leaders' GLOBAL button (FUNC(global)).
#define GLOBAL_TITLE        "GLOBAL"
#define GLOBAL_REFUSED      "Global is for TLs, ATLs, HHC and admins."

// --- Nets -------------------------------------------------------------------
// Net ids. C2 / A2G / DATA are RF nets; a TEAM net is one per Arma group;
// CALL n is call slot n (its RF quality is DATA's: a call rides the data net).
#define NET_C2              "C2"
#define NET_A2G             "A2G"
#define NET_DATA            "DATA"
#define NET_VEH             "VEH"
#define NET_DIRECT          "DIRECT"
#define TEAM_PREFIX         "TEAM "
#define TEAM_FORMAT         "TEAM %1 %2"
#define CALL_PREFIX         "CALL "
#define CALL_FORMAT         "CALL %1"
// The nets the server makes in RF at start (docs/DESIGN_RF.md "Nets"), and
// the band of every TEAM net.
#define FIXED_NETS          [[NET_C2, "VHF"], [NET_A2G, "UHF"]]
#define NET_BAND_TEAM       "VHF"
// The fill (DESIGN_RF.md: rifleman and leader get TEAM, C2, A2G): his TEAM
// net, C2-kind net and A2G-kind net (from the PAC plan when it has them), and
// this - RF's own DATA, which every set is on.
#define FILL_FIXED          [NET_DATA]
#define NET_SOURCE          "voice default plan"

// --- The PAC net plan (jmfsb_pac_fnc_netPlan) ---------------------------------
// A plan net is [id, band, kind "sr" | "lr" | "a2g", slot]. A squad's net of
// a kind comes from jmfsb_pac_fnc_netPlanSquad (the VON plan and the old
// tfarNets slots alike); without it, from the tfarNets rows [squad name,
// short range slot, long range slot] and the fallback slots, under the keys
// pac keeps them in. VON nets have no slot (PLAN_NO_SLOT).
#define PLAN_SR             "sr"
#define PLAN_LR             "lr"
#define PLAN_A2G            "a2g"
#define PLAN_NO_SLOT        -1
// An RTO net's row (FUNC(planRefresh) adds one per published net): its own
// kind, and a slot of its own so FUNC(canGlobal)'s "a slotless row means a
// VON plan" test is not fooled by one.
#define PLAN_CUSTOM         "custom"
#define PLAN_CUSTOM_SLOT    -2
#define PLAN_ROWS_VAR       "jmfsbFR_radio_tfarNets"
#define PLAN_COL_SR         1
#define PLAN_COL_LR         2
#define PLAN_FALLBACK_SR    "jmfsbFR_radio_tfarSwFallback"
#define PLAN_FALLBACK_LR    "jmfsbFR_radio_tfarLrFallback"

#define KIND_TEAM           "team"
// How long after a role pick or a respawn FUNC(checkActive) keeps looking for
// a TEAM net to land him on (FUNC(toTeam)): the roster is a second behind.
#define TEAM_WAIT_S 30
#define KIND_C2             "c2"
#define KIND_A2G            "a2g"
#define KIND_VEH            "veh"
#define KIND_CALL           "call"
#define KIND_DIRECT         "direct"
// An RTO's own net (see RTO nets below).
#define KIND_CUSTOM         "custom"
// Kinds whose voice goes through the mesh (and gets radio sounds).
#define MESH_KINDS          [KIND_TEAM, KIND_C2, KIND_A2G, KIND_CALL, KIND_CUSTOM]

#define EAR_LEFT            "L"
#define EAR_BOTH            "B"
#define EAR_RIGHT           "R"
#define EARS                [EAR_LEFT, EAR_BOTH, EAR_RIGHT]

// --- Sets the player carries -> RF nodes -------------------------------------
// Node id per player per set, stable across respawn: voice_<uid>_<kind>.
#define NODE_FORMAT         "voice_%1_%2"
#define NODE_SR             "sr"
#define NODE_LR             "lr"
#define NODE_VEH            "veh"
#define NODE_KINDS          [NODE_SR, NODE_LR, NODE_VEH]
#define OWNER_TAG           QUOTE(ADDON)
// The sets on a man are RF's to recognise (jmfsb_rf_fnc_carriedSets); a crew
// seat in a vehicle is the vehicle's set.
#define VEHICLE_PROFILE     "vehicle"
#define VEHICLE_KINDS       ["LandVehicle", "Air", "Ship"]
// A2G IS PILOTS (fnc_airSeat, user 2026-10-20): the driver of an Air vehicle
// or a man in one of its copilot turrets. A parachute is Air too and is not.
#define AIR_KIND            "Air"
#define PARACHUTE_KIND      "ParachuteBase"
#define SEAT_EVENTS         ["GetInMan", "GetOutMan", "SeatSwitchedMan"]
#define ROLE_CARGO          "cargo"

// --- Ticks ------------------------------------------------------------------
#define CLIENT_TICK_S       1
#define SERVER_TICK_S       1
#define RING_PERIOD_S       2
// RF EMCON level that is radio silence (receive only).
#define EMCON_SILENT        3

// --- Calls ------------------------------------------------------------------
// VON: one custom channel per call; ten custom channels, two are C2 / A2G.
#define CALL_SLOTS          8
#define CALL_MAX_MEMBERS    8
// A call is live from two members, and ends when one is left.
#define CALL_MIN_MEMBERS    2
#define PRIO_ROUTINE        "ROUTINE"
#define PRIO_FLASH          "FLASH"
#define STATE_RINGING       "ringing"
#define STATE_LIVE          "live"
#define STATE_OUTGOING      "outgoing"
#define STATE_ENDED         "ended"
#define STATE_WARNING       "warning"
#define REASON_NO_ROUTE     "noRoute"
#define REASON_BUSY         "busy"
#define REASON_NO_ANSWER    "noAnswer"
#define REASON_DECLINED     "declined"
#define REASON_BUMPED       "bumped"
#define REASON_DROPPED      "dropped"
#define REASON_REFUSED      "refused"
// Only the call's owner - who started it - invites people (user, 2026-10-20).
#define REASON_NOT_OWNER    "notOwner"
#define CB_WAITING          "waiting"
#define CB_HELD             "held"
#define SECONDS_PER_MINUTE  60
// Role tags (contacts, group adds).
#define TAG_SL              "SL"
#define TAG_RTO             "RTO"
#define TAG_MEDIC           "MEDIC"
#define TAG_HQ              "HQ"
// THE RTO TEST (fnc_isRto; the RTO console is a player job, user 2026-10-20):
// the flag a PAC skill effect or the mission sets on him, and the whole words
// of a slot's role description that name a radio job.
#define RTO_FLAG            "isRTO"
#define RTO_WORDS           ["RTO", "RADIO", "JTAC", "FAC"]
#define ROLE_WORD_SPLIT     " -_/.,()"
#define ROLE_GROUP_MARK     "@"
#define HQ_WORDS            ["HQ", "COMMAND", "CROSSROADS"]
// The flag jmfsb_common sets on a logged-in admin's unit - with isRto, who
// may make RTO nets on a client (FUNC(canManageNets)); the server re-checks
// with FUNC(canFlash).
#define ADMIN_FLAG          "jmfsb_common_isAdmin"

// --- RTO nets (user, 2026-10-22: "add an rto skill or trait, and on the
// radio app allow rtos to add custom channels") ------------------------------
// A net an RTO (or admin) makes in the mission: the server keeps them
// (GVAR(customNets), id -> [name, squads, uids, owner uid, owner name]) and
// publishes them as jmfsb_voice_customPub rows [id, name, squads, uids, owner
// uid, owner name]; every machine's FUNC(planRefresh) folds the rows into the
// plan as kind custom, so chips, mesh, RF and the roster treat one like C2.
// Each has its own VON custom channel for the rest of the mission (the
// adapter's "reserve" hook), so the calls get what is left of the ten.
#define CUSTOM_COL_ID       0
#define CUSTOM_COL_NAME     1
#define CUSTOM_COL_SQUADS   2
#define CUSTOM_COL_UIDS     3
#define CUSTOM_COL_OWNER    4
#define CUSTOM_COL_OWNER_NAME 5
// The id IS the name, upper-cased and trimmed - what the chip shows.
#define CUSTOM_NAME_MIN     2
#define CUSTOM_NAME_MAX     10
#define CUSTOM_NAME_CHARS   "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -"
// Names the fixed nets, the engine channels and the id prefixes already own.
#define CUSTOM_RESERVED     [NET_C2, NET_A2G, NET_VEH, NET_DIRECT, NET_DATA, "GLOBAL"]
#define CUSTOM_RESERVED_PREFIXES [TEAM_PREFIX, CALL_PREFIX]
#define DEFAULT_CUSTOM_NETS_MAX 2
#define CUSTOM_NETS_MAX_CAP 6
// Why the server refused (FUNC(netFailed) says it in words).
#define REASON_NOT_RTO      "notRto"
#define REASON_BAD_NAME     "badName"
#define REASON_TAKEN        "taken"
#define REASON_FULL         "full"
#define REASON_NO_CHANNEL   "noChannel"
#define REASON_UNKNOWN      "unknown"
#define ADMIN_NONE          0

// --- Sounds -----------------------------------------------------------------
// [cue id, family, file]: family "radio" obeys Radio beeps, "call" Call beeps.
// The radio's squelch, its noise and the TX / roger / cut clicks are the
// game's own radio sounds (they ship with Arma 3); the rest are our tones,
// sounds\<cue>.wav made by tools/voice_sounds.py (file "" = ours). Played by
// file path: playSoundUI for both ears, playSound3D for one.
#define CUE_RADIO           "radio"
#define CUE_CALL            "call"
#define FILE_OWN            ""
#define FILE_SQUELCH_OPEN   "A3\Dubbing_Radio_F\sfx\in2a.ogg"
#define FILE_SQUELCH_TAIL   "A3\Dubbing_Radio_F\sfx\out2a.ogg"
#define FILE_TX_OPEN        "A3\Dubbing_Radio_F\sfx\in2b.ogg"
#define FILE_TX_TAIL        "A3\Dubbing_Radio_F\sfx\out2b.ogg"
#define FILE_CUT            "A3\Dubbing_Radio_F\sfx\out2c.ogg"
#define FILE_NOISE          "A3\Dubbing_Radio_F\sfx\radionoise1.ogg"
#define CUES [ \
    ["txChirp", CUE_RADIO, FILE_TX_OPEN], ["rogerBeep", CUE_RADIO, FILE_TX_TAIL], \
    ["squelchOpen", CUE_RADIO, FILE_SQUELCH_OPEN], ["squelchTail", CUE_RADIO, FILE_SQUELCH_TAIL], \
    ["static", CUE_RADIO, FILE_NOISE], ["cutTone", CUE_RADIO, FILE_CUT], \
    ["netSwitch", CUE_RADIO, FILE_OWN], ["blocked", CUE_RADIO, FILE_OWN], \
    ["dialTone", CUE_CALL, FILE_OWN], ["ringback", CUE_CALL, FILE_OWN], ["ring", CUE_CALL, FILE_OWN], \
    ["busy", CUE_CALL, FILE_OWN], ["connect", CUE_CALL, FILE_OWN], ["hangUp", CUE_CALL, FILE_OWN], \
    ["joinChime", CUE_CALL, FILE_OWN], ["priorityWarning", CUE_CALL, FILE_OWN] \
]
#define SOUND_EXT           ".wav"
// playSound3D takes an addon path with no leading backslash.
#define SOUND_DIR           (QPATHTOF(sounds) select [1])
#define NO_SOUND            -1
// Pitch per net (docs/DESIGN_VOICE.md "Sounds"): C2 low, TEAM mid, A2G high,
// CALL two-tone (its second tone after TWO_TONE_GAP_S).
#define PITCH_C2            0.8
#define PITCH_TEAM          1
#define PITCH_A2G           1.25
#define PITCH_CALL_LOW      1
#define PITCH_CALL_HIGH     1.25
#define PITCH_FLAT          1
#define TWO_TONE_GAP_S      0.12
// Ear panning: a beep for the left / right ear is played this far to that
// side of the camera, heard out to EAR_RANGE_M.
#define EAR_OFFSET_M        1.5
#define EAR_RANGE_M         10
// Static: the game's radio noise (radionoise1.ogg, 5.7 s), started under an
// audible speaker at (1 - quality) of the beep volume, played again just
// before it runs out (STATIC_CLIP_S) or when his quality changes, stopped
// when he stops.
#define STATIC_CLIP_S       5.5

// --- Defaults of the settings ------------------------------------------------
#define DEFAULT_GRACE_S         3
#define DEFAULT_RING_S          20
#define DEFAULT_CALL_DROP_S     10
#define DEFAULT_CB_EXPIRE_MIN   15
#define DEFAULT_CB_PER_PLAYER   3
#define DEFAULT_BUMP_WARN_S     3
#define DEFAULT_BEEP_VOLUME     1
#define MAX_BEEP_VOLUME         2
