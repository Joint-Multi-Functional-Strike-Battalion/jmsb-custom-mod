#define COMPONENT antiship
#define COMPONENT_BEAUTIFIED AntiShip
#include "\z\jmfsb\addons\main\script_mod.hpp"

#ifdef DEBUG_ENABLED_ANTISHIP
    #define DEBUG_MODE_FULL
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

#define AS_TICK             10      // sec between scheduler checks
#define AS_INTERVAL_DEF     1200    // sec between launches - 20 minutes
#define AS_TARGETS_DEF      "Land_Carrier_01_base_F,Land_Destroyer_01_base_F,Ship"
#define AS_SEARCH_DEF       12000   // m the battery looks for a hull

// Faster than anything trying to stop it. Vanilla AA tops out well under this
// and the CIWS interceptor defaults to 600, so a tail chase is hopeless - it has
// to be engaged head-on, early, which is the whole tactical problem of a
// sea-skimmer.
#define AS_SPEED_DEF        900

// --- the surface search radar ---------------------------------------------
// The battery sits inland with no sight of the sea, so something else has to
// see for it. Everything here is per-radar overridable from the object's init
// field, e.g. this setVariable ["jmfsb_antiship_range", 40000];
#define AS_RADAR_TICK       5       // s between sweeps
#define AS_RADAR_RANGE      30000   // m instrumented range
#define AS_RADAR_ON         20      // s radiating
#define AS_RADAR_OFF        40      // s silent - EMCON, so it cannot just be waited for
#define AS_RADAR_DAMAGE     0.5     // damaged past this and the set is off the air
#define AS_RADAR_TRACK      90      // s a contact stays usable after it was last seen
// 4.12 * (sqrt(antenna m) + sqrt(mast m)) = km to the radar horizon. In metres
// here so the maths stays in the units everything else uses.
#define AS_RADAR_HORIZON    4120
// What a surface set sees. Not the battery's target list - a radar paints every
// hull and choosing which one is worth a missile is the battery's job. The two
// static hulls are buildings rather than Ships, so they need naming.
#define AS_RADAR_TYPES      ["Ship","Land_Carrier_01_base_F","Land_Destroyer_01_base_F"]

#define AS_CRUISE_ALT_DEF   45      // m above sea on the run in
#define AS_TERMINAL_DEF     1200    // m from the hull where it stops cruising and dives
#define AS_PN_GAIN          4
#define AS_TICK_FLY         0.045   // s between guidance corrections
#define AS_BOOST_TIME       2       // s of climb before it noses over
#define AS_FUZE             15      // m
#define AS_TIMEOUT          180     // s before a lost missile gives up

// --- the module's siting (jmfsb_moduleAntiShip) ----------------------------
#define AS_SITE_COAST       500     // m from the sea the radar may stand - further and it is not coastal
#define AS_SITE_PROBE       50      // m between water probes along each bearing
#define AS_SITE_SAMPLES     150     // candidate draws per radar - coast is a thin strip of a TAOR
#define AS_SITE_SPREAD      2000    // m between two batteries of one side
#define AS_LAUNCH_MIN       300     // m inland of the radar a launcher stands, at least
#define AS_LAUNCH_MAX       1500    // m inland of the radar a launcher stands, at most
#define AS_LAUNCH_SPREAD    80      // m between the launchers of one battery
#define AS_SITE_SLOPE       0.15    // gradient a radar or launcher may stand on
#define AS_RADAR_FOOT       8       // m half-size a radar needs clear and dry
#define AS_LAUNCH_FOOT      10      // m half-size a launcher needs clear and dry
#define AS_WORLD_REACH      0.71    // of worldSize: a ring from the centre that reaches every corner
#define AS_SITE_REJECT      -1e6    // score for ground with no sea in reach - never the best
