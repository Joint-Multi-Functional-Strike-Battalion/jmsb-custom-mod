#define COMPONENT rf
#define COMPONENT_BEAUTIFIED RF
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_RF
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_RF
    #define DEBUG_SETTINGS DEBUG_SETTINGS_RF
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// RF IS THE CORE. It depends on CBA and nothing else in this mod: the adapters
// and the consumers depend on it, never the reverse (docs/DESIGN_RF.md). Only
// the two headers above are shared, at compile time.

// --- Radio profiles (docs/DESIGN_RF.md, "Radio profiles") -------------------
// THE ONE PLACE A PROFILE IS WRITTEN. Adapters map their radio classes onto
// these ids; the core never knows a class name.
// [id, bands, TX dBm, RX sensitivity dBm, antenna gain dBi, hop limit,
//  relay capable, spread gain dB, battery Wh (-1 = powered by its host)]
// TX: 5 W = 37 dBm, 20 W = 43, 50 W = 47, 1 W = 30, 10 W = 40.
// "base" is the BASE STATION (user, 2026-10-20): the fixed set of a staging
// zone or a patrol base - the relay's terrestrial numbers plus a SAT terminal,
// powered by the site it stands on.
#define RF_PROFILES [ \
    ["handheld", ["VHF", "UHF"],        14, -112,  2, 4, true,  20,  38], \
    ["manpack",  ["VHF", "UHF"],        43, -115,  3, 6, true,  20,  90], \
    ["vehicle",  ["VHF", "UHF", "SAT"], 47, -118,  6, 8, true,  25,  -1], \
    ["relay",    ["VHF", "UHF"],        43, -118,  6, 8, true,  25, 200], \
    ["base",     ["VHF", "UHF", "SAT"], 43, -118,  6, 8, true,  25,  -1], \
    ["drone",    ["VIDEO"],             33,  -95,  3, 0, false, 10,  -1], \
    ["droneRelay", ["VHF", "UHF"],      33, -112,  3, 4, true,  20,  -1], \
    ["legacy",   ["VHF"],               37, -110,  2, 0, false,  0,  30], \
    ["satcom",   ["SAT"],               40, -120, 12, 0, false, 10,  60] \
]
#define RF_PATTERN_OMNI     "omni"
// A lobe: so many degrees wide about an azimuth, nothing outside it
// (FUNC(patternGain)). EW's jammer module can be set to it.
#define RF_PATTERN_SECTOR   "sector"

// --- Frequencies (FUNC(netFreq), FUNC(bandMhz)) ------------------------------
// Each band's ranges in MHz and the channel raster a net sits on in them;
// VIDEO is the two ISM ranges. A net's frequency is a hash of its id on that
// raster, so every machine works out the same one and none is ever sent. The
// hash stays under 2^24 (SQF numbers are single precision).
#define RF_BAND_MHZ [ \
    ["VHF",   [[30, 88]],                   0.025], \
    ["UHF",   [[225, 400]],                 0.025], \
    ["SAT",   [[7250, 7750]],               1], \
    ["VIDEO", [[2400, 2483], [5725, 5850]], 1] \
]
#define RF_FREQ_HASH_MULT   31
#define RF_FREQ_HASH_MOD    65521
#define DEGREES_FULL        360
#define DEGREES_HALF        180

// --- Carried sets (FUNC(itemProfile), FUNC(carriedSets)) ---------------------
// A radio item names its own profile in config (jmfsb_rf_profile =
// "handheld"), so RF recognises a set with no radio mod and no class list. An
// item in the radio slot that names none is a handheld. Under game voice
// nothing on the back is a set - no man packs (user, 2026-10-21); the
// "manpack" profile is TFAR's and ACRE's long range sets.
#define RADIO_ITEM_SIMULATION       "ItemRadio"
#define RADIO_ITEM_DEFAULT_PROFILE  "handheld"
// The kind of set in a node id: the radio slot.
#define SET_KIND_SR "sr"

// --- Bands --------------------------------------------------------------------
#define RF_BANDS            ["VHF", "UHF", "SAT", "VIDEO"]
// Defaults of the band-table settings (path-loss exponent, loss at 1 m dB,
// noise floor dBm), docs/DESIGN_RF.md "Link budget".
#define VHF_EXP     4.22
#define VHF_REF     9
#define VHF_FLOOR   -110
#define UHF_EXP     4.22
#define UHF_REF     4
#define UHF_FLOOR   -105
#define SAT_EXP     2.0
#define SAT_REF     45
#define SAT_FLOOR   -115
#define VIDEO_EXP   2.46
#define VIDEO_REF   48
#define VIDEO_FLOOR -95

// --- The satellite (docs/DESIGN_RF.md "The satellite link") -------------------
// SAT is not a ground band: two SAT-capable nodes holding one key (one side),
// each under open sky, link in ONE HOP at any distance, terrain and clutter
// ignored, whatever band the net is on (the terminal backhauls it). The SAT
// row of the band table prices only ground emitters on SAT (a jammer's noise,
// an intercept), never the link through the bird.
#define SAT_BAND            "SAT"
// The clear-sky link quality: the satellite's signal is placed this far into
// the quality span at the current threshold and span, so it reads the same
// whatever those settings are. Rain fade and jamming noise come off it in dB.
#define SAT_LINK_QUALITY    0.9
// Rain fade at full rain (the setting's default); an overcast sky with no
// rain counts this share of full rain.
#define DEFAULT_SAT_FADE_DB 6
#define SAT_OVERCAST_SHARE  0.25
// The open-sky check: one ray straight up from the antenna, this long. Cached
// per node; re-cast on the static tick or after EDGE_REUSE_M of movement.
#define SKY_CHECK_M         30
// The cache entry of a node whose sky was never cast: stale at once.
#define SKY_UNCAST          [[0, 0, 0], -1e9, false]
// rx of a link with no signal at all (no open sky at one end).
#define NO_SIGNAL_DBM       -1000

// Quality = clamp((snr - thr) / span). thr is open item 7 (6 dB in the spec,
// 3 dB in the mockups) and is a setting for that reason.
#define DEFAULT_THR_DB      6
#define DEFAULT_SPAN_DB     20

// Obstacles.
#define TERRAIN_SAMPLES     3
#define DEFAULT_TERRAIN_DB  12
#define DEFAULT_WALL_DB     18
#define DEFAULT_TREE_DB     5
#define DEFAULT_PRONE_DB    3
#define DEFAULT_VEHICLE_DB  6
// Clutter is counted with lineIntersectsSurfaces, one hit per object, capped.
// Past CLUTTER_FULL_M only the CLUTTER_END_M at each end is cast: the clutter
// round an antenna is what costs, and lineIntersectsSurfaces stops at 5 km.
#define CLUTTER_MAX_HITS    8
#define CLUTTER_FULL_M      1000
#define CLUTTER_END_M       400
// Terrain-object models of trees and bushes start with these (t_*, b_*).
#define TREE_MODEL_PREFIXES ["t_", "b_"]
// Where a node's antenna is, above a non-man object's origin.
#define PROP_ANTENNA_M      2

// --- Tick -----------------------------------------------------------------------
#define DEFAULT_TICK_PLAYERS 1
#define DEFAULT_TICK_STATIC  5
// An edge's path loss (the raycasts) is reused while neither end has moved
// further than this and it is younger than the static tick.
#define EDGE_REUSE_M        10
// ...and forgotten when nobody has asked for it for this many static ticks.
#define EDGE_CACHE_KEEP     2

// --- Mesh -----------------------------------------------------------------------
// Link quality is quantised before it is stored, so a slice only "changes"
// when the link really does - not on every tick's jitter.
#define QUALITY_STEP        0.05
// EMCON level from which a node stops relaying (SPEC rf.ew.EP.emcon).
#define EMCON_NO_RELAY      2
#define EMCON_MAX           3
// jmfsb_rf_fnc_quality: "RF does not know this node or net".
#define QUALITY_UNKNOWN     -1
// "No relay on the path yet", for the hop-limit minimum.
#define HOP_LIMIT_NONE      1e9
// Nets RF owns itself: DATA runs with no radio backend at all (rule 5).
#define NET_DATA            "DATA"
#define NET_DATA_BAND       "UHF"
#define SIDES_KEYED         [west, east, independent, civilian]
#define KEY_LENGTH          16
#define KEY_CHARS           "0123456789abcdef"

// --- Range self-test --------------------------------------------------------
#define RANGE_MAX_M         10000000
#define RANGE_ITERATIONS    48
// The range of the satellite: any distance.
#define RANGE_ANY           -1

// --- Debug overlay ----------------------------------------------------------
#define DEBUG_LINE_ALPHA    1
// The main map: display and control the overlay draws on.
#define MAP_DISPLAY         12
#define MAP_CONTROL         51
