#define COMPONENT ambience
#define COMPONENT_BEAUTIFIED Ambience
#include "\z\jmfsb\addons\main\script_mod.hpp"

#ifdef DEBUG_ENABLED_AMBIENCE
    #define DEBUG_MODE_FULL
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// Scheduler cadence - both modules wake this often and check their clocks.
#define AMB_TICK            15

// A TICK THAT FOUND NOBODY COMES BACK IN A MINUTE, not in another full
// interval. Both modules used to roll the next fire time BEFORE asking
// pickBuilding for a target, so a tick that landed while the players were
// inside a base - no house in the 150-450m band, or nobody in the markers -
// threw away the whole 240-900s wait and said nothing about it. On a short
// session that reads exactly like ambience that does not work.
#define AMB_RETRY           60

// How long a kamikaze run may chase before it gives up and goes away.
#define AMB_KAM_TIMEOUT     180

// The kamikaze steering tick and the arm/impact fuse distance.
#define AMB_KAM_STEP        0.1
#define AMB_KAM_FUSE        10

// The rest of the fuse - see FUNC(kamikazeRun): how many surface hits the look
// ahead may return (the airframe's own crew come back first), under what
// height over the terrain the airframe is on the ground, and inside how many
// metres of the aim moving away from it counts as having arrived. The look
// ahead itself is two steps' travel at the run's speed plus the fuse.
#define AMB_KAM_SCAN_HITS   4
#define AMB_KAM_DECK        1
#define AMB_KAM_TERMINAL    50
