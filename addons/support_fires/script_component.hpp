#define COMPONENT support_fires
#define COMPONENT_BEAUTIFIED Support Fires
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_SUPPORT_FIRES
    #define DEBUG_MODE_FULL
#endif
#ifdef DEBUG_SETTINGS_SUPPORT_FIRES
    #define DEBUG_SETTINGS DEBUG_SETTINGS_SUPPORT_FIRES
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// ---------------------------------------------------------------- provider --
// THE SUPPORT PROVIDER this addon registers with the support core
// (addons/support/README.md). Every asset id it hands out is "fires:<n>", n the
// module's place in GVAR(entities).
#define SUPPORT_KIND        "fires"

// The asset types. BOTH ARTILLERY MODULES ARE "arty" (user, 2026-10-20:
// "arty should be virtual"): every battery of ours is a virtual one, and it
// lists under the one ARTILLERY tab beside any other provider's guns.
#define TYPE_ARTY           "arty"
#define TYPE_CRUISE         "cruise"
#define TYPE_LOITER         "loiter"

// List order in the ASSET group. In use elsewhere: transport 10, CAS 20,
// artillery 30.
#define ORDER_ARTY          30
#define ORDER_CRUISE        34
#define ORDER_LOITER        36

// Task tokens.
#define TASK_FIRE           "FFE"
#define TASK_STRIKE         "STRIKE"
#define TASK_HUNT           "HUNT"
#define TASK_RTB            "rtb"

// PARAMETER SLOTS. 0-11 belong to the screen and the older providers; 12-19
// are this addon's, 20-31 support_air's, and 32-35 this addon's again (the
// Simplex-style fire mission fields, 2026-10-20). A slot means the same thing
// for every asset type that declares it.
#define SLOT_ORD            12
#define SLOT_ROUNDS         13
#define SLOT_SHEAF          14
#define SLOT_GUNS           15
#define SLOT_MISSILES       16
#define SLOT_MUNITIONS      17
#define SLOT_SEARCH         18
#define SLOT_SHEAF_TYPE     19
#define SLOT_DELAY          32
#define SLOT_INTERVAL       33
#define SLOT_REPEAT         34
#define SLOT_COORD          35

// Stepper ranges. A slot the player never touched reads as its minimum, which
// is what the screen shows for it - so every minimum below is a real order.
// The tops of ROUNDS, DELAY, INTERVAL and REPEAT are the module's own (its Max
// attributes, the Simplex limits); 0 there takes the stepper off the page.
#define SHEAF_STEP          25
#define SHEAF_MAX           300
#define SEARCH_MIN          100
#define SEARCH_STEP         50
#define SEARCH_MAX          1000
#define DELAY_STEP          15
#define INTERVAL_STEP       5

// SHEAF TYPES, the values of SLOT_SHEAF_TYPE (Simplex's four). The SHEAF
// stepper sizes each one - the square the page draws round the target:
//   converged - every round at its own random point inside the sheaf radius
//   parallel  - the guns side by side across the line of fire, each on its
//               own aim point, spread over the sheaf's width
//   box       - rounds spread evenly over the whole square
//   creeping  - one lane per gun across the square; each gun's rounds walk
//               from the near edge to the far edge along the line of fire
#define SHEAF_CONVERGED     0
#define SHEAF_PARALLEL      1
#define SHEAF_BOX           2
#define SHEAF_CREEPING      3
#define SHEAF_WORDS         ["CONVERGED", "PARALLEL", "BOX", "CREEPING"]

// Row status tokens. "idle" is the only one the core treats as taskable.
#define STATUS_IDLE         "idle"
#define STATUS_COOLDOWN     "cooldown"
#define STATUS_FIRING       "firing"
#define STATUS_INBOUND      "inbound"
#define STATUS_STATION      "on station"
#define STATUS_EXPENDED     "expended"

// ---------------------------------------------------------------- shared --
// The splash call comes this long before the first round lands.
#define SPLASH_LEAD         5
// The target marker the asset's side sees on the map while a mission runs
// (Simplex's task marker): an icon on the point, and the area hunted or
// shelled as an outline when the mission has one.
#define MARK_ICON           "mil_warning"
#define MARK_COLOR          "ColorOrange"
#define MARK_ALPHA          0.8
#define MARK_AREA_BRUSH     "Border"

// -------------------------------------------------------- virtual artillery --
// GRAVITY (9.8066) comes from addons/main/script_macros.hpp.
// CHARGES, as shares of the muzzle velocity - a 155 mm howitzer's propellant
// charges. A high-angle mission is fired on the lowest charge that reaches
// with the tube at or under VA_MAX_ELEV, the way a real battery (and
// Simplex's solver) does it, so a near target is not a three-minute lob.
// Artillery shells fly without drag in Arma, so the vacuum arc is exact.
#define VA_CHARGES          [0.19, 0.3, 0.48, 0.65, 0.8, 1]
#define VA_MAX_ELEV         80
// The descent the round is spawned on: it appears this many seconds before it
// lands, on the descending branch of its arc, so it is heard and seen coming in
// rather than popping into existence on the ground.
#define VA_DESCENT_TIME     8
// Speed the round arrives at. A vacuum arc would bring a high-angle shell down
// at its muzzle velocity; real shells lose most of that to drag, so the
// descent is flown at a shell's real terminal speed along the vacuum angle.
#define VA_IMPACT_SPEED     300
// The round is never spawned lower than this above the target - a flat low
// angle shot would otherwise appear a few metres off the ground.
#define VA_MIN_SPAWN_AGL    150
// Illumination is a flare that ignites a few seconds after it is spawned
// (F_40mm_White_Illumination: triggerTime 3); it is spawned this high so it
// burns over the target and drifts down through it.
#define VA_ILLUM_HEIGHT     280
#define VA_ILLUM_FALL       -4
// Submunition rounds (smoke, cluster, guided, the 230 mm rockets) are opened
// by script at their own triggerDistance above the ground
// (FUNC(virtualRound)), because a spawned round has no aim point for the
// engine's own fuze to measure against.
// Time between salvos of the battery's guns is the module's reload; the guns
// within one salvo are this far apart, so a sheaf lands as a ripple.
#define VA_GUN_STAGGER      0.4
// A finished volley waits this long after its last impact before the next
// volley or the end of the mission, so the last round is down first.
#define VA_SETTLE           2
// Defaults of the battery attributes, shared by the Virtual Artillery module
// and the retired Artillery Battery module (which has none of them).
#define VA_DEF_GUNS         4
#define VA_DEF_MV           810
#define VA_DEF_MIN_RANGE    2000
#define VA_DEF_MAX_RANGE    24000
#define VA_DEF_DISPERSION   40
#define VA_DEF_RELOAD       8
#define VA_DEF_COOLDOWN     60
#define VA_DEF_ROUND_CD     5
#define VA_DEF_MAX_ROUNDS   12
#define VA_DEF_MAX_DELAY    300
#define VA_DEF_MAX_INTERVAL 30
#define VA_DEF_MAX_REPEAT   3
#define VA_DEF_COORDINATION 1000
#define VA_DEF_SHEAFS       "CONVERGED, PARALLEL, BOX, CREEPING"

// ---------------------------------------------------------- cruise missiles --
#define CM_TICK             0.05
// Straight up off the rail for this long before it noses over onto its route.
#define CM_BOOST_TIME       3
#define CM_BOOST_SPEED      60
// Route points are this far apart along the track; each one is flown at the
// cruise altitude above the ground under it.
#define CM_LEG              1500
// Look-ahead for terrain following: the missile climbs for ground it will be
// over this many seconds from now, not the ground it is already over.
#define CM_LOOKAHEAD        3
// From this far out (horizontal) the missile stops following the terrain and
// dives straight at the target.
#define CM_TERMINAL         1800
// Detonation distance.
#define CM_FUZE             12
// How sharply it turns towards its next point, per second (blend weight),
// on the route and in the terminal dive.
#define CM_TURN             1.5
#define CM_TURN_TERMINAL    4
// Terminal profile: inside CM_TERMINAL it pops up this far above its cruise
// height, and inside CM_DIVE it pushes over and dives onto the target.
#define CM_POPUP            200
#define CM_DIVE             700
// The rail the missile leaves from stands this high above the ground or sea.
#define CM_RAIL_HEIGHT      5
// A missile reports itself to the air defence intercept (adsite) once its
// time to impact is under this - adsite ignores threats further out.
#define CM_REPORT_TTI       200
// Missiles in one salvo leave this many seconds apart.
#define CM_SALVO_GAP        4
// Closest target a launcher takes: inside this the missile is still climbing
// off the rail when it should already be diving.
#define CM_MIN_RANGE        1000
// Never plan a flight longer than this share of the round's timeToLive.
#define CM_TTL_SHARE        0.9
// Ammo used when the module names none - the Mk41 VLS round (weapons_f_destroyer).
#define CM_CLASS_DEF        "ammo_Missile_Cruise_01"

// ------------------------------------------------------- loitering munitions --
#define LM_TICK             0.05
// The search runs every this many seconds while on station.
#define LM_SCAN             3
// Distance from the area centre that counts as arrived on station.
#define LM_STATION_RING     400
// Dive: speed floor, and the distance at which the warhead goes off.
#define LM_DIVE_SPEED       70
#define LM_FUZE             4
// A munition that has not found its way to the area in this long is lost -
// and a target further than it can fly in that time is refused.
#define LM_TRANSIT_MAX      900
// The munition flies to the area at this share of its airframe's top speed.
#define LM_CRUISE_SHARE     0.6
// Infantry within this of a man count towards his score - the best infantry
// target is the one standing in the biggest group.
#define LM_CLUSTER          12
// A target must be at least this visible from the munition.
#define LM_VISIBLE          0.2
#define LM_SPAWN_HEIGHT     60
// The orbit flown over the area: this share of the search radius, never
// tighter than the floor.
#define LM_ORBIT_SHARE      0.6
#define LM_ORBIT_MIN        150
#define LM_LAUNCH_GAP       3
// Ammo detonated when the module names no warhead and the airframe carries
// none of its own.
#define LM_WARHEAD_DEF      "M_Titan_AP"
// Built-in fallback airframe when the Switchblade mod is absent: the side's
// Darter, flown as a one-way attack drone.
#define LM_FALLBACK_WEST    "B_UAV_01_F"
#define LM_FALLBACK_EAST    "O_UAV_01_F"
#define LM_FALLBACK_GUER    "I_UAV_01_F"
// Switchblade mod (workshop @Switchblade Loitering Munition, CfgPatches
// "switchblade"). Its airframes carry no warhead in config: its own Killed
// handler spawns one, so this addon names the matching one itself.
#define SWB_PATCH           "switchblade"
#define SWB_WEST            "B_SwitchBlade_600"
#define SWB_GUER            "I_SwitchBlade_600"
#define SWB_AT_WARHEAD      "SwitchBlade_AT_Warhead"
#define SWB_HE_WARHEAD      "SwitchBlade_40mm_HE_Warhead"

// A warhead set off at a target is put this far short of the first surface
// on the line to it and fused by script on the next frame - a missile warhead
// that has not flown its own fuseDistance would land as a dud if it touched
// anything first. It creeps at the target this slowly meanwhile, so even a
// slow frame cannot carry it onto the surface.
#define WARHEAD_STANDOFF    1
#define WARHEAD_CREEP       5
// A script fuze is sampled once a tick, and a busy server stretches a tick to
// two frames: so a fuze reaches out as far as this many ticks of flight.
#define FUZE_LOOKAHEAD_TICKS 2

// The air defence intercept's CBA setting that switches each threat family
// on, indexed by its family number (addons/adsite FAM_*, 0 = none).
#define ADS_FAMILY_SETTINGS ["", QEGVAR(adsite,threatArtillery), QEGVAR(adsite,threatRockets), QEGVAR(adsite,threatMissiles), QEGVAR(adsite,threatBombs)]

// Strike rules.
#define RULE_BOTH           0
#define RULE_VEHICLES       1
#define RULE_INFANTRY       2
#define LM_VEHICLE_KINDS    ["Car", "Tank", "StaticWeapon", "Ship"]
