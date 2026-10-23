#define COMPONENT support_air
#define COMPONENT_BEAUTIFIED Support Air
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_SUPPORT_AIR
    #define DEBUG_MODE_FULL
#endif
#ifdef DEBUG_SETTINGS_SUPPORT_AIR
    #define DEBUG_SETTINGS DEBUG_SETTINGS_SUPPORT_AIR
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// ---------------------------------------------------------------- provider --
// THE SUPPORT PROVIDER this addon registers with the support core
// (addons/support/README.md). Every asset id is "air:<n>", n the module's
// index in GVAR(entities); the row TYPE says which of the four modules it is.
#define SUPPORT_KIND        "air"

#define KIND_CAS            "cas"
#define KIND_TRANSPORT      "transport"
#define KIND_LOGISTICS      "logistics"
#define KIND_QRF            "qrf"

// Task tokens. "rtb" is the core's.
#define TASK_RTB            "rtb"
#define TASK_SAD            "SAD"
#define TASK_LOITER         "LOITER"
#define TASK_RUN            "ATTACK RUN"
#define TASK_PICKUP         "PICKUP"
#define TASK_LAND           "LAND"
#define TASK_LAND_OFF       "LAND_OFF"
#define TASK_MOVE           "MOVE"
#define TASK_EXTRACT        "EXTRACT"
#define TASK_LIFT           "LIFT"
#define TASK_ORBIT          "ORBIT"
#define TASK_FASTROPE       "FASTROPE"
#define TASK_HELOCAST       "HELOCAST"
#define TASK_PARADROP       "PARADROP"
#define TASK_SLING          "SLINGLOAD"
#define TASK_DROP           "DROP"
#define TASK_STATIC         "STATIC"
#define TASK_ASSAULT        "ASSAULT"

// Not a request: the leg home an EXTRACT and an RTB fly. Never declared.
#define TASK_HOME           "HOME"

// Where each asset type sits in the ASSET list. Transport 10, CAS 20 and
// artillery 30 are the core's README; these two go after them.
#define ORDER_TRANSPORT     10
#define ORDER_CAS           20
#define ORDER_LOGISTICS     40
#define ORDER_QRF           50

// --------------------------------------------------------------- steppers --
// PARAMETER SLOTS 20-31 ARE THIS PROVIDER'S (12-19 are support_fires'). Each
// is written by a stepper this provider declares on its own tasks and read by
// FUNC(readParam). A slot the requester never touched reads as the stepper's
// minimum - which is why every height/time stepper starts at "MODULE": index
// 0 means "what the module says".
#define SLOT_PASSES         20
#define SLOT_ORDNANCE       21
#define SLOT_RADIUS         22
#define SLOT_CAS_ALT        23
#define SLOT_HEIGHT         24
#define SLOT_SPEED          25
#define SLOT_ROE            26
#define SLOT_DROP_ALT       27
// 28 and 29 are retired (2026-10-19) and stay empty, so the slots after them
// keep their numbers.
#define SLOT_WAIT           30
// THE SECOND BLOCK, 40-49 (2026-10-20): the Simplex-style request options.
// 32-39 stay free for support_fires to grow into.
#define SLOT_DANGER         40
#define SLOT_LIGHTS         41
#define SLOT_APPROACH       42
#define SLOT_SIGNAL         43
#define SLOT_VIA            44
#define SLOT_LZ             45
#define SLOT_CONTENTS       46
#define SLOT_CRATE_SIGNAL   47
#define SLOT_JUMP_ALT       48
// The core's INGRESS and EGRESS slots (support README), shared with the CAS
// drones: the same point means the same thing on both.
#define SLOT_INGRESS        8
#define SLOT_EGRESS         9

// Value tables behind the index steppers. Entry 0 is the module's own value.
#define CAS_ALT_TABLE       [0, 300, 500, 800, 1200, 2000]
#define CAS_ALT_WORDS       ["MODULE", "300 M", "500 M", "800 M", "1200 M", "2000 M"]
#define HEIGHT_TABLE        [0, 40, 80, 150, 300]
#define HEIGHT_WORDS        ["MODULE", "40 M", "80 M", "150 M", "300 M"]
#define WAIT_TABLE          [0, 120, 300, 600, 1800]
#define WAIT_WORDS          ["MODULE", "2 MIN", "5 MIN", "10 MIN", "30 MIN"]
#define DROP_ALT_TABLE      [0, 150, 250, 400, 600]
#define DROP_ALT_WORDS      ["MODULE", "150 M", "250 M", "400 M", "600 M"]
#define JUMP_ALT_TABLE      [0, 150, 250, 400, 600]
#define JUMP_ALT_WORDS      ["MODULE", "150 M", "250 M", "400 M", "600 M"]

// Danger close: 0 holds any release with friendlies inside the module's
// Friendly Range of the aim point, 1 releases anyway.
#define DANGER_WORDS        ["NO", "YES"]
// Lights: index 0 is ON, the way Simplex commissions its transports.
#define LIGHTS_WORDS        ["ON", "OFF"]
// Final approach: 0 AUTO (straight in from wherever it is), then the bearing
// it comes FROM in 45-degree steps.
#define APPROACH_STEP       45
#define APPROACH_WORDS      ["AUTO", "FROM N", "FROM NE", "FROM E", "FROM SE", "FROM S", "FROM SW", "FROM W", "FROM NW"]
// Landing signal: what the crew looks for round the LZ on final and lands on.
#define SIGNAL_NONE         0
#define SIGNAL_ANY          1
#define SIGNAL_SMOKE        2
#define SIGNAL_IR           3
#define SIGNAL_FLARE        4
#define SIGNAL_WORDS        ["NONE", "ANY", "SMOKE", "IR STROBE", "FLARE"]
// Crate signal: index 0 is the module's, the rest a choice per request - the
// class each one sets off on the landed crate.
#define CRATE_SIGNAL_WORDS  ["MODULE", "SMOKE", "IR STROBE", "CHEMLIGHT", "FLARE", "NONE"]
#define CRATE_SIGNAL_CLASSES ["", "SmokeShellBlue", "B_IRStrobe", "Chemlight_blue", "F_40mm_White", ""]
// The module's Signal combo is the same table without MODULE: 0 smoke ... 4 none.
#define CRATE_SIGNAL_MODULE_OFFSET 1

// Speed and ROE are words, not numbers: index -> engine value.
#define SPEED_WORDS         ["NORMAL", "LIMITED", "FULL"]
#define ROE_WORDS           ["RETURN FIRE", "FIRE AT WILL", "HOLD FIRE"]
#define ROE_COMBAT          ["GREEN", "YELLOW", "BLUE"]

#define RADIUS_MIN          400
#define RADIUS_MAX          1500
// The tightest orbit a fixed-wing CAS aircraft is asked to fly (m).
#define PLANE_ORBIT_MIN     1000
#define RADIUS_STEP         100
#define PASSES_MIN          1
#define PASSES_MAX          4

// [label, slot, step, min, max, display, list, bar] - the core's stepper shape.
#define STEP_PASSES         ["PASSES", SLOT_PASSES, 1, PASSES_MIN, PASSES_MAX, "%1", [], true]
#define STEP_CAS_ALT        ["ALTITUDE", SLOT_CAS_ALT, 1, 0, 5, CAS_ALT_WORDS, [], true]
#define STEP_HEIGHT         ["HEIGHT", SLOT_HEIGHT, 1, 0, 4, HEIGHT_WORDS, [], true]
#define STEP_SPEED          ["SPEED", SLOT_SPEED, 1, 0, 2, SPEED_WORDS, [], false]
#define STEP_ROE            ["DOOR GUNS", SLOT_ROE, 1, 0, 2, ROE_WORDS, [], false]
#define STEP_WAIT           ["WAIT", SLOT_WAIT, 1, 0, 4, WAIT_WORDS, [], true]
#define STEP_DROP_ALT       ["DROP HEIGHT", SLOT_DROP_ALT, 1, 0, 4, DROP_ALT_WORDS, [], true]
// Field 8 is the map aid TAC//SUPPORT draws for the value (support README):
// RADIUS is the effect area, APPROACH a bearing into the point, DANGER CLOSE
// the friendly-range ring (its metres put in per asset by FUNC(tasks)).
#define STEP_RADIUS         ["RADIUS", SLOT_RADIUS, RADIUS_STEP, RADIUS_MIN, RADIUS_MAX, "%1 M", [], true, ["radius"]]
#define STEP_DANGER         ["DANGER CLOSE", SLOT_DANGER, 1, 0, 1, DANGER_WORDS, [], false, ["ring", 0]]
#define STEP_LIGHTS         ["LIGHTS", SLOT_LIGHTS, 1, 0, 1, LIGHTS_WORDS, [], false]
#define STEP_APPROACH       ["APPROACH", SLOT_APPROACH, 1, 0, 8, APPROACH_WORDS, [], false, ["bearing", APPROACH_STEP]]
#define STEP_SIGNAL         ["LZ SIGNAL", SLOT_SIGNAL, 1, 0, 4, SIGNAL_WORDS, [], false]
#define STEP_JUMP_ALT       ["JUMP HEIGHT", SLOT_JUMP_ALT, 1, 0, 4, JUMP_ALT_WORDS, [], true]
#define STEP_CRATE_SIGNAL   ["CRATE SIGNAL", SLOT_CRATE_SIGNAL, 1, 0, 5, CRATE_SIGNAL_WORDS, [], false]

// POINT DECLARATIONS - task declaration field 7, [label, slot, hint,
// required, many, leg] (support README). "in" legs are flown before the
// task point, "out" legs after it.
#define POINT_INGRESS       ["INGRESS", SLOT_INGRESS, "AUTO - FROM THE AIRBASE SIDE", false, 1, "in"]
#define POINT_EGRESS        ["EGRESS", SLOT_EGRESS, "AUTO - STRAIGHT THROUGH", false, 1, "out"]
#define VIA_MAX             4
#define POINT_VIA           ["VIA", SLOT_VIA, "DIRECT - CLICK TO ADD LEGS", false, VIA_MAX, "in"]
#define POINT_LZ            ["LZ", SLOT_LZ, "REQUIRED - CLICK THE MAP", true, 1, "out"]
#define POINT_SET_DOWN      ["SET DOWN", SLOT_LZ, "REQUIRED - CLICK THE MAP", true, 1, "out"]

// ------------------------------------------------------- task declarations --
// [token, label, meta, guidance, steppers, needsPoint, pointLabel]. The
// ORDNANCE stepper is per airframe and added by FUNC(tasks); these are the
// static shapes. The point label is what TAC//SUPPORT calls the one point
// the task flies to - TARGET when a task does not say (the CAS tasks).
#define DECL_SAD     [TASK_SAD, "SAD", "SEEK & DESTROY", "Holds over the grid and strikes what is painted or known inside the radius; a new SAD or LOITER on station moves it", [STEP_RADIUS, STEP_CAS_ALT, STEP_DANGER], true, "", [POINT_INGRESS, POINT_EGRESS]]
#define DECL_LOITER  [TASK_LOITER, "LOITER", "", "Orbits the grid weapons tight until its time on station runs out; a new SAD or LOITER on station moves it", [STEP_RADIUS, STEP_CAS_ALT], true, "", [POINT_INGRESS, POINT_EGRESS]]
#define DECL_RUN     [TASK_RUN, "ATTACK RUN", "", "Runs in on the ingress and makes the passes set - laser or smoke first, else the grid - then leaves on the egress", [STEP_PASSES, STEP_CAS_ALT, STEP_DANGER], true, "", [POINT_INGRESS, POINT_EGRESS]]

// Every transport task flies the same way between points - height, speed,
// door guns, lights - and may be routed through VIA legs; the ones that end
// on the ground or in a hover take a final approach, and the landings a
// signal to land on.
#define STEPS_FLY    STEP_HEIGHT, STEP_SPEED, STEP_ROE, STEP_LIGHTS
#define STEPS_LAND   STEPS_FLY, STEP_APPROACH, STEP_SIGNAL
#define DECL_PICKUP  [TASK_PICKUP, "PICKUP", "", "Lands at the grid - on you without one - engine running, and waits", [STEPS_LAND], false, "PICKUP", [POINT_VIA]]
#define DECL_LAND    [TASK_LAND, "LAND", "", "Lands at the grid, puts its passengers out and waits engine running", [STEPS_LAND], true, "LZ", [POINT_VIA]]
#define DECL_LAND_OFF [TASK_LAND_OFF, "LAND ENG OFF", "", "Lands at the grid and shuts down", [STEPS_LAND], true, "LZ", [POINT_VIA]]
#define DECL_MOVE    [TASK_MOVE, "HOVER", "", "Flies to the grid and holds a hover until the next order", [STEPS_FLY, STEP_APPROACH], true, "HOVER POINT", [POINT_VIA]]
#define DECL_EXTRACT [TASK_EXTRACT, "EXTRACT", "", "Lands at the grid - on you without one - waits for your group, then flies it to base", [STEPS_LAND, STEP_WAIT], false, "PICKUP", [POINT_VIA]]
#define DECL_LIFT    [TASK_LIFT, "PICKUP > LZ", "", "Lands at the pickup - on you without one - waits for your group, flies it to the LZ and puts it out", [STEPS_LAND, STEP_WAIT], false, "PICKUP", [POINT_VIA, POINT_LZ]]
#define DECL_ORBIT   [TASK_ORBIT, "LOITER", "", "Orbits the grid at the radius until the next order", [STEPS_FLY, STEP_RADIUS], true, "ORBIT POINT", [POINT_VIA]]
#define DECL_FASTROPE [TASK_FASTROPE, "FASTROPE", "", "Hovers over the grid with the ropes out until the cabin is empty or the wait is up, then holds the hover", [STEPS_FLY, STEP_APPROACH, STEP_WAIT], true, "ROPE POINT", [POINT_VIA]]
#define DECL_HELOCAST [TASK_HELOCAST, "HELOCAST", "", "Comes down to the water at the grid and drifts while the cabin goes out, then climbs back to a hover", [STEPS_FLY, STEP_APPROACH, STEP_WAIT], true, "CAST POINT", [POINT_VIA]]
#define DECL_PARADROP [TASK_PARADROP, "PARADROP", "", "Crosses the drop zone at the jump height and puts the whole cabin out on static lines, then returns to base", [STEP_JUMP_ALT, STEP_SPEED, STEP_ROE, STEP_LIGHTS], true, "DROP ZONE", [POINT_VIA]]
#define DECL_SLING    [TASK_SLING, "SLINGLOAD", "", "Hooks the nearest load it can lift at the grid, carries it to the set-down point and lowers it", [STEPS_FLY], true, "LOAD", [POINT_VIA, POINT_SET_DOWN]]

#define DECL_DROP_CHUTE [TASK_DROP, "SUPPLY DROP", "PARACHUTE", "Flies from base over the grid and puts a crate out under a chute", [STEP_DROP_ALT, STEP_CRATE_SIGNAL], true, "DROP POINT"]
#define DECL_DROP_SLING [TASK_DROP, "SUPPLY DROP", "SLING", "Flies from base with a crate on the hook and sets it down on the grid", [STEP_CRATE_SIGNAL], true, "DROP POINT"]

#define DECL_STATIC  [TASK_STATIC, "STATIC LINE", "", "Low slow pass over the grid; chutes open on exit", [], true, "DROP ZONE"]
#define DECL_ASSAULT [TASK_ASSAULT, "AIR ASSAULT", "", "Helicopter puts the squad down at the grid - fast-rope where it can - and leaves", [], true, "LZ"]

#define SUPPORT_TYPES [ \
    [KIND_TRANSPORT, "TRANSPORT", "AIRFRAME", "AIRFRAMES", ORDER_TRANSPORT, [DECL_PICKUP, DECL_LAND, DECL_LAND_OFF, DECL_MOVE, DECL_EXTRACT, DECL_LIFT, DECL_ORBIT, DECL_FASTROPE, DECL_HELOCAST, DECL_PARADROP, DECL_SLING]], \
    [KIND_CAS, "CAS", "AIRFRAME", "AIRFRAMES", ORDER_CAS, [DECL_SAD, DECL_LOITER, DECL_RUN]], \
    [KIND_LOGISTICS, "LOGISTICS", "DROP", "DROPS", ORDER_LOGISTICS, [DECL_DROP_CHUTE]], \
    [KIND_QRF, "QRF", "SQUAD", "SQUADS", ORDER_QRF, [DECL_STATIC, DECL_ASSAULT]] \
]

// ------------------------------------------------- verdict and map shapes --
// THE VERDICT BEFORE CONFIRM (FUNC(preview)) estimates its ETA at this share
// of the airframe's top speed (config maxSpeed, km/h) for each SPEED word,
// indexed like SPEED_WORDS: NORMAL, LIMITED, FULL. Estimates of what the AI
// holds, not measurements (FUNC(flightTime)).
#define ETA_SHARES          [0.7, 0.35, 0.9]
#define SPEED_NORMAL        0
#define SPEED_FULL          2
// km/h in one m/s.
#define KMH_PER_MS          3.6
// The labels of the plan the board draws (row field 8) that are not a task
// token: the CAS legs (FUNC(casLaunch)) and the leg home (FUNC(homeTick),
// FUNC(transportPlan)). FUNC(overlay) finds the legs by them.
#define PLAN_IN             "IN"
#define PLAN_OUT            "OUT"
#define PLAN_BASE           "BASE"
#define PLAN_EGRESS         "EGRESS"

// ------------------------------------------------------------------ status --
#define STATUS_IDLE         "idle"
#define STATUS_COOLDOWN     "cooldown"
#define STATUS_EXPENDED     "expended"
#define STATUS_LAUNCHING    "launching"
#define STATUS_REPLACING    "replacing"

// ----------------------------------------------------------------- respawn --
// Respawn Delay -1: a lost aircraft is the asset lost, for good.
#define RESPAWN_NEVER       -1
// Cooldown Trigger: 0 when the aircraft is home (or gone), 1 at the request.
#define COOLDOWN_AT_END     0
#define COOLDOWN_AT_START   1
// A wreck this close to the stand is cleared before the replacement is set
// down on it.
#define STAND_CLEAR         30

// ---------------------------------------------------------------- flying --
// The watch every sortie runs on, seconds.
#define AIR_TICK            1
// A sortie that has not finished in this long is written off and swept,
// whatever it is doing - a stuck aircraft must not hold its asset for ever.
#define SORTIE_TIMEOUT      1800
// Close enough to the module to count as home.
#define HOME_RING           600
// Close enough to a transport point to start landing or hovering.
#define ARRIVE_RING         250
// How far around a requested landing point a clear patch is searched for.
#define LZ_SEARCH           80
// The invisible pad a helicopter is told to land on.
#define LZ_PAD              "Land_HelipadEmpty_F"
// Settled on the ground: below this speed (km/h) and touching it.
#define SETTLED_SPEED       3
// How long a landing may take before it is tried again.
#define LANDING_PATIENCE    120
// Height a helicopter flies to the module at when it was not told one.
#define HOME_HEIGHT         120
// Final approach: the leg flown into the point on the requested bearing (m).
#define APPROACH_LEG        400
// Landing signal: searched for round the LZ from this far out, inside this
// radius of it (m).
#define SIGNAL_LOOK         800
#define SIGNAL_RADIUS       300
// The classes each signal word answers to.
#define SIGNAL_SMOKE_CLASSES ["SmokeShell"]
#define SIGNAL_IR_CLASSES   ["IRStrobeBase", "ACE_IR_Strobe_Effect"]
#define SIGNAL_FLARE_CLASSES ["FlareCore", "F_40mm_White"]

// CAS
// The ring an attack run releases in - the aircraft covers a hundred metres a
// tick, a point would be stepped over.
#define CAS_RELEASE_RING    700
// How often a SAD looks for something to hit, seconds.
#define CAS_SAD_EVERY       20
// Within this of the grid an orbit counts as on station.
#define CAS_STATION_EXTRA   1200
// A helicopter's working height is held under this, whatever was asked.
#define HELI_CEILING        400
// Class aircraft never appear closer to the target than this, whatever the
// ingress point - a jet needs room to line up.
#define INGRESS_FLOOR       2000
// Said this long before time on station runs out.
#define STATION_WARNING     60
// How close (m) to its ingress point a synced aircraft turns in.
#define CAS_ENTRY_RING      800

// LOGISTICS
// Height a sling load is carried at and set down from.
#define SLING_CRUISE        60
#define SLING_SET_DOWN      12
// How close over the grid the hook is cut.
#define SLING_RING          40
// How long it may hover over the grid before the load is cut anyway.
#define SLING_PATIENCE      90

// QRF
// Seconds between jumpers leaving the aircraft.
#define JUMP_INTERVAL       0.7
// Static line: the chute opens this long after exit.
#define STATIC_OPEN_DELAY   1
// The static-line canopy - vanilla, round, not steered.
#define CHUTE_ROUND         "NonSteerable_Parachute_F"
// Jumper watch, seconds - often, so the canopy opens on time.
#define CHUTE_TICK          0.1
// Height a helicopter flies an air assault at, and the hover it fast-ropes from.
#define ASSAULT_CRUISE      100
#define FASTROPE_HOVER      18
// How long the squad has to get out of a landed helicopter before it lifts.
#define DISMOUNT_PATIENCE   60
// How long jumpers have to reach the ground before the squad is handed its
// task anyway.
#define DESCENT_PATIENCE    900

// TRANSPORT TASKS
// Helocast: height over the water and the drift speed (km/h) it holds.
#define HELOCAST_HEIGHT     3
#define HELOCAST_SPEED      10
// Slingload: how far round the load point a liftable object is looked for,
// and the hover it is hooked from.
#define SLING_SEARCH        80
#define SLING_HOOK_HEIGHT   14
// What a load is looked for among round the load point - the hook
// (FUNC(transportArrive)) and the verdict before CONFIRM (FUNC(preview)).
#define SLING_LOAD_KINDS    ["AllVehicles", "ReammoBox_F", "Cargo_base_F"]
// FAST-ROPING UNDER requireRopeItems. addons/cba_settings forces
// ace_fastroping_requireRopeItems on, and with it ACE offers its "Deploy
// ropes" action only to a man holding a rope item or in a helicopter that
// carries one in its cargo (ace_fastroping_fnc_canDeployRopes reads
// itemCargo). ACE's own AI deploy (ace_fastroping_fnc_deployAI, the one the
// FASTROPE task calls) names no rope and skips the check - so the item is
// for the players in the cabin. A transport that may fast-rope is stocked
// with ROPE_STOCK of ROPE_CLASS (FUNC(stockRopes)). Checked against ACE
// 3.21.2 (ace_logistics_rope CfgWeapons: ACE_rope3 to ACE_rope36 under
// ACE_ropeBase); 36.6 m is the longest, the one ACE's default deploy action
// names, and well over FASTROPE_HOVER.
#define ROPE_CLASS          "ACE_rope36"
#define ROPE_STOCK          2
// Over a hover point: this close (m) and this slow (km/h).
#define HOVER_RING          40
#define HOVER_SPEED         10
// Paradrop: the green light comes on this far (m) short of the drop zone.
#define PARADROP_LEAD       150
