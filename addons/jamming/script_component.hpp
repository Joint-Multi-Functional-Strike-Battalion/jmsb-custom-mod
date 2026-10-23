#define COMPONENT jamming
#define COMPONENT_BEAUTIFIED Jamming
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE
// #define CBA_DEBUG_SYNCHRONOUS
// #define ENABLE_PERFORMANCE_COUNTERS

#ifdef DEBUG_ENABLED_JAMMING
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_JAMMING
    #define DEBUG_SETTINGS DEBUG_SETTINGS_JAMMING
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// --- tuning constants ---
#define JAM_CHECK_INTERVAL      2       // sec between client-local jam re-evaluations
#define JAMMER_PRUNE_INTERVAL   10      // sec between server jammer-liveness re-broadcasts
#define JAMMER_EFFECTIVE_FRAC   0.4     // inner fraction of a jammer radius that is full-strength

// RADIO AND DATA ZONES ARE RF NOISE (2026-10-19). FUNC(rfNoise) is registered
// with jmfsb_rf_fnc_addNoiseSource: a radio zone adds noise on the voice
// bands, a data zone on the band of RF's DATA net, at the module's dBm at the
// core scaled by the zone's own factor (10 log10 f). Game voice feels it
// through RF link quality in jmfsb_voice - this addon touches no voice code.
// GPS stays here (FUNC(gpsApply)).
#define JAM_RF_CORE_DBM         -40
#define JAM_RF_RADIO_BANDS      ["VHF", "UHF"]
#define JAM_RF_DATA_NET         "DATA"

// ACRE2 jamming levers - fraction of received signal STRENGTH removed, applied
// through acre_api_fnc_setCustomSignalFunc (strengthPct *= 1 - frac).
#define ACRE_JAM_FULL           0.98    // fraction removed inside a jammer's core
#define ACRE_JAM_NEAR           0.6     // at the inner edge of the falloff band
#define ACRE_JAM_FAR            0       // at the outer edge (no jam)

// --- zone registry ---------------------------------------------------------
// One entry per zone. Indices 0-2 are FROZEN: pre-registry consumers (the jam
// loop, fnc_hasDetector, hacking's fnc_nearestTower) read them positionally.
// Everything new is appended, so nothing had to be rewritten to add it.
//   0 object          emitter, objNull for temp/abstract zones
//   1 rEff            full-strength radius
//   2 rFall           outer radius, jamming reaches zero here
//   3 id              STRING, unique, stable for the zone's life
//   4 type            "jam" | "detect"
//   5 isTemp          BOOL, spawned by a hack failure rather than the module
//   6 pos             position, authoritative when object is null
//   7 model           HASHMAP of the Part 3 propagation fields
#define ZONE_OBJ    0
#define ZONE_REFF   1
#define ZONE_RFALL  2
#define ZONE_ID     3
#define ZONE_TYPE   4
#define ZONE_TEMP   5
#define ZONE_POS    6
#define ZONE_MODEL  7

// The whole detection net is one synthetic zone (D35); this is its fixed id.
#define DETECT_NET_ID "detect_net"

// --- jamming meter (Part 3 Â§3) ---------------------------------------------
#define IDC_JAM_PANEL   8600
#define IDC_JAM_LABEL   8601
#define IDC_JAM_BAR     8602
// ONE ROW PER DOMAIN (user, 2026-08-31). The meter used to be a single
// label and bar, which stopped meaning anything the moment one emitter
// could deny the net without touching TAC//MSG. Labels are BASE+i and
// bars BASE+i for i in JAM_ROWS order; the classes in gui.hpp carry the
// old idc as a default and ctrlCreate overrides it per row.
#define IDC_JAM_LABEL0  8610
#define IDC_JAM_BAR0    8620

// The row colours, the house palette the hacking tablet and the HUD use:
// bone for a service that still works, amber for degraded, red for gone.
#define JAM_COL_OK      [0.933, 0.910, 0.863, 0.55]
#define JAM_COL_DEG     [0.914, 0.651, 0.235, 1]
#define JAM_COL_OUT     [0.85, 0.28, 0.20, 1]

#define JAM_HUD_ID      "jamMeter"
#define JAM_HUD_W       0.16
#define JAM_HUD_H       0.09    // three rows now, not one
#define JAM_HUD_DEF_X   0.42
#define JAM_HUD_DEF_Y   0.80
#define JAM_HUD_INTERVAL 0.5

// --- RDF scanner (Part 3 section 2) ----------------------------------------

// --- UAV jamming (Part 3 section 4) ----------------------------------------
#define UAV_SWEEP_INTERVAL  5       // sec between server drone sweeps
#define UAV_FREEZE_FACTOR   0.5     // jam factor at which a drone is frozen

// --- AI ambient emitters (Part 1 section 8) --------------------------------
#define AI_CHATTER_RANGE    3000    // m from a player for AI traffic to be worth simulating
#define AI_CHATTER_MIN      3       // sec a transmission lasts, lower bound
#define AI_CHATTER_MAX      6       // upper bound

// THE THREE DOMAINS (user, 2026-08-31). A zone denies one or more of them, and
// every consumer asks about the one it cares about rather than about "jamming".
//   radio - the voice net: game voice (through RF) and ACRE degradation
//   data  - TAC//MSG traffic and other groups' BFT markers
//   gps   - the GPS item and the map self-icon
// DOM_ANY is not a domain a zone can carry; it is the question the HUD and the
// EW scanner ask, meaning "is anything jamming here, whatever it denies".
//
// A zone with no domains set carries RADIO and DATA, which is what one emitter
// did before the split, so an untouched mission behaves exactly as it did.
#define DOM_RADIO   "radio"
#define DOM_DATA    "data"
#define DOM_GPS     "gps"
#define DOM_UAV     "uav"
#define DOM_ANY     "any"
#define DOM_DEFAULT [DOM_RADIO, DOM_DATA]

// WHERE A SERVICE IS CALLED GONE RATHER THAN SICK. messaging's linkState
// turns DEGRADED into DENIED here, the meter turns amber into red here, and
// the GPS strip fires here - one number, so the handset, the map and the
// meter cannot describe the same field three different ways.
#define JAM_DENIED_BAND 0.75

// A JAMMER SITE IS THREE PROPS, NOT ONE (user, 2026-08-31). The terminal says
// what the site DENIES and is the emitter - it holds the zone, and hacking or
// destroying it is what kills the zone. The antenna and the dish are the
// installation around it: they make a site read as a site from three hundred
// metres out instead of as a lone box, and they are the reason the whole thing
// is registered with ALiVE as an objective rather than left as scenery.
//
// The terminal picks the domain, one class each:
#define JAM_PROP_GPS        "RuggedTerminal_01_communications_hub_F"
#define JAM_PROP_DATA       "RuggedTerminal_01_F"
#define JAM_PROP_RADIO      "RuggedTerminal_01_communications_F"

// One of each of these joins it, rolled per site so no two look identical.
#define JAM_PROP_OMNI       ["OmniDirectionalAntenna_01_sand_F", "OmniDirectionalAntenna_01_black_F", "OmniDirectionalAntenna_01_olive_F"]
#define JAM_PROP_DISH       ["SatelliteAntenna_01_Sand_F", "SatelliteAntenna_01_Olive_F", "SatelliteAntenna_01_Black_F"]

// How far the two dressing props stand from the terminal, and how big the ALiVE
// objective the site is registered as ends up being.
#define JAM_SITE_SPREAD     14
#define JAM_SITE_OBJ_SIZE   60

// How often a site with Artillery Reply armed looks at its own field. Five
// seconds, because the thing being measured is a dwell time in the tens of
// seconds and nearEntities over a 3 km radius is not free.
#define JAM_ARTY_TICK       5

// How often dead or hacked emitters are pruned from the registry.
#define JAM_PRUNE_TICK      10

// Sites placed per frame while the spawn queue drains. Two is deliberately
// slow: the whole point is that a thirty-one commander order of battle
// costs a longer wait rather than a frozen server, and nobody is looking at
// a mast in the first minute of a mission anyway.
#define JAM_SPAWN_PER_TICK  2

// GPS DENIAL IS SPACE-BASED (user, 2026-08-31), so it has no mast at the
// spot it is denying. A wandering sphere with nothing in it to kill does
// the denying, and ONE ground station - the uplink that steers it - is
// what ends it. Kill or hack the station and the sphere goes with it, for
// good: this is the only jamming in the system a player cannot walk out of.
#define GPS_SPHERE_R_A      1000    // the two radii the sphere is rolled from
#define GPS_SPHERE_R_B      2000
#define GPS_DRIFT_TICK      20      // sec between sphere moves
#define GPS_DRIFT_SPEED     22      // m/sec of drift, so ~440 m a tick
#define GPS_TURN_CHANCE     25      // % chance a tick re-rolls the heading
#define GPS_EDGE_MARGIN     500     // m from the world edge the sphere turns back

// ONE GPS JAMMER PER MAP (user, 2026-08-31), not one per commander. A comms
// net is many masts and a constellation is steered from one place - so the
// first commander with an objective gets the uplink and nobody else does.
#define GPS_ONE_PER_MAP     1
