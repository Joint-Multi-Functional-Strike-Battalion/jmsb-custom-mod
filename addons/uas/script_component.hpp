#define COMPONENT uas
#define COMPONENT_BEAUTIFIED UAS
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_UAS
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_UAS
    #define DEBUG_SETTINGS DEBUG_SETTINGS_UAS
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// How often patrols are topped back up to the ceiling, and how often live
// drones are checked for having seen somebody. Both slow: a drone that has
// noticed you stays noticed, and a fleet that is one short can wait.
#define UAS_PATROL_TICK     60

// Replacements per side per planning tick. Uncapped, a side that keeps
// losing drones - a DDT jammer pack downs every hostile UAV inside 100 m,
// crew deleted, no exemption flag - was refilled to the full ceiling every
// minute, which read as raining drones. Attrition now regenerates as a
// drip: the fleet still comes back, one airframe at a time.
#define UAS_REGEN_PER_TICK  1

// What one patrol thins to while its side's supply cache is down. One, so the
// sky visibly empties without going quiet - a patrol that vanished entirely
// would make a cache raid an off switch rather than a cost.
#define UAS_OUTAGE_MAX      1
#define UAS_SPOT_TICK       8

// A drone that has reported a player says nothing again for this long, so one
// pass over a position is one discovery rather than a stream of them.
#define UAS_SPOT_COOLDOWN   120

// How sure a drone must be that it is looking at somebody. knowsAbout runs
// 0-4; 1.5 is "identified something", not "glimpsed a heat blob".
#define UAS_SPOT_KNOWS      1.5

// How far from a drone a player is even considered for detection.
#define UAS_SPOT_RANGE      800

// THE IED PELICAN'S FUZE - see FUNC(iedDrone). How close a hostile has to be
// to set it off, how often it looks, and how long after spawning it starts
// looking (so it does not take its own operator at deployment).
#define UAS_IED_RADIUS      7
#define UAS_IED_TICK        0.5
#define UAS_IED_ARM_DELAY   12

// How long FUNC(fpvWatch)'s wait for Drongo's Drone Tweaks sits before giving up.
#define UAS_DDT_WAIT_S      600

// HOW CLOSE A PLAYER HAS TO BE FOR A PATROL TO EXIST AT ALL.
//
// A drone orbiting a base nobody is near is a drone nobody will ever see, and
// this mission flies twenty of them: twenty airframes, twenty crews and twenty
// AI pilots being simulated across an island for an audience of nobody. The
// point of a patrol is to be met, so one is put up when somebody is close
// enough to meet it and stood down when everybody has left.
//
// Measured to the ORBIT CENTRE, not to the airframe - a patrol wanders 800 m
// around its objective, and measuring the aircraft would have a drone standing
// itself down and back up as it flew the far side of its own circle.
#define UAS_PLAYER_RANGE    3200

// AND HOW CLOSE COUNTS AS BEING WATCHED. A patrol on the near side of a circle
// whose centre has just gone out of range is still a real aircraft in somebody's
// sky; FUNC(standDown) leaves that one for a later tick rather than deleting it
// in front of them. Under the range at which an airframe at 250-600 m is
// anything more than a speck.
#define UAS_SEEN_RANGE      2000

// Patrol altitude band.
#define UAS_ALT_MIN         250
#define UAS_ALT_MAX         600

// A patrol wanders this far around its orbit centre, so it is also the smallest
// zone worth drawing - a module never resized is one orbit.
#define UAS_ORBIT_RADIUS    800
// A rotor UAV (anything not a Plane) patrols a ring of MOVE waypoints instead
// of a LOITER, which only a fixed wing flies cleanly (user, 2026-10-24: the
// patrol drones "were wobbling in place in the air"): this many points, on
// this fraction of the zone's radius but never tighter than the minimum,
// reached within the completion radius, at a rotor's height.
#define UAS_ROTOR_RING_POINTS 6
#define UAS_ROTOR_RING_FRAC   0.7
#define UAS_ROTOR_RING_MIN    200
#define UAS_ROTOR_WP_RADIUS   60
#define UAS_ROTOR_ALT_MIN     90
#define UAS_ROTOR_ALT_MAX     160

// --- the swarm module -------------------------------------------------------
// Two is the smallest thing worth calling a swarm; twelve is where a dozen
// airframes, crews and steering loops stop being a swarm and start being a
// frame time.
#define UAS_SWARM_MIN       2
#define UAS_SWARM_MAX       12
#define UAS_SWARM_STAGGER   0.5     // s between launches - a swarm arriving, not a stutter

// WHERE A SWARM COMES FROM. Far enough that it is seen and heard coming and can
// be engaged on the way in - at UAS_SWARM_SPEED, 1500 m is about thirty seconds
// of somebody deciding what to do about it. Spawning on top of the target is a
// swarm that cannot be fought, which is not a swarm, it is damage.
// The hard floor on the module's Spawn Min. Below this a swarm is on top of its
// target before anybody can react to it, which is not a difficulty setting.
#define UAS_SWARM_SPAWN_FLOOR 500

#define UAS_SWARM_SPAWN_MIN 1500
#define UAS_SWARM_SPAWN_MAX 2500

// IMPACT
#define UAS_SWARM_SPEED     45      // m/s on the run in
#define UAS_SWARM_STEP      0.1     // s between steering writes
#define UAS_SWARM_FUSE      6       // m
#define UAS_SWARM_TIMEOUT   120     // s before a lost airframe deletes itself
#define UAS_SWARM_WARHEAD   "Sh_122mm_AMOS"

// THE REST OF THE FUSE - see FUNC(swarmImpact). How far ahead the dive looks
// for a surface or the ground before the next step: two steps' travel and the
// fuse, so a long frame still finds the wall before the airframe does. How
// many hits that look may return - the airframe's own crew come back first.
// Under this height over the terrain the airframe is on the ground. Inside
// this many metres of the aim, moving away from it counts as having arrived.
#define UAS_SWARM_REACH     (UAS_SWARM_SPEED * UAS_SWARM_STEP * 2 + UAS_SWARM_FUSE)
#define UAS_SWARM_SCAN_HITS 4
#define UAS_SWARM_DECK      1
#define UAS_SWARM_TERMINAL  50

// CIRCLE
#define UAS_SWARM_RADIUS    400     // m orbit when the module was never resized
#define UAS_SWARM_ALT       120     // m the lowest shelf
#define UAS_SWARM_ALT_STEP  40      // m between shelves, so a stack does not collide
