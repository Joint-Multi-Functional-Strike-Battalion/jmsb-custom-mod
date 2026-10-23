#define COMPONENT cas
#define COMPONENT_BEAUTIFIED CAS
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_CAS
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_CAS
    #define DEBUG_SETTINGS DEBUG_SETTINGS_CAS
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// How long the run is allowed to take before the airframe is written off and
// swept, whatever it is doing. A drone that loses its waypoints to terrain or
// a stall would otherwise circle for the rest of the mission holding its
// asset busy - and the ledger would never free up.
#define CAS_RUN_TIMEOUT     600

// How close to the target counts as arrived, for the pass that releases
// ordnance. The aircraft is doing 200+ m/s; a tighter ring is one the tick
// can step straight over.
#define CAS_RELEASE_RING    600

// The terminal-guidance poll. The aircraft re-looks for a laser or smoke on
// the way in rather than once, so a JTAC who lights the target LATE - which
// is the normal case, you do not burn a designator for a minute - is still
// picked up before release.
#define CAS_ACQUIRE_STEP    1

// A dummy laser target is what actually guides the ordnance; see
// FUNC(fireAt). This is how far above the aim point it sits so a bomb
// fuses on the target rather than short of it.
#define CAS_DUMMY_UP        0.1

// HOW THE HEAVIEST THING ABOARD IS DECIDED, and the only place that order is
// written. FUNC(stores) ranks the airframe's stores with it so the page reads
// down the list in the order a run would have chosen for itself, and
// FUNC(fireAt) picks AUTO with it. Bombs first because that is what a strike
// is for; the gun last so an airframe carrying only cannon still makes a run
// rather than flying over silently. Submunitions sit with the bombs - a
// cluster store is a bomb to everyone except the config.
#define CAS_RANK            ["shotbomb", "shotsubmunitions", "shotmissile", "shotrocket", "shotshell", "shotbullet"]

// LOITER IS A TASK, NOT A RUN, so it gets its own patience: an ISR asset is
// meant to sit over the objective for as long as the section is working, and
// the strike timeout would pull it off station in ten minutes. It still ends
// on RTB, on death, or here.
#define CAS_LOITER_TIMEOUT  3600

// The orbit the aircraft holds over the task point once it is on station.
#define CAS_LOITER_RADIUS   900

// How close to the task point counts as ON STATION - the ring that hands the
// gunner's seat to the drone controller. Wide, because an orbit this size
// never puts the aircraft on the point itself.
#define CAS_STATION_RING    1600

// THE WAY OUT. A run that is over - egressed, recalled, out of patience - flies
// on its egress heading off the map and is deleted once it is outside it (see
// FUNC(egress)). The exit point sits this far past the edge so the aircraft
// crosses the edge before it ever arrives and slows for a waypoint.
#define CAS_EXIT_MARGIN     1000

// How often the way out is checked, and how long it may take before the
// aircraft is deleted where it is. Long enough to cross the biggest map at a
// UAV's cruise; a drone that has lost its waypoint to a stall is not left
// circling for the rest of the mission.
#define CAS_EXIT_STEP       1
#define CAS_EXIT_TIMEOUT    1200

// The beat between handing the seat back and deleting the airframe, so the
// controller is out of the turret before it goes.
#define CAS_EXIT_HANDBACK   3

// THE SUPPORT PROVIDER this addon registers with the support core: the kind is
// the prefix of every asset id FUNC(entityRow) hands out ("cas:3"), and the
// type declaration is the one asset type and three tasks TAC//SUPPORT offers
// for these drones. LOITER holds overhead; every other token is a strike - see
// FUNC(task). The ATTACK tokens need a target grid, which the screen already
// asks of this provider's rows (it draws INGRESS and EGRESS for them too).
#define SUPPORT_KIND        "cas"
#define SUPPORT_ORDER_CAS   20
// The labels of the run's own points in the plan the board draws (row field
// 8): FUNC(request) writes them, FUNC(overlay) finds the legs by them.
#define PLAN_IN             "IN"
#define PLAN_OUT            "OUT"
// THE VERDICT BEFORE CONFIRM (FUNC(preview)) reads a time the way the board
// does (FUNC(fmtEta)): whole seconds under a minute, then minutes and seconds
// rounded to this step - "ETA 40 S", "ETA 2 MIN 40 S". support_air reads its
// times through the same function.
#define ETA_STEP            10
#define ETA_MINUTE          60
// km/h in one m/s - the module's Speed and config maxSpeed are km/h.
#define KMH_PER_MS          3.6
// The run the player draws: INGRESS and EGRESS, in the core's slots 8 and 9
// (task declaration field 7, [label, slot, hint, required, many, leg]).
#define SUPPORT_POINTS [["INGRESS", 8, "AUTO - FROM YOUR SIDE", false, 1, "in"], ["EGRESS", 9, "AUTO - STRAIGHT THROUGH", false, 1, "out"]]
#define SUPPORT_TYPES [ \
    ["cas", "CAS", "AIRFRAME", "AIRFRAMES", SUPPORT_ORDER_CAS, [ \
        ["SAD", "SAD", "SEEK & DESTROY", "Unit will move to location, provide close air support and engage all painted targets", [], true, "", SUPPORT_POINTS], \
        ["LOITER", "LOITER", "", "Unit holds overhead the task point", [], true, "", SUPPORT_POINTS], \
        ["ATTACK RUN", "ATTACK RUN", "", "Unit makes attack runs on the task point", [], true, "", SUPPORT_POINTS] \
    ]] \
]
