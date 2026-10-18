#define COMPONENT adsite
#define COMPONENT_BEAUTIFIED Air Defence Intercept
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_ADSITE
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_ADSITE
    #define DEBUG_SETTINGS DEBUG_SETTINGS_ADSITE
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// REWRITTEN 2026-10-14 FOR A HARD PERFORMANCE BUDGET. The first adsite ran a
// picture every 0.25 s per Site (nearObjects per munition family over km-scale
// radii) and a 0-delay fuse PFH, and the game ran at ~4 FPS. Nothing here scans:
// units register on their own creation, threats arrive on their own Fired
// event, and the one engagement PFH exists only while a threat is in the air.

// ---- the budget (README "Performance budget") ------------------------------
// The engagement beat. A shell is in the air for tens of seconds; five looks a
// second is far more than a crew's reaction needs.
#define ADS_TICK 0.15
// At most this many threats are held at once - a barrage of a hundred rockets
// costs what sixteen do. The rest land unopposed (and are counted).
#define ADS_THREAT_CAP 16
// Unit-against-threat feasibility tests per pass, at most. What does not fit
// is looked at next pass (the start rotates).
#define ADS_EVAL_CAP 64
// Engagements started per pass, at most.
#define ADS_ASSIGN_CAP 8
// A pass slower than this (ms) logs a WARNING, at most once per ADS_WARN_GAP s.
#define ADS_WARN_MS 2
#define ADS_WARN_GAP 30
// The firing machine's projectile map is pruned of landed rounds above this.
#define ADS_OWNED_CAP 64

// ---- threat families, per ammo class (FUNC(family)) ------------------------
#define FAM_NONE 0
#define FAM_ARTILLERY 1
#define FAM_ROCKET 2
#define FAM_MISSILE 3
#define FAM_BOMB 4
// A shell is artillery when its ammo says artilleryLock, or it is at least
// this heavy (an 82 mm mortar round is hit 165, a 40 mm grenade 80).
#define ADS_ARTY_MIN_HIT 150
// ...and leaves the tube at least this steep (degrees): a tank's direct-fire HE
// round is flat, a howitzer's or a mortar's is not.
#define ADS_ARTY_PITCH 15
// A missile with this airLock is an AA missile - an interceptor, not a threat.
#define ADS_AA_LOCK 2
// Ammo with no speed of its own in config is taken to fly this fast (m/s).
#define ADS_DEFAULT_SPEED 600

// ---- impact prediction (FUNC(predict)) -------------------------------------
#define ADS_GRAVITY 9.81
// Terrain-height refinements of the ballistic landing point.
#define ADS_PREDICT_PASSES 2
// A threat landing sooner than this (s) cannot be engaged by anything; one
// landing later than this is not worth holding a slot for.
#define ADS_TTI_MIN 3
#define ADS_TTI_MAX 240
#define MODEL_BALLISTIC 0
#define MODEL_LINEAR 1

// ---- a threat, an array (FUNC(threat)) -------------------------------------
#define T_ID 0
#define T_OWNER 1
#define T_IMPACT 2
#define T_TIMPACT 3
#define T_MODEL 4
#define T_P0 5
#define T_V0 6
#define T_T0 7
#define T_CANDS 8
#define T_UNIT 9
#define T_RESOLVE 10
#define T_FAMILY 11

// ---- an AD unit, an array in GVAR(units) (FUNC(register)) -----------------
#define U_VEH 0
#define U_GUN 1
#define U_MISSILE 2
#define U_RADIUS 3
#define U_CHANCE 4
#define U_AREA 5
#define U_BUSY 6

// ---- what makes a vehicle air defence (FUNC(profile)) ----------------------
// A gun round at least this heavy (CfgAmmo hit) - every rifle and MG bullet
// has airLock 1, so airLock alone would make every armed car air defence. A
// 20 mm AA round is 60, a 12.7 mm ball 30.
#define ADS_GUN_HIT 40
// A gun that fires faster than this (s between rounds) is a CIWS and needs no
// radar of its own; a slower AA gun counts only on a radar-carrying vehicle.
#define ADS_CIWS_RELOAD 0.03
// A missile's average speed over its flight, as a share of its top speed -
// it starts from rest.
#define ADS_MISSILE_AVG 0.7

// ---- engagement (FUNC(plan), FUNC(fire)) -----------------------------------
// From assignment to the round leaving: the crew's reaction plus the turret
// slewing onto the aim point (FUNC(fire) waits ADS_SLEW of it).
#define ADS_REACTION 2
#define ADS_SLEW 1.5
// An intercept must happen at least this long before the predicted impact.
#define ADS_INTERCEPT_MARGIN 1
// The inner layer: guns and CIWS take a threat only this close (s) to impact;
// missiles take it any time they can reach it.
#define ADS_INNER_WINDOW 8
// Intercept-time refinements of the lead point.
#define ADS_PLAN_PASSES 2
// A gun's burst: this many forceWeaponFire calls, this far apart (s).
#define ADS_BURST_ROUNDS 12
#define ADS_BURST_GAP 0.05

// ---- protect radius --------------------------------------------------------
// A unit whose weapons say no range at all still protects this much.
#define ADS_RADIUS_MIN 500

// ---- targeting modes, per vehicle (FUNC(setMode)) --------------------------
#define ADS_MODE_OFF "off"
#define ADS_MODE_RANDOM "random"
#define ADS_MODE_CLOSEST "closest"
#define ADS_MODE_HIGHEST "highest"
#define ADS_MODES [ADS_MODE_OFF, ADS_MODE_RANDOM, ADS_MODE_CLOSEST, ADS_MODE_HIGHEST]
#define ADS_MODE_NAMES ["Off", "Random", "Closest threat", "Highest threat"]
#define ADS_MODE_DEFAULT ADS_MODE_CLOSEST

// ---- alarms (FUNC(alarm)) --------------------------------------------------
// The base game's own alarm sounds, a3\sounds_f\sfx. Index 0 is Off.
#define ADS_ALARMS ["", "A3\Sounds_F\sfx\alarm.wss", "A3\Sounds_F\sfx\alarm_blufor.wss", "A3\Sounds_F\sfx\alarm_opfor.wss", "A3\Sounds_F\sfx\alarm_independent.wss", "A3\Sounds_F\sfx\alarm_3.wss", "A3\Sounds_F\sfx\siren.wss"]
#define ADS_ALARM_NAMES ["Off", "Air raid", "BLUFOR alarm", "OPFOR alarm", "Independent alarm", "Alarm (short)", "Siren"]
#define ADS_ALARM_INDICES [0, 1, 2, 3, 4, 5, 6]
#define ADS_SPEAKERS ["Land_Loudspeakers_F", "Land_PortableSpeakers_01_F"]
// Loudspeakers this close to an area's first unit play its alarm - looked up
// ONCE, when the area is made.
#define ADS_SPEAKER_RANGE 600
#define ADS_ALARM_VOLUME 3
#define ADS_ALARM_DISTANCE 1500
// Automatic units of one config side share an alarm area per grid cell this
// big, so a cluster of guns sounds once, not once each.
#define ADS_AREA_CELL 1000

// ---- player actions (FUNC(actions)) ----------------------------------------
#define ADS_ACTION_RANGE 8
#define ADS_ACTION_PRIORITY 1.5
#define ADS_ICON "\a3\ui_f\data\map\markers\nato\b_antiair.paa"

// Sides' relation under which a shooter is hostile (getFriend).
#define ADS_FRIEND 0.6
