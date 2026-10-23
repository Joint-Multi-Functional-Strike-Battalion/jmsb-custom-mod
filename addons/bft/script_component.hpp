#define COMPONENT bft
#define COMPONENT_BEAUTIFIED BFT
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_BFT
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_BFT
    #define DEBUG_SETTINGS DEBUG_SETTINGS_BFT
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// THE MEMBER ICON (docs/DESIGN_BFT_MEMBERS.md): three textures in data/, one
// size for all of them - the ring is the outer edge of the same 128 px canvas.
#define MEMBER_SIZE 24
#define MEMBER_TEXT_SIZE 0.035
#define MEMBER_NUMBER_TEXT_SIZE 0.026 // the number inside the circle, smaller than the name (user, 2026-10-23)
#define MEMBER_BODY QPATHTOF(data\member_body_ca.paa)
#define MEMBER_OUTLINE QPATHTOF(data\member_outline_ca.paa)
#define MEMBER_RING QPATHTOF(data\member_ring_ca.paa)
#define MEMBER_BLANK "#(argb,8,8,3)color(0,0,0,0)"
#define MEMBER_OUTLINE_RGBA [0.13, 0.12, 0.11, 1]
#define MEMBER_DOWN_ALPHA 0.5
// Who is talking, as FUNC(draw) records it: nothing, direct voice, a radio net.
#define VOICE_NONE 0
#define VOICE_DIRECT 1
#define VOICE_RADIO 2
// jmfsb_voice's net kind for direct speech, and the engine's Direct VON channel.
#define VOICE_KIND_DIRECT "direct"
#define VON_CHANNEL_DIRECT 5
#define RING_RADIO [0.90, 0.15, 0.15, 1]
#define RING_DIRECT [0.85, 0.20, 0.85, 1]

// GPS (jmfsb_ew_fnc_gpsOf, read only when jmfsb_ew is loaded): a man is drawn
// where his GPS says he is. Denied: no dot. Suspect: flagged on your own dot.
#define GPS_STATE_NOFIX "NO FIX"
#define GPS_STATE_SUSPECT "SUSPECT"
#define GPS_SUSPECT_TAG " - GPS SUSPECT"
