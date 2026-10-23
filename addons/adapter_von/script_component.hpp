#define COMPONENT adapter_von
#define COMPONENT_BEAUTIFIED VON Adapter
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_ADAPTER_VON
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_ADAPTER_VON
    #define DEBUG_SETTINGS DEBUG_SETTINGS_ADAPTER_VON
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// THE VON SEAM. The only place the game's VON commands are used for voice
// (radioChannel*, setCurrentChannel, enableChannel, getPlayerChannel,
// setPlayerVoNVolume). jmfsb_voice knows nets; this maps them onto channels.

// --- VON channels (docs/DESIGN_VOICE.md "Channels") -----------------------------
#define CH_NONE             -1
#define CH_GLOBAL           0
#define CH_SIDE             1
#define CH_COMMAND          2
#define CH_GROUP            3
#define CH_VEHICLE          4
#define CH_DIRECT           5
// A push-to-talk key that sends on the current channel.
#define CH_CURRENT          -2
// A custom channel id n (1..10) is VON channel CUSTOM_BASE + n.
#define CUSTOM_BASE         5
#define CUSTOM_MAX          10
#define CUSTOM_NONE         0
// radioChannelInfo's "exists" field.
#define CHANNEL_INFO_EXISTS 5

// Voice net ids and kinds (jmfsb_voice's contract, addons/voice/README.md).
#define NET_VEH             "VEH"
#define NET_DIRECT          "DIRECT"
#define KIND_TEAM           "team"
#define KIND_C2             "c2"
#define KIND_A2G            "a2g"
#define KIND_CALL           "call"
#define KIND_VEH            "veh"
#define KIND_DIRECT         "direct"
// An RTO's net (user, 2026-10-22: "allow rtos to add custom channels"): its
// own channel, keyed by its id like a CALL, kept for the mission.
#define KIND_CUSTOM         "custom"

// Custom channels by key: every C2-kind net shares the C2 channel (the
// listener's volume is worked out on the speaker's own net), every A2G-kind
// net shares the A2G channel the same way, each CALL n has its own. Made with radioChannelCreate: C2 and A2G at
// mission start, a CALL channel on its first call, then reused (VON cannot
// delete a custom channel; an ended call's channel is just emptied).
#define KEY_C2              "C2"
#define KEY_A2G             "A2G"
#define FIXED_KEYS          [KEY_C2, KEY_A2G]
#define CHANNEL_CALLSIGN    "%UNIT_NAME"
#define COLOR_C2            [0.9, 0.6, 0.2, 1]
#define COLOR_A2G           [0.3, 0.8, 0.9, 1]
#define COLOR_CALL          [0.9, 0.9, 0.9, 1]
#define COLOR_CUSTOM        [0.6, 0.9, 0.5, 1]

#define CHANNELS_TICK_S     1
// Our talking popup in the game's RscDisplayVoiceChat (FUNC(voiceChatLoad)):
// its control, refresh, colours, and the engine channels by number (0 Global,
// 1 Side, 2 Command, 3 Group, 4 Vehicle, 5 Direct) for a key that carries no
// net of ours.
#define IDC_VOICECHAT_TX    5501
#define VOICECHAT_TICK_S    0.1
#define VOICECHAT_BG        {0.125, 0.118, 0.114, 0.9}
#define VOICECHAT_DOT       "●"
#define VOICECHAT_DOT_HEX   "#ff563c"
#define VOICECHAT_CHANNEL_NAMES ["Global", "Side", "Command", "Group", "Vehicle", "Direct"]
#define ADMIN_NONE          0

// --- Push-to-talk -------------------------------------------------------------
// Every PTT input and the channel it sends on: the per-channel keys their own
// channel, Push To Talk and the VON toggle the current one. Read every frame
// with inputAction; the per-channel keys are checked first.
#define PTT_ACTIONS [ \
    ["PushToTalkAll", CH_GLOBAL], ["PushToTalkSide", CH_SIDE], \
    ["PushToTalkCommand", CH_COMMAND], ["PushToTalkGroup", CH_GROUP], \
    ["PushToTalkVehicle", CH_VEHICLE], ["PushToTalkDirect", CH_DIRECT], \
    ["pushToTalk", CH_CURRENT], ["voiceOverNet", CH_CURRENT] \
]
// The VON toggle (actionKeys) is swallowed on the mission display: an open
// mic would bypass the push-to-talk that the mesh, the sounds and the
// cut-offs follow. Push To Talk unbound or the VON volume (getAudioOptionVolumes
// [effects, music, radio, von, ...]) below VON_VOLUME_LOW: told once at start.
#define ACTION_TOGGLE       "VoiceOverNet"
#define ACTION_PTT          "PushToTalk"
#define DISPLAY_MISSION     46
#define VON_VOLUME_INDEX    3
#define VON_VOLUME_LOW      0.1
#define NOTE_TITLE          "VOICE"
#define NOTE_TOGGLE         "Voice Over Net (toggle) is blocked. Bind Push To Talk instead: Configure > Controls > Multiplayer."
#define NOTE_NO_PTT         "Push To Talk has no key. Bind one: Configure > Controls > Multiplayer."
#define NOTE_VON_LOW        "Your VON volume is near zero: Options > Audio."

// --- Cut-offs: the voice core's "block" levels (addons/voice/README.md) -----------
// 1 radio silence: Group and our custom channels closed; 2 unconscious: the
// Vehicle channel too; 3 dead or out of air: Direct too. Vehicle and Direct
// are otherwise the mission's: their voice state is kept and put back.
#define BLOCK_NONE          0
#define BLOCK_SILENCE       1
#define BLOCK_RADIO         2
#define BLOCK_ALL           3
#define CUT_CHANNELS        [[CH_VEHICLE, BLOCK_RADIO], [CH_DIRECT, BLOCK_ALL]]

// Volume: VON's per-listener volume of a speaker, 0..1.
#define VOLUME_FULL         1
#define VOLUME_MUTE         0
#define DEFAULT_VOLUME_FLOOR 0.3

// --- Self test ------------------------------------------------------------------
#define TEST_VOLUME         0.5
#define TEST_WINDOW_S       15
#define TEST_READD_S        3
#define MS_PER_S            1000
