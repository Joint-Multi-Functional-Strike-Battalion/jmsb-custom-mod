#define COMPONENT adapter_livekit
#define COMPONENT_BEAUTIFIED LiveKit Adapter
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_ADAPTER_LIVEKIT
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_ADAPTER_LIVEKIT
    #define DEBUG_SETTINGS DEBUG_SETTINGS_ADAPTER_LIVEKIT
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// THE LIVEKIT SEAM. The only addon that calls the jmsb_voice extension
// (extensions/jmsb_voice, docs/DESIGN_VOICE_LIVEKIT.md): jmsb_voice_x64.dll
// on players, jmsb_voice_x64.so (tokens only) on a Linux server.
#define VOICE_EXT           "jmsb_voice"
// callExtension's [result, returnCode, errorCode]: 0 and 0 when it ran.
#define VOICE_EXT_OK        0
// The mission display: its Unload is the mission's end on this machine.
#define IDD_MISSION         46

// --- The echo test (docs/DESIGN_VOICE_LIVEKIT.md "Echo test") ------------------
// Each caller his own room, this then his UID; the voice server's echo bot
// answers every room so named (pelican-eggs livekit-voice/echobot ROOM_PREFIX).
#define ECHO_ROOM_PREFIX    "echo-"
// The bot's identity in the room.
#define ECHO_BOT            "echo"
// States. "" is no extension: the echo test is not offered.
#define ECHO_NONE           ""
#define ECHO_IDLE           "idle"
#define ECHO_JOINING        "joining"
#define ECHO_LIVE           "live"
// The bot must answer within this (s); the test ends itself after ECHO_MAX_S,
// so a forgotten one does not keep the microphone open.
#define ECHO_ANSWER_S       15
#define ECHO_MAX_S          180
#define ECHO_TICK_S         0.5
#define ECHO_TITLE          "ECHO TEST"

// --- The voice adapter "livekit" (2026-10-31: LiveKit IS the voice) -----------
// Registered with jmfsb_voice under this id; the system chosen wherever the
// extension answers (jmfsb_voice_fnc_selectSystem, Automatic).
#define ADAPTER_ID          "livekit"
#define VOICE_SYSTEM_AUTO   "auto"
#define VOICE_TITLE         "VOICE"
// THE ROOM: one per mission start, named and published by the server.
#define ROOM_PREFIX         "mission-"
#define ROOM_ID_MAX         1000000
// This machine's place in it.
#define ROOM_NONE           ""
#define ROOM_IDLE           "idle"
#define ROOM_JOINING        "joining"
#define ROOM_LIVE           "live"
// A token or a join not answered within this (s) is asked again; a drop by
// the server is rejoined after ROOM_RETRY_S; a join that fails is tried again
// after ROOM_RETRY_S, doubling each time up to ROOM_RETRY_SLOW_S, and said
// once until it works; a server that cannot sign us in (no address, key or
// secret set) is asked again after ROOM_RETRY_SLOW_S.
#define ROOM_ANSWER_S       15
// Once the extension is connecting, it gives up itself after 15 s - after it
// opened the audio devices - and reports the error. The tick waits longer than
// that (2026-11-05: at 15 s a fresh connect overtook the failing one and its
// error was lost), and says once that the voice server does not answer.
#define ROOM_CONNECT_S      40
#define NO_ANSWER_TEXT      "Voice: the voice server does not answer (address, port or firewall). Trying again."
#define ROOM_RETRY_S        10
#define ROOM_RETRY_SLOW_S   60
#define DROP_BY_US          "ClientInitiated"
// SERVER: one token per machine per this many seconds; more are dropped.
#define TOKEN_MIN_S         2
// The token's key and secret: the CBA settings when set, else the server's
// environment (the extension reads JMSB_LIVEKIT_KEY / JMSB_LIVEKIT_SECRET when
// passed empty - CBA copies every server setting to every client, so the
// secret belongs there, review S9 / R4). The extension's error when neither
// has them holds NOT_SET_MARK; the client is then told NOT_SET_TEXT.
#define NOT_SET_MARK        "not set"
#define NOT_SET_TEXT        "the voice server's API key or secret is not set (the server's JMSB_LIVEKIT_KEY / JMSB_LIVEKIT_SECRET, or CBA: JMSB - Voice (Built-in))"
#define NO_URL_TEXT         "the voice server's address is not set (CBA: JMSB - Voice (Built-in))"

// --- WHICH VOICE SERVER (2026-11-01): LiveKit or Mumble ------------------------
// The voice core's one setting (jmfsb_voice_defaultSystem, user 2026-11-01):
// LiveKit and Mumble are themselves; Automatic is Mumble when its address is
// set, else LiveKit when its address is set, else none - the game VON then
// carries the mission (FUNC(srvServerKind), 2026-11-05). The
// extension runs both, picked by the address it is given: ws/wss for LiveKit,
// MUMBLE_URL_FORMAT for Mumble - his UID as the Mumble user name, the room as a
// channel, the server's password as the token. The echo test on Mumble is the
// server's own loopback (MUMBLE_ECHO_FORMAT).
#define SERVER_LIVEKIT      "livekit"
#define SERVER_MUMBLE       "mumble"
#define SERVER_NONE         ""
#define MUMBLE_URL_FORMAT   "mumble://%1@%2/%3"
#define MUMBLE_ECHO_FORMAT  "mumble://%1@%2?echo"
#define NO_MUMBLE_TEXT      "the Mumble server's address is not set (CBA: JMSB - Voice (Built-in))"
#define NO_EXT_TEXT         "the voice extension is not loaded on the server"
// THE MIX: every speaker's gain and ear, re-asked this often and sent to the
// extension when the gain moved by GAIN_EPS or the ear by PAN_EPS (the ear
// moves with every turn of the head, so a coarser step).
#define TICK_S              0.2
#define GAIN_EPS            0.02
#define PAN_EPS             0.1
// WHO IS RECEIVED AT ALL (auto-subscribe is off in the extension): a speaker
// is subscribed while he could be heard - on a net the listener is on (by the
// server's roster), in the same vehicle, or within the local voice range
// times this - so his first words are not lost to the subscription.
#define SUBSCRIBE_RANGE_FACTOR 1.5
// GAME VON OFF (no in-game VON under LiveKit): every game channel's voice,
// 0-5 and the custom 6-15, re-checked this often (a respawn or a mission
// script may turn one back on).
#define VON_CHANNELS_MAX    15
#define VON_OFF_TICK_S      1
#define SYSTEM_NONE         "none"
// LOCAL VOICE, over the server too (no game VON): full in the same vehicle,
// else falling with distance to the range (the CBA setting) by this power;
// the ear from where he stands (right of you: the right ear).
#define LOCAL_CURVE         2
#define LOCAL_RANGE_DEFAULT 50
#define LOCAL_RANGE_MIN     5
#define LOCAL_RANGE_MAX     200
// The net id of local voice: none - the voice core keys no net for it.
#define LOCAL_NET           ""
// The voice core's cut-off levels (addons/voice BLOCK_*): none, radio
// silence (radio nets closed), unconscious (radio and intercom closed), dead
// or out of air (local too).
#define BLOCK_NONE          0
#define BLOCK_SILENCE       1
#define BLOCK_RADIO         2
#define BLOCK_ALL           3
// THE TALK KEYS, as the game VON adapter's: Caps Lock with a modifier each
// (user, 2026-10-30), PTT 1 the active net, Shift + Caps Lock local.
#define PTT_DEFAULT_KEYS    [DIK_CAPITAL, DIK_CAPITAL, DIK_CAPITAL, DIK_CAPITAL]
#define PTT_DEFAULT_MODS    [[false, false, false], [false, true, false], [false, false, true], [true, true, false]]
#define PTT_DEFAULT_NAMES   ["Caps Lock", "Ctrl + Caps Lock", "Alt + Caps Lock", "Shift + Ctrl + Caps Lock"]
#define PTT_ACTIVE_KEY      1
#define LOCAL_DEFAULT_KEY   DIK_CAPITAL
#define LOCAL_DEFAULT_MODS  [true, false, false]
#define LOCAL_DEFAULT_NAME  "Shift + Caps Lock"
#define HOLD_PTT            "ptt"
#define HOLD_LOCAL          "local"
