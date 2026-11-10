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

// The server's machine id - an order goes there by remoteExec (review S6).
#define SERVER_OWNER        2

// ---------------------------------------------------------------- provider --
// THE SUPPORT PROVIDER this addon registers with the support core
// (addons/support/README.md). Every asset id is "air:<n>", n the module's
// index in GVAR(entities); the row TYPE says which of the three modules it
// is. The Logistics Drop and its "logistics" type moved to
// addons/support_logistics (2026-11-01).
#define SUPPORT_KIND        "air"
// A NEW TASK IN THE THREAD (2026-11-02, the provider's "threadCards"): a new
// CAS REQUEST in a strike thread (FUNC(casRetask), the answer to FURTHER
// TASKING?), and a NEXT LIFT - any transport card - in a lift thread
// (FUNC(liftReply) "task", the answer to HOLD, RTB OR NEXT LIFT?).
#define THREAD_LIFT_CARDS   ["pickup", "hlz", "extract", "casevac", "airdrop"]
#define THREAD_CARDS        [["cas", ["cas"]], ["onstation", ["cas"]], ["pickup", THREAD_LIFT_CARDS], ["hlz", THREAD_LIFT_CARDS], ["extract", THREAD_LIFT_CARDS], ["casevac", THREAD_LIFT_CARDS], ["airdrop", THREAD_LIFT_CARDS]]

#define KIND_CAS            "cas"
#define KIND_TRANSPORT      "transport"
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
#define TASK_STATIC         "STATIC"
#define TASK_ASSAULT        "ASSAULT"

// Not a request: the leg home an EXTRACT and an RTB fly. Never declared.
#define TASK_HOME           "HOME"

// Where each asset type sits in the ASSET list. Transport 10, CAS 20 and
// artillery 30 are the core's README; QRF goes after support_logistics' 40.
#define ORDER_TRANSPORT     10
#define ORDER_CAS           20
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
// 23 (ALTITUDE) and 24 (HEIGHT) are retired (2026-11-01) and stay empty: the
// support core's tactical flight sets every height (user: "nap of the earth
// for helos", "atack alt need to be 4k m atl").
#define SLOT_SPEED          25
#define SLOT_ROE            26
// 27 (DROP HEIGHT) went to support_logistics with the Logistics Drop
// (2026-11-01). 28 and 29 are retired (2026-10-19) and stay empty, so the
// slots after them keep their numbers.
#define SLOT_WAIT           30
// THE SECOND BLOCK, 40-49 (2026-10-20): the Simplex-style request options.
// 32-39 stay free for support_fires to grow into.
#define SLOT_DANGER         40
// 41 (LIGHTS) is retired (2026-11-01) and stays empty: every support aircraft
// is lit only over its own airfield (the support core's tactical lights).
#define SLOT_APPROACH       42
#define SLOT_SIGNAL         43
#define SLOT_VIA            44
#define SLOT_LZ             45
// 46 (CONTENTS, retired) and 47 (CRATE SIGNAL, now MARKING) went to
// support_logistics with the Logistics Drop (2026-11-01).
#define SLOT_JUMP_ALT       48
// The core's INGRESS and EGRESS slots (support README), shared with the CAS
// drones: the same point means the same thing on both.
#define SLOT_INGRESS        8
#define SLOT_EGRESS         9

// Value tables behind the index steppers. Entry 0 is the module's own value.
#define WAIT_TABLE          [0, 120, 300, 600, 1800]
#define WAIT_WORDS          ["MODULE", "2 MIN", "5 MIN", "10 MIN", "30 MIN"]
#define JUMP_ALT_TABLE      [0, 150, 250, 400, 600]
#define JUMP_ALT_WORDS      ["MODULE", "150 M", "250 M", "400 M", "600 M"]

// Danger close: 0 holds any release with friendlies inside the module's
// Friendly Range of the aim point, 1 releases anyway.
#define DANGER_WORDS        ["NO", "YES"]
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

// Speed and ROE are words, not numbers: index -> engine value.
#define SPEED_WORDS         ["NORMAL", "LIMITED", "FULL"]
#define ROE_WORDS           ["RETURN FIRE", "FIRE AT WILL", "HOLD FIRE"]
#define ROE_COMBAT          ["GREEN", "YELLOW", "BLUE"]

#define RADIUS_MIN          400
#define RADIUS_MAX          1500
// The orbit a fixed-wing CAS aircraft flies at its off-map hold (m) - wide,
// because slow and tight in a turn is a stall (RPT 2026-10-20).
#define FW_HOLD_ORBIT       3000
#define RADIUS_STEP         100
#define PASSES_MIN          1
#define PASSES_MAX          4

// [label, slot, step, min, max, display, list, bar] - the core's stepper shape.
#define STEP_PASSES         ["PASSES", SLOT_PASSES, 1, PASSES_MIN, PASSES_MAX, "%1", [], true]
#define STEP_SPEED          ["SPEED", SLOT_SPEED, 1, 0, 2, SPEED_WORDS, [], false]
#define STEP_ROE            ["DOOR GUNS", SLOT_ROE, 1, 0, 2, ROE_WORDS, [], false]
#define STEP_WAIT           ["WAIT", SLOT_WAIT, 1, 0, 4, WAIT_WORDS, [], true]
// Field 8 is the map aid TAC//SUPPORT draws for the value (support README):
// RADIUS is the effect area, APPROACH a bearing into the point, DANGER CLOSE
// the friendly-range ring (its metres put in per asset by FUNC(tasks)).
#define STEP_RADIUS         ["RADIUS", SLOT_RADIUS, RADIUS_STEP, RADIUS_MIN, RADIUS_MAX, "%1 M", [], true, ["radius"]]
#define STEP_DANGER         ["DANGER CLOSE", SLOT_DANGER, 1, 0, 1, DANGER_WORDS, [], false, ["ring", 0]]
#define STEP_APPROACH       ["APPROACH", SLOT_APPROACH, 1, 0, 8, APPROACH_WORDS, [], false, ["bearing", APPROACH_STEP]]
#define STEP_SIGNAL         ["LZ SIGNAL", SLOT_SIGNAL, 1, 0, 4, SIGNAL_WORDS, [], false]
#define STEP_JUMP_ALT       ["JUMP HEIGHT", SLOT_JUMP_ALT, 1, 0, 4, JUMP_ALT_WORDS, [], true]

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
#define DECL_SAD     [TASK_SAD, "SAD", "SEEK & DESTROY", "Holds over the grid and strikes what is painted or known inside the radius; a new SAD or LOITER on station moves it", [STEP_RADIUS, STEP_DANGER], true, "", [POINT_INGRESS, POINT_EGRESS]]
#define DECL_LOITER  [TASK_LOITER, "LOITER", "", "Orbits the grid weapons tight until its time on station runs out; a new SAD or LOITER on station moves it", [STEP_RADIUS], true, "", [POINT_INGRESS, POINT_EGRESS]]
#define DECL_RUN     [TASK_RUN, "ATTACK RUN", "", "Runs in on the ingress and makes the passes set - laser or smoke first, else the grid - then leaves on the egress", [STEP_PASSES, STEP_DANGER], true, "", [POINT_INGRESS, POINT_EGRESS]]
// A FIXED-WING ON STATION HOLDS OFF THE MAP (user, 2026-11-01): its SAD and
// LOITER say so, and its LOITER has no RADIUS - the orbit is FW_HOLD_ORBIT out
// there, not round the grid (FUNC(tasks)).
#define GUIDE_SAD_FW    "Holds 8 km off the map and comes in at 4000 m on what is painted or known inside the radius, then goes back to the hold; a new SAD or LOITER on station moves it"
#define GUIDE_LOITER_FW "Holds 8 km off the map weapons tight until its time on station runs out; a new SAD or LOITER on station moves it"
// The plan label of a fixed-wing's off-map hold (row field 8).
#define PLAN_HOLD           "HOLD"

// Every transport task flies the same way between points - nap of the earth,
// dark away from its airfield (the support core's tactical flight), at the
// speed and with the door guns asked - and may be routed through VIA legs;
// the ones that end on the ground or in a hover take a final approach, and
// the landings a signal to land on.
#define STEPS_FLY    STEP_SPEED, STEP_ROE
#define STEPS_LAND   STEPS_FLY, STEP_APPROACH, STEP_SIGNAL
#define DECL_PICKUP  [TASK_PICKUP, "PICKUP", "", "Lands at the grid - on you without one - engine running, and waits", [STEPS_LAND], false, "PICKUP", [POINT_VIA]]
#define DECL_LAND    [TASK_LAND, "LAND", "", "Lands at the grid, puts its passengers out and waits engine running", [STEPS_LAND], true, "LZ", [POINT_VIA]]
#define DECL_LAND_OFF [TASK_LAND_OFF, "LAND ENG OFF", "", "Lands at the grid and shuts down", [STEPS_LAND], true, "LZ", [POINT_VIA]]
#define DECL_MOVE    [TASK_MOVE, "HOVER", "", "Flies to the grid and holds a hover until the next order", [STEPS_FLY, STEP_APPROACH], true, "HOVER POINT", [POINT_VIA]]
#define DECL_EXTRACT [TASK_EXTRACT, "EXTRACT", "", "Holds a low hover at the grid - on you without one - never touching down, waits for your group, then flies it to base", [STEPS_LAND, STEP_WAIT], false, "PICKUP", [POINT_VIA]]
#define DECL_LIFT    [TASK_LIFT, "PICKUP > LZ", "", "Lands at the pickup - on you without one - and shuts down, waits for your group, then starts up, flies it to the LZ and puts it out", [STEPS_LAND, STEP_WAIT], false, "PICKUP", [POINT_VIA, POINT_LZ]]
#define DECL_ORBIT   [TASK_ORBIT, "LOITER", "", "Orbits the grid at the radius until the next order", [STEPS_FLY, STEP_RADIUS], true, "ORBIT POINT", [POINT_VIA]]
#define DECL_FASTROPE [TASK_FASTROPE, "FASTROPE", "", "Hovers over the grid with the ropes out until the cabin is empty or the wait is up, then holds the hover", [STEPS_FLY, STEP_APPROACH, STEP_WAIT], true, "ROPE POINT", [POINT_VIA]]
#define DECL_HELOCAST [TASK_HELOCAST, "HELOCAST", "", "Comes down to the water at the grid and drifts while the cabin goes out, then climbs back to a hover", [STEPS_FLY, STEP_APPROACH, STEP_WAIT], true, "CAST POINT", [POINT_VIA]]
#define DECL_PARADROP [TASK_PARADROP, "PARADROP", "", "Crosses the drop zone at the jump height and puts the whole cabin out on static lines, then returns to base", [STEP_JUMP_ALT, STEP_SPEED, STEP_ROE], true, "DROP ZONE", [POINT_VIA]]
#define DECL_SLING    [TASK_SLING, "SLINGLOAD", "", "Hooks the nearest load it can lift at the grid, carries it to the set-down point and lowers it", [STEPS_FLY], true, "LOAD", [POINT_VIA, POINT_SET_DOWN]]

#define DECL_STATIC  [TASK_STATIC, "STATIC LINE", "", "Low slow pass over the grid; chutes open on exit", [], true, "DROP ZONE"]
#define DECL_ASSAULT [TASK_ASSAULT, "AIR ASSAULT", "", "Helicopter puts the squad down at the grid - fast-rope where it can - and leaves", [], true, "LZ"]

#define SUPPORT_TYPES [ \
    [KIND_TRANSPORT, "TRANSPORT", "AIRFRAME", "AIRFRAMES", ORDER_TRANSPORT, [DECL_PICKUP, DECL_LAND, DECL_LAND_OFF, DECL_MOVE, DECL_EXTRACT, DECL_LIFT, DECL_ORBIT, DECL_FASTROPE, DECL_HELOCAST, DECL_PARADROP, DECL_SLING]], \
    [KIND_CAS, "CAS", "AIRFRAME", "AIRFRAMES", ORDER_CAS, [DECL_SAD, DECL_LOITER, DECL_RUN]], \
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
// THE RESPAWN COUNT (user, 2026-11-02: "make sure there is a respawn count for
// each support, default no respawns"). Respawns n: n replacement airframes.
// Only an airframe LOST - destroyed, its crew dead, or disabled and written
// off (FUNC(writeOff)) - uses one (FUNC(lost), FUNC(replace)): the row reads
// REPLACING for the Respawn Delay, then the next tasking makes a new one. A
// virtual airframe going home and removed uses none. None left: the asset is
// gone - off the SUPPORT list (FUNC(assets)) and a card to its box answers
// WHY_NO_AIRFRAME. It folds in the CAS Sorties, the transport's Airframes
// Available, the QRF's Squads and the old Respawn Delay -1 "never".
#define MODULE_RESPAWNS     0
#define MODULE_RESPAWN_DELAY 300
#define WHY_NO_AIRFRAME     "UNABLE - NO AIRFRAME"

// ------------------------------------------------------ virtual until tasked --
// USER, 2026-11-02: "all support aircraft needs to be virtual till tasked, then
// they spawn in at alt over the support module location" (it replaced the same
// day's "on station from the start"). A module that flies a class (not one
// synced to an aircraft) has no airframe until a task is accepted; then it is
// made over the module at its flight level (FUNC(spawnAircraft),
// EFUNC(support,spawnAirborne)) - a helicopter nap of the earth, a fixed-wing
// at 4000 m - flies the task, comes back over the module and is removed there,
// virtual again (FUNC(homeTick)). The Response Delay and the CAS Ingress
// Distance are retired with it: a mission that set them still loads, the
// values are not read.
// Cooldown Trigger: 0 when the aircraft is home (or gone), 1 at the request.
#define COOLDOWN_AT_END     0
#define COOLDOWN_AT_START   1
// A wreck this close to a synced aircraft's stand is cleared before the
// replacement is set down on it.
#define STAND_CLEAR         30
// FUNC(writeOff)'s verdicts: flying, cannot fly but within FAULT_GRACE, lost.
#define WRITE_OFF_NONE      0
#define WRITE_OFF_PENDING   1
#define WRITE_OFF_DONE      2

// ---------------------------------------------------------------- flying --
// The watch every sortie runs on, seconds.
#define AIR_TICK            1
// A sortie that has not finished in this long is written off and swept,
// whatever it is doing - a stuck aircraft must not hold its asset for ever.
#define SORTIE_TIMEOUT      1800
// A transport that cannot fly (FUNC(flightFault)) is written off only when it
// has not flown for this long, s (2026-11-01: one tick was the verdict), and
// the hit points past FAULT_HIT_FLOOR are named in the RPT line.
#define FAULT_GRACE         10
#define FAULT_HIT_FLOOR     0.1
// Close enough to the module to count as home.
#define HOME_RING           600
// Close enough to a transport point to start landing or hovering.
#define ARRIVE_RING         250
// A HELICOPTER IS FLOWN THE WAY SIMPLEX SUPPORT SERVICES FLIES ONE (2026-11-05,
// the user's two runs, RPT 16:23 and 17:13: the UH-80 made over its module
// hovered with no waypoint on it; flight control modelled on how Simplex
// pilots a helicopter, no code of it used). No group waypoint. In transit the
// airframe itself is ordered (doMove), the order given again every
// HELI_ORDER_TICK s whenever the AI reports itself idle short of the point,
// done inside HELI_ORDER_RING m of it airborne and idle (FUNC(heliOrder),
// FUNC(heliOrderTick)). On the ground inside HELI_TAKEOFF_PAST m of a point -
// too near for the AI to lift off for - it is ordered that far past it first.
// A LOITER steps round the ring HELI_ORBIT_STEP deg at a time, the next point
// ordered once inside HELI_ORBIT_NEXT of the radius. HELI_STUCK_REISSUES
// orders in a row without the distance to the point shrinking HELI_PROGRESS m
// (the AI refusing nap of the earth over what is under it) climb it
// HELI_STUCK_CLIMB m, said in the RPT; an order given again is said at most
// every HELI_ORDER_LOG_S s. HELI_FAR is further than anything on the map.
#define HELI_ORDER_TICK     2
#define HELI_ORDER_RING     200
#define HELI_TAKEOFF_PAST   200
#define HELI_ORBIT_STEP     60
#define HELI_ORBIT_NEXT     0.6
#define HELI_STUCK_REISSUES 5
#define HELI_PROGRESS       20
#define HELI_STUCK_CLIMB    50
#define HELI_ORDER_LOG_S    30
// A busy AI no HELI_PROGRESS m closer for this long is ordered again too.
#define HELI_BUSY_STUCK_S   30
#define HELI_FAR            1e10
// A VTOL flies as a helicopter only inside VTOL_PLANE_RANGE m of its point -
// the take-off, the approach, the hover, the landing - and as a plane beyond
// it (user, 2026-11-08: "helo only in landing and take off, needs to use
// flight mode over distances over 1k"; FUNC(moveTo)).
#define VTOL_PLANE_RANGE    1000
// What a transport module may fly (FUNC(moduleTransport)).
#define TRANSPORT_KINDS     ["Helicopter", "VTOL_Base_F"]
// THE FLIGHT CONTROL (FUNC(heliTake), FUNC(heliFrame), FUNC(heliRelease)): the
// final approach, the hover and the landing are not the AI's. Each frame the
// airframe is moved by velocity (setVelocityTransformation to where its new
// velocity takes it, never a teleport - the men aboard ride it): towards its
// point at HELI_GAIN of the distance a second, no faster than the caller's cap
// (HELI_APPROACH_SPEED m/s for a landing), the velocity changed by at most
// HELI_ACCEL m/s each second, climbing no faster than HELI_CLIMB_MAX m/s,
// descending no faster than HELI_DESCENT_MAX, to its height at HELI_GAIN_Z of
// the difference a second. The height is held off whatever is under it: the
// surface HELI_LOOK_AHEAD_S s of flight ahead (lineIntersectsSurfaces from
// HELI_SCAN_UP m above its level down HELI_SCAN m) plus HELI_CLEARANCE m,
// easing to the point's own height inside HELI_SLOW_RING m of it; below that
// floor it slows to no less than HELI_SLOW_SHARE of the cap. The point's
// surface - ground, roof, deck, sea at HELI_SEA_Z ASL - is the highest thing
// from HELI_SURFACE_UP m above the terrain down. Reached: inside
// HELI_HOVER_RING m of the point and HELI_HOVER_BAND m of its height. A
// landing approaches a hover HELI_LAND_HOVER m over the pad, then comes down
// at HELI_LAND_GAIN of its height over what is under it (scanned from
// HELI_SCAN_BODY m above its placing point, the wheels - every position here
// is getPosASL, the format setVelocityTransformation takes; see FUNC(heliFrame))
// a second, between HELI_TOUCH_VZ
// and HELI_LAND_DESCENT_MAX m/s, and is down touching the ground or under
// HELI_TOUCH_HEIGHT m; on the ground the velocity is damped to
// HELI_SETTLE_DAMP each frame with HELI_SETTLE_PUSH m/s kept into the ground
// for HELI_SETTLE_S s, then the engine is set as asked: off, the airframe is
// handed back; on, it is held down the same way every frame until the next
// order or take. Attitude: nose down HELI_PITCH_PER_SPEED deg per m/s and
// HELI_PITCH_PER_ACCEL deg per m/s2 forward, banked HELI_BANK_PER_ACCEL deg
// per m/s2 sideways, within HELI_PITCH_LIMIT and HELI_BANK_LIMIT deg,
// following at HELI_ATTITUDE_RATE a second; the nose turns to the point at
// HELI_YAW_RATE deg/s while faster than HELI_TURN_SPEED m/s and further than
// HELI_TURN_DIST m from it, else holds. A frame longer than HELI_FRAME_MAX s
// counts as that, never shorter than HELI_FRAME_MIN; HELI_NO_DISTANCE m is
// no distance to go.
// NO RISE TO SLOW DOWN (user, 2026-11-08: "make sure helos and vtol do not do
// a large rise to slow down or gain alt to slow down"). The control keeps the
// speed it takes the airframe at (up to HELI_CARRY_MAX m/s) and brakes level:
// never faster than a stop at HELI_BRAKE m/s2 would allow over the distance
// left. It takes a transport HELI_TAKE_RING m out (FUNC(transportTick)) -
// before the AI's own braking flare, no further than SIGNAL_LOOK so the
// signal is looked for first - unless the LZ's circle and clearance come
// first. While the AI flies a rotary order, it is kept from climbing more than
// HELI_RISE_MARGIN m over the height it was told (FUNC(heliNoRise)).
#define HELI_CARRY_MAX      70
#define HELI_BRAKE          2.5
#define HELI_TAKE_RING      800
#define HELI_RISE_MARGIN    25
// ...over the terrain or sea under it, only inside HELI_NO_RISE_RING m of the
// point.
#define HELI_NO_RISE_RING   1500
// ...and only faster than HELI_NO_RISE_SPEED m/s across the ground - never a
// take-off or a hover.
#define HELI_NO_RISE_SPEED  15
// A VTOL (user, 2026-11-08: "vtol landing for pick up was way to slow"): taken
// VTOL_TAKE_RING m out, beyond VTOL_PLANE_RANGE, while still a plane at speed;
// it comes down from its cruise on a glide - up to VTOL_GLIDE m of descent per
// m of ground speed, never faster than VTOL_DESCENT_MAX m/s - not at
// HELI_DESCENT_MAX.
#define VTOL_TAKE_RING      1500
#define VTOL_GLIDE          0.35
#define VTOL_DESCENT_MAX    15
// ...and at least VTOL_DESCENT_SLOW m/s when slow over the point. Every
// airframe is flown from where the flight control put it last frame unless it
// was knocked further than HELI_HOLD_SNAP m (FUNC(heliFrame)).
// It is the plane only from VTOL_PLANE_MIN_ALT m over the ground: lower, it
// climbs out on the helicopter order first, for at most VTOL_CLIMB_S s
// (FUNC(moveTo), user, 2026-11-08: "crashed in to a moutaion on rtb").
#define VTOL_DESCENT_SLOW   8
#define HELI_HOLD_SNAP      10
#define VTOL_PLANE_MIN_ALT  100
#define VTOL_CLIMB_S        90
#define HELI_TAKE_TASKS     [TASK_PICKUP, TASK_LAND, TASK_LAND_OFF, TASK_EXTRACT, TASK_LIFT, TASK_FASTROPE, TASK_RAPPEL, TASK_HELOCAST, TASK_SLING, TASK_HOME]
#define HELI_APPROACH_SPEED 20
#define HELI_GAIN           0.25
#define HELI_GAIN_Z         0.5
#define HELI_ACCEL          5
#define HELI_CLIMB_MAX      6
#define HELI_DESCENT_MAX    4
#define HELI_LOOK_AHEAD_S   2
#define HELI_SCAN_UP        30
#define HELI_SCAN_BODY      2
#define HELI_SCAN           60
// How many hits a surface scan takes, so the airframe's own crew and what hangs
// from it can be skipped (2026-11-05) and the first other hit be the surface.
#define HELI_SCAN_HITS      6
// An RPT line this often (s) while the control holds an airframe.
#define HELI_LOG_S          5
#define HELI_CLEARANCE      15
#define HELI_SLOW_RING      150
#define HELI_SLOW_SHARE     0.3
#define HELI_SURFACE_UP     50
#define HELI_SEA_Z          0
#define HELI_HOVER_RING     4
#define HELI_HOVER_BAND     2
#define HELI_LAND_HOVER     10
#define HELI_LAND_GAIN      0.3
#define HELI_TOUCH_VZ       0.5
#define HELI_LAND_DESCENT_MAX 2.5
#define HELI_TOUCH_HEIGHT   0.3
#define HELI_SETTLE_DAMP    0.5
#define HELI_SETTLE_PUSH    -0.3
#define HELI_SETTLE_S       1.5
#define HELI_PITCH_PER_SPEED 0.3
#define HELI_PITCH_PER_ACCEL 2
#define HELI_BANK_PER_ACCEL 3
#define HELI_PITCH_LIMIT    12
#define HELI_BANK_LIMIT     15
#define HELI_ATTITUDE_RATE  3
#define HELI_YAW_RATE       40
#define HELI_TURN_SPEED     2
#define HELI_TURN_DIST      10
#define HELI_FRAME_MAX      0.1
#define HELI_FRAME_MIN      0.001
#define HELI_NO_DISTANCE    0.01
// setVelocityTransformation is given the one new state twice: nothing to
// interpolate, the factor is moot.
#define HELI_STATE_NOW      1
// Degrees round and half round, for the shortest turn to a heading.
#define HELI_FULL_TURN      360
#define HELI_HALF_TURN      180
// The control's phases (QGVAR(flight) "phase" on the airframe): on the way
// to the hover point, holding it, coming down, on the ground settling.
#define HELI_PHASE_APPROACH "approach"
#define HELI_PHASE_HOVER    "hover"
#define HELI_PHASE_LAND     "land"
#define HELI_PHASE_DOWN     "down"
// A gear that retracts (config gearRetracting) is put down for the landing.
// How often the pilot orders the gear down on a landing, from inside
// HELI_SLOW_RING m of the pad (FUNC(heliFrame)): the AI folds it again while it
// thinks it is flying, so once at the take is not enough.
#define HELI_GEAR_S         1
// How far around a requested landing point a clear patch is searched for.
#define LZ_SEARCH           80
// A CLEAR SPOT FOR THE ROTOR (2026-11-02, the user's RPT 07:37:53: RAVEN's
// main rotor destroyed on the ground before it had flown anywhere, nothing hit
// it, damage 0 - a rotor strike). findEmptyPosition fits the body, not the
// rotor disc. FUNC(clearSpot): nothing taller than ROTOR_DISC_LOW m (in the
// air, than its height less that) within the airframe's bounding radius plus
// ROTOR_MARGIN m; on the ground no water and no slope steeper than
// LANDING_FLAT_MIN (the up share of the ground's normal, about 16 deg). The
// nearest clear spot is searched in CLEAR_STEP m rings, CLEAR_BEARING_STEP deg
// apart: a helicopter's start (FUNC(spawnAircraft), out to CLEAR_SPAWN_SEARCH
// m), its stand when it is on the ground (FUNC(respawn), LZ_SEARCH) and every
// landing pad but the one home (FUNC(landAt), LZ_SEARCH). What blocks: the
// terrain object types and the mission object kinds below, never a man.
#define ROTOR_DISC_LOW      2
#define ROTOR_MARGIN        3
#define LANDING_FLAT_MIN    0.96
#define CLEAR_STEP          10
#define CLEAR_BEARING_STEP  45
#define CLEAR_FULL_CIRCLE   360
#define CLEAR_SPAWN_SEARCH  200
#define CLEAR_TERRAIN_TYPES ["TREE", "SMALL TREE", "BUILDING", "HOUSE", "CHURCH", "CHAPEL", "CROSS", "FUELSTATION", "HOSPITAL", "LIGHTHOUSE", "POWER LINES", "POWERSOLAR", "POWERWAVE", "POWERWIND", "TRANSMITTER", "WATERTOWER", "BUNKER", "FORTRESS", "FOUNTAIN", "VIEW-TOWER", "RUIN", "ROCK", "ROCKS", "SHIPWRECK", "STACK", "TOURISM", "WALL"]
#define CLEAR_OBJECT_KINDS  ["Static", "AllVehicles", "Thing"]
// THE SAFETY NET (2026-11-02): a helicopter whose only damage is a rotor
// (hit point names holding ROTOR_WORD), that nothing hit and that has not yet
// been HOME_RING m from its airfield, is repaired once a sortie and logged,
// not written off (FUNC(rotorRepair)).
#define ROTOR_WORD          "rotor"
// Settled on the ground: below this speed (km/h) and touching it.
#define SETTLED_SPEED       3
// How long a landing may take before it is tried again.
#define LANDING_PATIENCE    120
// THE SUPPORT CORE'S TACTICAL FLIGHT (user, 2026-11-01): the phases its
// EFUNC(support,flightHeight) and EFUNC(support,flyAt) answer for - nap of the
// earth for a helicopter, 4000 m for a fixed-wing - and "no height of its
// own" on a transport order (element 3), which flies the transit height.
#define FLY_TRANSIT         "transit"
#define FLY_STATION         "station"
#define FLY_ATTACK          "attack"
#define TASK_HEIGHT_NONE    0
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
// THE RELEASE IS A PASS (2026-11-05, user: "the back end should be based on
// simplex"): the CAS drones' pass (addons/cas, modelled on how Simplex
// Support Services flies a strafe; no code of it used) - lined up on the
// ingress bearing, dived on the aim, the salvo released on a solution,
// handed back - begun by FUNC(casStrike) and ticked by FUNC(casRun),
// FUNC(casTick) and FUNC(casJob). The 700 m release ring is gone with it.
// Turning out after a pass, it comes round once it is this share of the
// run-in distance from the grid.
#define OUT_SHARE           0.8
// How often a SAD looks for something to hit, seconds.
#define CAS_SAD_EVERY       20
// Within this of the grid an orbit counts as on station.
#define CAS_STATION_EXTRA   1200
// Said this long before time on station runs out.
#define STATION_WARNING     60
// How close (m) to its ingress point an aircraft turns in.
#define CAS_ENTRY_RING      800

// THE ASSET'S THREAD (2026-11-01, DESIGN_SUPPORT_MESSAGING steps 3 and 4 and
// 1.1): what the support core's card reader (EFUNC(support,readOrder)) calls
// a strike and a REQUEST ON STATION, and the one word its follow-up hook hands
// over for CLEARED HOT and for anything that ends the task.
#define ORDER_STRIKE        "strike"
#define ORDER_STATION       "station"
#define WORD_CLEARED        "cleared"
#define WORD_STOP           "stop"
// The CANTCO words (doc 5.2) this addon gives itself.
#define WHY_NO_TARGET       "NO TARGET LOCATION"
#define WHY_NOT_ON_STATION  "NOT ON STATION"
#define WHY_TASKED          "TASKED"
#define WHY_RTB             "RTB"
#define WHY_LOST            "LOST"
#define WHY_NO_STORES       "NO STORES"
#define WHY_DANGER_CLOSE    "DANGER CLOSE NOT ACKNOWLEDGED"
// A strike from station whose pass put nothing down (2026-11-05): broken off
// at the floor, never lined up, the store would not fire.
#define WHY_NO_RELEASE      "NO RELEASE"
// Why a station sortie closes its thread (doc 1.1, "off station: RTB, bingo,
// or the on-station thread closed").
#define OFF_RTB             "RTB"
#define OFF_BINGO           "BINGO"
#define OFF_WINCHESTER      "WINCHESTER"
// THE BDA SAID EGRESS (user, 2026-11-02: "reattack or egress"; EGRESS = LEAVE):
// it flies the strike's egress point - the card's Line 4 - and goes home, its
// threads closed with this. The BDA's decision words are the support core's.
#define OFF_EGRESS          "EGRESS - RTB"
#define BDA_REATTACK        "reattack"
#define BDA_EGRESS          "egress"
// The status words that say where a CAS aircraft is.
#define STATUS_ON_STATION   "on station"
#define STATUS_RTB          "rtb"
// The check-in a CAS aircraft files on station (user, 2026-11-02; the card is
// the support core's, EFUNC(support,checkIn)): its Line 7 remarks - a
// fixed-wing at its off-map hold, a helicopter over the grid, a helicopter's
// run held short of the target for CLEARED HOT.
#define CHECKIN_REMARKS_HOLD  "HOLDING OFF THE MAP, DARK"
#define CHECKIN_REMARKS_GRID  "OVER THE GRID, DARK"
#define CHECKIN_REMARKS_SHORT "HOLDING SHORT FOR CLEARED HOT"
#define SECONDS_PER_MINUTE  60
// The most of the target description a WILCO repeats.
#define DESCRIPTION_MAX     48
#define WILCO_SEP           " - "
// THE PROMPTS AND THE BDA (2026-11-01, DESIGN_SUPPORT_MESSAGING 5.4, step 5).
// What the support core's EFUNC(support,casPrompt) says, and the follow-up
// words a CAS module answers besides CLEARED HOT and the stops (RTB by its
// card sends the sortie home from a strike from station too).
#define CAS_IN              "in"
#define CAS_OFF             "off"
#define CAS_REATTACK        "reattack"
#define CAS_TASKING         "tasking"
#define CAS_BINGO           "bingo"
#define WORD_BDA            "bda"
#define WORD_NO             "no"
#define CARD_RTB            "rtb"
// BINGO: a sortie answering a thread says BINGO IN 2 MIN (FLASH) this long
// (s) before its time on station runs out, or when its fuel is down to
// CAS_BINGO_FUEL of a tank, and leaves CAS_BINGO_LEAD s later. CAS_BINGO_LEAD
// is the 2 MIN the support core's prompt says - keep them in step. (A
// transport's own bingo is FUNC(transportTick)'s.)
#define CAS_BINGO_LEAD      120
#define CAS_BINGO_FUEL      0.25
// ALL ATTACK (user, 2026-11-02: "add an all attack for the fixed flight where
// the drones also attack the target or targets in the area"; FUNC(allAttack)):
// the follow-up word, the escorts' target area round the target (m - the `cas`
// card gives none), what the asset says when it goes in, the NO ESCORTS
// prompt's word (the support core's casPrompt), and how long (s) the OFF after
// the jet's release waits for the drones to finish before it counts them.
#define WORD_ALL_ATTACK     "allattack"
#define ALL_ATTACK_RADIUS   300
#define ALL_ATTACK_IN       "ALL ATTACK - FLIGHT IN HOT"
#define CAS_NO_ESCORTS      "noescorts"
#define ALL_ATTACK_BDA_WAIT 120

// --- CAS (2026-11-09) --------------------------------------------------------
// THE MESSAGE TEMPLATES' CAS FLOW (docs/DESIGN_MESSAGE_TEMPLATES.md, the trees'
// tree 3), flown by a CAS module's aircraft: READBACK after the WILCO, IP
// INBOUND leaving for the IP, IN at the IP asking the clearance (CLEARED HOT,
// CONTINUE - a dry pass, ABORT; Type 3 CLEARED TO ENGAGE and ATTACK
// COMPLETE), ABORT then STATE INTENTIONS, the BDA's three picks, FRAGO until
// IP INBOUND, MOVE a new station, HOLD, the TOT. The words are the cas addon's
// (EFUNC(cas,casAsk)) so its drones say the same; these are its keys.
#define CAS_ASK_READBACK    "readback"
#define CAS_ASK_SEND_FRAGO  "sendfrago"
#define CAS_ASK_FRAGO_LATE  "fragolate"
#define CAS_ASK_IP_INBOUND  "ipinbound"
#define CAS_ASK_IN          "in"
#define CAS_ASK_COMPLETE    "attackcomplete"
#define CAS_ASK_INTENTIONS  "intentions"
#define CAS_ASK_LINE        "line"
#define CAS_IP_ETA          "ETA %1"
#define CAS_SAID_HOLDING    "HOLDING AT %1"
#define CAS_SAID_MOVING     "MOVING - STATION %1"
#define CAS_SAID_ABORTED    "ABORTED - NO RELEASE"
#define CAS_SAID_REATTACK   "RE-ATTACK - %1 %2 LEFT"
#define CAS_SAID_CONTINUE   "CONTINUING - DRY PASS, NO RELEASE"
// The words the support core hands over (EFUNC(support,srvFollowUp)).
#define WORD_CAS_CORRECT    "correct"
#define WORD_CAS_WRONG      "wrong"
#define WORD_CAS_ENGAGE     "clearedengage"
#define WORD_CAS_CONTINUE   "continue"
#define WORD_CAS_ABORT      "abort"
#define WORD_CAS_HOLD       "hold"
#define WORD_CAS_MOVE       "move"
#define WORD_CAS_FRAGO      "frago"
#define WORD_CAS_TASK       "task"
// The words threadReply takes for a CAS module's thread.
#define WORDS_CAS [WORD_CLEARED, WORD_ALL_ATTACK, WORD_STOP, WORD_BDA, WORD_NO, WORD_CAS_TASK, WORD_CAS_CORRECT, WORD_CAS_WRONG, WORD_CAS_ENGAGE, WORD_CAS_CONTINUE, WORD_CAS_ABORT, WORD_CAS_HOLD, WORD_CAS_MOVE, WORD_CAS_FRAGO]
// The readback's steps on a strike ("rb"): asked, read back right.
#define RB_ASKED            "asked"
#define RB_OK               "ok"
// The IP when the card gives none (m out from the target, on its side of
// it): a fixed-wing's, from the hold; a helicopter's is its run-in distance.
#define CAS_IP_DEFAULT      5000
// A dry pass (CONTINUE) turns back this far short of the target (m).
#define CAS_DRY_RING        800
// The TOT: the pass begins this many seconds before it (the dive).
#define CAS_TOT_LEAD        20
// The phases a strike from station is running in on, past IP INBOUND.
#define JOB_PHASES_IN       ["jobIn", "jobIp", "jobDry", "jobRun"]
// A MOVE's station is a LOITER sortie's (FUNC(casOrder)'s mode word).
#define CAS_MODE_LOITER     "loiter"
// THREAD_CARDS (above): a CAS REQUEST filed in a REQUEST ON STATION's thread
// tasks the aircraft from its station (2026-11-09, tree 3).

// SLINGLOAD (the transport task, FUNC(transportStep)).
// Height a sling load is set down from. It is carried at the support core's
// sling transit height (nap of the earth plus the rope and the load).
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
// The hover an air assault fast-ropes from; it flies there nap of the earth.
#define FASTROPE_HOVER      18
// THE ROPE INSERTION (user, 2026-11-08: "on insertion we also need to add a
// fast rope option ... helos and vtos need to come in to the insertion point as
// fast as possiable and leave quickly, so also add a simplex like repel"): the
// LIFT REQUEST's INSERT line (jmfsb_support INSERT_METHODS) - "rope" is ACE's
// fast rope where the airframe takes FRIES (FUNC(canRope)), else the rappel;
// "rappel" is this addon's own, any airframe (FUNC(rappelOut), FUNC(rappel) -
// Simplex's idea of ropes from the hover and men sliding down them; no code of
// it used). Flown in at FULL with the flight control's cap raised to
// INSERT_APPROACH_SPEED m/s; no LZ status, circle or clearance; ropes cut and
// gone on its EGRESS the moment the cabin is empty, or INSERT_ROPE_WAIT s
// after the ropes went out.
#define TASK_RAPPEL         "RAPPEL"
#define INSERT_APPROACH_SPEED 40
#define INSERT_ROPE_WAIT    90
// The rappel: a rope each side RAPPEL_SIDE m out from the airframe's centre,
// RAPPEL_ROPE_LENGTH m long, from a RAPPEL_HOVER m hover; a man out every
// RAPPEL_INTERVAL s, sides in turn, sliding down at RAPPEL_SPEED m/s, off the
// rope under RAPPEL_FOOT m - RAPPEL_MAX_S s at most, then put on the ground.
#define RAPPEL_HOVER        15
#define RAPPEL_SIDE         1.4
#define RAPPEL_ROPE_LENGTH  25
#define RAPPEL_INTERVAL     1
#define RAPPEL_SPEED        5
#define RAPPEL_FOOT         0.6
#define RAPPEL_MAX_S        20
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

// THE BOARD'S REACH CARD (FUNC(reach), the support core's "reach" hook,
// 2026-11-01). An ETA nobody can give is -1; the effect line names at most
// REACH_STORES_SHOWN of a CAS aircraft's stores, plain ASCII between items
// (the tacpad font).
#define REACH_ETA_UNKNOWN   -1
#define REACH_SEP           " - "
#define REACH_STORES_SHOWN  3

// DRONE ESCORTS (user, 2026-11-02: "drone escorts is based on lz security for
// helos and always for fix wings"; FUNC(escortLaunch), the support core's
// escort). A helicopter's are decided this long (s) after it launches: the
// board files its request card to the asset's box just before the order, and
// the LZ security is read off that card, which must be on the server by then.
// Only these securities are escorted. A fixed-wing lead with no Fixed-Wing
// Escort Class takes its side's vanilla UCAV (sides and classes in step).
#define ESCORT_LZ_WAIT      5
// ESCORT CALLED (user, 2026-11-09: "make sure there is a way to call in
// escorts to all transports no mater the phase or tasking"; FUNC(escortCall)):
// what the asset says.
#define ESCORT_SAID_UP      "ESCORTS LAUNCHING"
#define ESCORT_SAID_ALREADY "ESCORTS ALREADY UP"
#define ESCORT_SAID_LATER   "ESCORTS WILL LAUNCH WITH THE AIRCRAFT"
#define ESCORT_SAID_NONE    "UNABLE - NO ESCORT CLASS SET ON THE MODULE"
#define ESCORT_LZ_ESCORTED  ["YELLOW", "RED"]
#define ESCORT_PLANE_SIDES  [west, east, independent]
#define ESCORT_PLANE_DEFAULTS ["B_UAV_02_dynamicLoadout_F", "O_UAV_02_dynamicLoadout_F", "I_UAV_02_dynamicLoadout_F"]

// ------------------------------------------- transport and QRF by message --
// STEP 7 (user, 2026-11-01: "per the doc i want to use the messaging system to
// call ai support"; DESIGN_SUPPORT_MESSAGING 5.4 and step 7). What the support
// core's card reader calls the cards (EFUNC(support,readOrder)), and the words
// its follow-up hook hands over for their answers.
#define ORDER_PICKUP        "pickup"
#define ORDER_LIFT          "lift"
#define ORDER_CASEVAC       "casevac"
#define ORDER_DROP          "drop"
// THE PICKUP REPORT IS ITS OWN (user, 2026-11-08: "what part of spliting the
// pick up report did you not understand"): a PICKUP lands, shuts down and
// waits for the INSERTION (JOB_INSERT, PROMPT_INSERT) - filed in its thread,
// that LZ is merged into the job at the pickup (FUNC(liftReply)) and the
// troop load asked; ALL IN starts it up and flies it.
#define JOB_INSERT          "insert"
#define PROMPT_INSERT       "ON DECK AT PICKUP, SHUT DOWN - SEND THE INSERTION"
#define ANSWERS_INSERT      "hlz,rtb"
#define CARD_IN_HOVER       "inhover"
// EXTRACTION (HLZ) (user, 2026-11-02: "need a pick up version where the pick
// up is the hot zone"): the pickup is the one asked about - LZ STATUS? on the
// way in, the RED one confirmed, the mark verified and CLEARED TO LAND there.
// TRANSPORT IS TWO THINGS (user, 2026-11-08: "pick up with the helo lands
// turns off, insertion happens after a pickup, and extraction should be a low
// hover never touching the groups then rtb on all in"): the LIFT REQUEST's
// pickup lands and shuts down, the insertion flown after its ALL IN; the
// EXTRACTION holds EXTRACT_HOVER m over the pickup, never down, and goes home
// on ALL IN - it has no destination. The WILCO says how many.
#define ORDER_EXTRACT       "extract"
#define EXTRACT_HOVER       2.5
#define WILCO_PAX           "%1 PAX"
// The QRF card's kind ("qrf"; ORDER_QRF is the type's list position).
#define ORDER_LINKUP        "qrf"
#define WORD_CONFIRM        "confirm"
#define WORD_COLD           "cold"
#define WORD_HOT            "hot"
#define WORD_PAXOFF         "paxoff"
#define WORD_HOLD           "hold"
#define WORD_RECEIVED       "received"
#define WORD_NOTFOUND       "notfound"
#define WORD_DESTINATION    "destination"
#define WORD_TASK           "task"
// A destination may be given in a free-text message (EFUNC(support,readOrder)).
#define CARD_FREETEXT       "freetext"
// The asset's own milestones, an optional text on each (EFUNC(support,builtinReplies)).
#define CARD_WHEELS_UP      "wheelsup"
#define CARD_WHEELS_DOWN    "wheelsdown"
#define CARD_TEXT_KEY       "Text.A"
// The card's security that makes a hot LZ (doc 5.3), and its CANTCO words.
#define LZ_RED              "RED"
#define WHY_HOT_LZ          "HOT LZ NOT ACKNOWLEDGED"
#define WHY_NO_PARADROP     "CANNOT PARADROP"
// A RED LZ's WILCO says plainly what to do (user, 2026-11-01: the thread waited
// for a CONFIRM nobody knew to send).
#define WILCO_HOT           "HOT LZ - REPLY EXECUTE TO LAUNCH"
// THE PROMPTS (doc 5.4) - what it asks, and the reply ids it offers. LZ
// STATUS? is asked with the 1 MIN OUT - POP SMOKE alert, in one FLASH
// message (EFUNC(support,inbound), user 2026-11-01).
#define PROMPT_LZ_STATUS    "LZ STATUS?"
#define ANSWERS_LZ_STATUS   "cold,hot"
// The launch's WHEELS UP: "INBOUND - ETA m:ss" (user, 2026-11-01).
#define WHEELS_UP_INBOUND   "INBOUND - %1"
#define PROMPT_HOT          "HOT LZ - EXECUTE?"
#define ANSWERS_HOT         "execute,rtb"
#define PROMPT_PAX          "WHEELS DOWN - PAX OFF?"
#define ANSWERS_PAX         "paxoff,hold"
#define PROMPT_PAX_HOLD     "HOLDING - PAX OFF?"
#define ANSWERS_PAX_HOLD    "paxoff,rtb"
#define PROMPT_NEXT         "HOLD, RTB OR NEXT LIFT?"
#define ANSWERS_NEXT        "hold,rtb,hlz"
#define PROMPT_NO_TARGET    "NO TARGET LOCATION - HOLD, RTB OR NEXT LIFT?"
#define PROMPT_DEST         "PATIENTS ABOARD - DESTINATION?"
#define PROMPT_DEST_COUNT   "%1 ABOARD - DESTINATION?"
#define ANSWERS_DEST        "move,freetext"
#define PROMPT_RECEIPT      "PACKAGE AWAY - CONFIRM RECEIPT"
#define ANSWERS_RECEIPT     "received,notfound"
#define PROMPT_LINKUP       "SQUAD DOWN AT %1 - %2 MEN - %3 - LINKED UP?"
#define ANSWERS_LINKUP      "received,close"
// What the thread is closed with.
#define SAID_RTB            "RTB"
#define SAID_NO_RESPONSE    "NO RESPONSE - RTB"
#define SAID_RETASKED       "RE-TASKED"
#define SAID_RECEIVED       "RECEIVED"
#define SAID_NOT_FOUND      "NOT FOUND - DROPPED AT %1"
#define SAID_LINKED_UP      "LINKED UP"
#define SAID_SILENT         "NO RESPONSE"
// The lift's steps (QGVAR(liftJob) "step"): waiting for CONFIRM on a RED LZ
// before it launches, flying, asked the LZ status, asked to confirm a hot LZ
// on the way in, loading patients, asked the destination, asked whether the
// passengers are off, asked what next, holding, asked for the receipt.
#define JOB_CONFIRM         "confirm"
#define JOB_FLYING          "flying"
#define JOB_LZ_STATUS       "lzStatus"
#define JOB_HOT             "hot"
#define JOB_LOADING         "loading"
#define JOB_DEST            "dest"
#define JOB_PAX             "paxOff"
#define JOB_NEXT            "next"
#define JOB_HOLDING         "holding"
#define JOB_RECEIPT         "receipt"
#define JOB_LINKUP          "linkup"
// THE HLZ AND EXTRACTION FLOWS (user, 2026-11-02: "hlz insertion: 1) pick up
// site (always safe) 2) troop load, all in (need an ace interaction while in
// heli for all in) 3) flight path 4) insertion 5) egress. extraction: 1) on
// station 2) extraction 3) troop load, all in 4) egress"). An extraction holds
// on its STATION (JOB_STATION) until the issuer's EXTRACT; at the pickup it
// waits for ALL IN (JOB_ALL_IN) - the `allin` reply or the ACE self action
// aboard (FUNC(srvAllIn)) - or, as before, for every man there aboard or the
// module's Extract Wait.
#define JOB_STATION         "station"
#define JOB_ALL_IN          "allIn"
// THE ACTIVE LZs AND DZs (user, 2026-11-02: "in AiTR lz and drop zones need to
// be highlighted"; FUNC(liftZones), EFUNC(support,zones)): the support core's
// zone kinds a lift and a QRF publish. The pickup legs - the landing that
// ends with the troop load, the patients or the stick - and the zone each one
// is; the zone goes once the job leaves that leg.
#define ZONE_PICKUP         "pickup"
#define ZONE_INSERT         "insert"
#define ZONE_EXTRACT        "extract"
#define ZONE_CASEVAC        "casevac"
#define ZONE_DEST           "dest"
#define ZONE_PARA           "para"
#define ZONE_QRF            "qrf"
#define ZONE_QRF_DROP       "qrfdrop"
#define PICKUP_LEGS         [TASK_LIFT, TASK_EXTRACT, TASK_PICKUP]
#define WORD_ALL_IN         "allin"
#define WORD_EXTRACT_NOW    "extractnow"
#define PROMPT_ON_STATION   "ON STATION - READY FOR EXTRACTION"
#define ANSWERS_ON_STATION  "extractnow,abort"
#define PROMPT_ALL_IN       "TROOP LOAD - ALL IN?"
#define ANSWERS_ALL_IN      "allin,abort"
#define WHEELS_DOWN_PICKUP  "AT PICKUP %1"
// An insertion's PAX OFF ends it (5: egress): the card's EGRESS points, home.
#define SAID_EGRESS         "EGRESS - RTB"
// No STATION marker on the card: it holds this far (m) short of the HLZ, on
// the side it comes from.
#define STATION_SHORT       1000
// THE ACE SELF ACTION "ALL IN" (FUNC(canAllIn), FUNC(srvAllIn)): offered aboard
// a support helicopter loading at its pickup to the request's issuer and to a
// group leader; the vehicle carries [thread id, issuer uid] (QGVAR(allIn))
// while it loads.
#define ALL_IN_ACTION_NAME  "ALL IN"
#define ALL_IN_ACTION_ICON  "\a3\ui_f\data\IGUI\Cfg\Actions\getincargo_ca.paa"
// Where the scroll ALL IN sits in the action menu (XEH_postInit): above the
// seat and door actions a man in a helicopter's cabin is offered.
#define ALL_IN_ACTION_PRIORITY 10
// WAVE OFF (user, 2026-11-08: "on insertion add a wave off scroll command",
// "then send a notice to who told the flight to wave off"): scroll and ACE
// self action aboard a lift request's insertion leg, from ALL IN until it is
// down on the LZ or its ropes are in (FUNC(canWaveOff), FUNC(srvWaveOff)) -
// the issuer or a group leader. The vehicle carries [thread id, issuer uid]
// (QGVAR(waveOff)) while it may. It goes around: ropes in, out to hold short,
// LZ STATUS? asked again; the one who waved it off gets the notice.
#define WAVE_OFF_ACTION_NAME "WAVE OFF"
#define WAVE_OFF_ACTION_ICON "\a3\ui_f\data\IGUI\Cfg\Actions\getout_ca.paa"
#define WAVE_OFF_ACTION_PRIORITY 11
// 1 MIN OUT - LZ STATUS? is asked a minute out (the support core's
// ONE_MIN_OUT) or this near (m), whichever is first; nearer than this the
// helicopter holds short until it is answered (and a hot LZ confirmed),
// orbiting at LZ_HOLD_ORBIT m.
#define LZ_HOLD_SHORT       1000
#define LZ_HOLD_ORBIT       400
// CIRCLE TILL THE MARK IS VERIFIED, THEN CLEARED TO LAND (user, 2026-11-02:
// "support trans needs to circle till smoke is verified, caller pops smoke
// helo verifies color, either way transport needs final permission to land").
// Every landing of a lift (the tasks below) and of a QRF air assault tasked by
// message: inside ARRIVE_RING it circles the point LZ_CIRCLE_RADIUS m out,
// LZ_CIRCLE_HEIGHT m up - over the support core's nap of the earth, clear of
// the trees, low enough to see the mark - while the support core verifies the
// mark and asks for the clearance (EFUNC(support,lzClear)); it lands only on
// CLEARED TO LAND (FUNC(liftCleared)). The job's "landing": circling, then
// cleared. An EXTRACTION to home base (TASK_EXTRACT, 2026-11-02) clears its
// pickup this way; home base is landed on without it.
#define LZ_CLEAR_TASKS      [TASK_PICKUP, TASK_LAND, TASK_LIFT, TASK_EXTRACT]
#define LZ_CIRCLE_RADIUS    200
#define LZ_CIRCLE_HEIGHT    50
#define LANDING_CIRCLING    "circling"
#define LANDING_CLEARED     "cleared"
// THE PASSENGERS ARE THOSE AT THE PICKUP (step 7): the side's men on foot this
// close (m) when it touches down; it lifts when they are aboard or the wait is
// up - a LIFT REQUEST's and an EXTRACTION's (2026-11-02) alike.
#define PICKUP_PAX_RADIUS   150
// A QRF's method: words in the card's route, attachments, action or remarks
// that ask for a static-line drop; the action's words for what the squad does.
#define QRF_STATIC_WORDS    ["STATIC", "PARA", "JUMP"]
// REINFORCE is the QRF card's pick for joining (report-card review,
// 2026-11-02: ACTION ON ARRIVAL is a pick - CORDON, BLOCK, CCP, REINFORCE,
// ASSAULT; ASSAULT is the module's own On The Ground).
#define QRF_JOIN_WORDS      ["JOIN", "REINFORCE"]
#define QRF_DEFEND_WORDS    ["DEFEND", "HOLD", "CORDON", "BLOCK", "SECURE", "CCP"]
#define ON_LANDING_DEFEND   0
#define ON_LANDING_JOIN     1
// The words of a LZ marking line, as the LZ signal it looks for.
#define MARKING_SIGNALS     [["SMOKE", SIGNAL_SMOKE], ["IR", SIGNAL_IR], ["PYRO", SIGNAL_FLARE], ["FLARE", SIGNAL_FLARE]]

// WHAT HAPPENS TO AN AIRFRAME IS SAID IN ITS THREADS (user, 2026-11-05;
// EFUNC(support,threadEvent) through the core's EVENT_AIRCRAFT): hit - once
// per HIT_SAID_S per airframe - a fault, a loss.
#define HIT_SAID_S          30
#define EVENT_TAKING_FIRE   "TAKING FIRE AT %1"
#define EVENT_CANNOT_FLY    "CANNOT FLY - %1 - AT %2"
#define EVENT_DOWN          "DOWN AT %1 - AIRFRAME LOST - %2"
#define EVENT_NO_REPLACE    "NO REPLACEMENT"
#define EVENT_REPLACE_IN    "REPLACEMENT IN %1 S"

// --- transport (2026-11-09, docs/DESIGN_MESSAGE_TEMPLATES.md) -----------------
// The words the support core hands over for the new commands (its
// FOLLOW_UP_WORDS): ABORT is no longer a stop - the lift breaks off where it
// is and asks STATE INTENTIONS (EFUNC(support,askIntentions)); HOLD stops it
// where it is in any step; MOVE flies it to a point and does LOITER / LAND /
// HOVER / HOLD there; FRAGO re-plans the job from the merged order; GO AROUND
// and CONTINUE APPROACH outside the core's landing wait; NO DROP on a
// paradrop's run-in; ESCORT any time (FUNC(escortCall)).
#define WORD_ABORT          "abort"
#define WORD_MOVE           "move"
#define WORD_FRAGO          "frago"
#define WORD_ESCORT         "escort"
#define WORD_NO_DROP        "nodrop"
#define WORD_GO_AROUND      "goaround"
#define WORD_CONTINUE_APP   "continueapproach"
// The job's steps they put it in: held where it is (the order it was flying
// kept to resume - "heldOrder"), flying a MOVE, broken off by an ABORT, on a
// paradrop's run-in waiting for EXECUTE (STAND BY).
#define JOB_HELD            "held"
#define JOB_MOVE            "move"
#define JOB_ABORTED         "aborted"
#define JOB_STANDBY         "standby"
// What it says, and what its STATE INTENTIONS offers beside the core's
// MOVE / HOLD / FRAGO / RTB: EXECUTE carries on with the order it had (a
// held or aborted lift), and the transport starters it flies.
#define SAID_HELD           "HOLDING AT %1"
#define SAID_ABORTED        "ABORTED"
#define SAID_HOLDING        "HOLDING"
#define SAID_MOVE_WILCO     "MOVING TO %1 - %2"
#define SAID_ARRIVED        "AT %1 - %2"
#define SAID_TIME_UP        "TIME UP AT %1"
#define SAID_FRAGO          "FRAGO - %1"
#define SAID_FRAGO_NONE     "FRAGO - NO CHANGE TO FLY"
#define SAID_GOING_AROUND   "GOING AROUND - %1"
#define SAID_CONTINUING     "CONTINUING APPROACH"
#define ANSWERS_CARRY_ON    "execute"
#define ANSWERS_STARTERS    "pickup,hlz,extract,casevac,airdrop"
// MOVE's ON ARRIVAL words (EFUNC(support,readOrder) "arrival") as the
// transport task flown there: LOITER and HOLD orbit the point, HOVER holds a
// hover over it, LAND lands and shuts down (the clearance first, as every
// landing - user, 2026-11-02).
#define MOVE_LOITER         "LOITER"
#define MOVE_LAND           "LAND"
#define MOVE_HOVER          "HOVER"
#define MOVE_HOLD           "HOLD"
#define MOVE_DEFAULT        "HOLD"
// THE PARADROP'S RUN-IN (FM 3-21.38 Table 3-3): STAND BY - EXECUTE? asked
// PARADROP_STANDBY_RING m out (execute / nodrop); not cleared by
// PARADROP_HOLD_RING m it flies closed traffic round the DZ, PARADROP_ORBIT m
// out, and asks again. NO DROP is another pass; the PARADROP_PASSES_MAX-th,
// or a second NO DROP in a row, asks STATE INTENTIONS.
#define PARADROP_STANDBY_RING 3000
#define PARADROP_HOLD_RING  1500
#define PARADROP_ORBIT      1200
#define PARADROP_PASSES_MAX 3
#define PARADROP_NODROPS_MAX 2
#define PROMPT_STANDBY      "STAND BY - %1 - EXECUTE?"
#define PROMPT_NO_DROP      "NO DROP - CLOSED TRAFFIC - PASS %1 - EXECUTE?"
#define ANSWERS_STANDBY     "execute,nodrop"
#define SAID_NO_DROP_END    "NO DROP"
// LAND HEADING (2026-11-09; EFUNC(support,readOrder) "heading", deg, -1 none):
// the leg's final approach comes in on it - the board's approach bearing is
// where it comes FROM, so the heading's reverse (FUNC(transportPlan)).
#define HEADING_REVERSE     180
#define FULL_CIRCLE         360
// A QRF's tick state, kept on the module so its replies can re-aim it.
#define QRF_PHASE_HELD      "held"
// A lift's answer said in its thread as the asset when the thread is past
// ACCEPTED (EFUNC(support,state) says nothing behind where a thread is).
#define SAID_WILCO          "WILCO - %1"
// A HOLD or ABORT in the frame it is made waits this long (s) for it to be up.
#define LIFT_HOLD_LAUNCH_WAIT 10
#define SAID_CARRY_ON       "CARRYING ON"
#define SAID_EXECUTE        "EXECUTE"
// The 9-line CASEVAC's WILCO (2026-11-09): the litters, the special
// equipment unless NONE.
#define WILCO_LITTER        "%1 LITTER"
#define CASEVAC_NO_EQUIPMENT "NONE"
// An extraction's troop load in its low hover: GO AROUND beside ALL IN.
#define ANSWERS_ALL_IN_HOVER "allin,goaround,abort"
// AN RTB WITH PLAYERS ABOARD (user, 2026-11-09: "we need a way to set an rtb
// landing location if an aircraft has players on board"): what it says.
#define SAID_RTB_LAND       "RTB - LANDING AT %1 FOR PAX FIRST"
// A QRF's RTB landing for the players aboard (2026-11-09, FUNC(qrfTick)).
#define QRF_PHASE_RTB_IN    "rtbIn"
#define QRF_PHASE_RTB_LANDING "rtbLanding"
#define QRF_PHASE_RTB_DOWN  "rtbDown"
