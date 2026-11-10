#define COMPONENT reaction
#define COMPONENT_BEAUTIFIED Reaction
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_REACTION
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_REACTION
    #define DEBUG_SETTINGS DEBUG_SETTINGS_REACTION
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"
// NOTE_* levels for the notify addon's post event (see XEH_postInit), mirrored
// from diag/roomba_macros.hpp - including that whole header here redefines a
// logging macro this addon already carries with a different arity.
#define NOTE_INFO [ARR_4(0.871,0.361,0.188,1)]
#define NOTE_GOOD [ARR_4(0.400,0.702,0.400,1)]
#define NOTE_WARN [ARR_4(1,0.776,0.102,1)]
#define NOTE_BAD  [ARR_4(0.831,0.267,0.267,1)]

// A SMALL flag trebles the next roll, and forgets after this long. Long
// enough that a retry straight away is a real gamble, short enough that a
// section which broke contact and waited is genuinely clean again.
// THE TOWN TALKS. Detection is scaled by the nearest settlement's hostility
// to the player's side, read off ALiVE's civilian model: at 0 hostility the
// roll is halved, at 50 unchanged, at 100 one and a half times - a town that
// hates you reports you.
#define REACT_HOSTILITY_FLOOR 0.5
// "The enemy has your position": how often the commander's own knowledge is
// checked against the players, how close a report has to be to count, and
// how long a group is left alone after being told.
#define REACT_SPOTTED_TICK     30
#define REACT_SPOTTED_RANGE    300
#define REACT_SPOTTED_COOLDOWN 300
// Without ALiVE (user, 2026-11-02): how well a hostile side must know a man
// (knowsAbout, 0-4) before he is told it has his position, and below which a
// side counts as hostile.
#define REACT_SPOTTED_KNOWS    3
#define REACT_HOSTILE_BELOW    0.6
#define REACT_FLAG_MULT     3
#define REACT_FLAG_DECAY    300

// MAJOR: who learns where you are.
#define REACT_REVEAL_MIN    300
#define REACT_REVEAL_MAX    1000

// One MAJOR per player per this long. Five failed retries are one discovery,
// not five fire missions.
#define REACT_MAJOR_COOLDOWN 120

// The shells, when the commander's own guns cannot be reached.
// COUNTER-BATTERY (fnc_cbShot / cbFire): the shell of the virtual answer and
// the gap between its rounds, and how far round the fixed guns their crew are
// warned.
#define CB_AMMO             "Sh_155mm_AMOS"
#define CB_GAP              3
#define CB_WARN_RADIUS      150
// A virtual barrage's battery (fnc_cbVirtual): placed this far from where it
// lands, inside the map, and reused for any barrage within its reach - so a
// fix means the same battery next time.
#define CB_SITE_MIN         3000
#define CB_SITE_MAX         7000
#define CB_SITE_REACH       9000
#define CB_SITE_EDGE        200
#define CB_SITE_TRIES       8
// What the radar calls a gun it cannot name (a virtual battery).
#define CB_WHAT_DEFAULT     "artillery"
// The radar's reports to the players' artillery team (fnc_cbRadar): the call
// sign they are filed under, and how often one gun may fire before its own
// machine asks again (the server has its own per-gun cooldown).
#define CB_RADAR_CALLSIGN   "CB RADAR"
#define CB_RADAR_LOCAL_GAP  10
#define REACT_FALLBACK_AMMO "Sh_82mm_AMOS"
#define REACT_FALLBACK_DISP 60
#define REACT_FALLBACK_GAP  4

// The jamming calculator takes transmit power in milliwatts.
#define REACT_MW_PER_WATT   1000
// A game-voice key-up beyond the squad: no per-set power, taken as this many
// watts (fnc_onTransmit).
#define REACT_VOICE_WATTS   5

// How smothered the ground has to be before keying up counts as punching
// THROUGH something rather than just talking in a noisy place. Same number
// as jamming's JAM_DENIED_BAND and messaging's DENIED - a field the handset
// calls dead is the one worth burning through.
#define REACT_BURN_BAND     0.75

// The ground the QRF is told to answer for after a burn-through. Small: the
// transmitter's own position, not an objective - they are answering a
// bearing, not a captured place.
#define REACT_BURN_QRF_RADIUS 150

// Game voice net kinds (jmfsb_voice_fnc_nets) a key-up on never reaches the
// filter: the squad's own net, the crew intercom, and direct speech.
#define REACT_VOICE_SAFE_KINDS ["team", "veh", "direct"]

// What a client may report about its own player (FUNC(report), review R1),
// and the server's machine id for the requests that go to it.
#define REACT_CLIENT_SOURCES ["radio", "burnthrough", "hack"]
#define SERVER_OWNER         2
