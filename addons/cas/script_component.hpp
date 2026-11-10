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

// WHO MAY ORDER A RUN (review S6). A client's order and recall go by
// remoteExec to the server (SERVER_OWNER), which checks the real sender
// (FUNC(mayTask)): the module named must be this addon's own class, and the
// tasks it flies the two modes FUNC(task) sends.
#define SERVER_OWNER        2
#define CAS_MODULE          "jmfsb_moduleCAS"
#define STATUS_IDLE         "idle"
#define MODE_STRIKE         "strike"
#define MODE_LOITER         "loiter"

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

// ------------------------------------------------------------- the pass --
// THE PASS (2026-11-05, user: "the back end should be based on simplex" -
// modelled on how Simplex Support Services flies a strafe, no code of it
// used): one attack run of any CAS aircraft - a jet, a helicopter, a drone -
// shared by this addon's drones and support_air's CAS (FUNC(passBegin),
// FUNC(passTick), FUNC(passFrame), FUNC(passEnd), FUNC(passAim),
// FUNC(bombDrop), FUNC(fireAt)). Before: one trigger pull inside a 700 m ring
// from wherever the AI had the aircraft - at 4000 m, level, an unguided bomb
// landed kilometres long and the gun fired at nothing.
//
// THE LINE-UP: the AI flies it, ordered again every PASS_ORDER_EVERY s while
// idle, to the aim once it is within PASS_LINE_TOL deg of the ingress bearing
// (seen from the aim), else to the prep point PASS_LINE_OUT times the line-up
// distance out on that bearing. The line-up distance is the release range
// plus PASS_LINE_EXTRA m, or PASS_LINE_LEAD_S s at top speed plus the salvo
// and PASS_HEIGHT_SHARE of its height over the aim, whichever is more. It
// commits to the dive inside the commit distance (the release range, or
// PASS_DIVE_LEAD_S s at the run speed plus the salvo and the same height
// buffer) and outside the nearest distance (PASS_NEAREST_SHARE of the range,
// or PASS_NEAREST_LEAD_S s at the run speed plus the salvo - no height
// buffer, so the window is wide enough for a one-second watch), on the line,
// nosed within PASS_NOSE_TOL deg of the aim, faster than its minimum. Lining up
// longer than PASS_LINE_MAX_S: it commits from wherever it is inside the
// line-up distance, else the pass is missed. On the way in it keeps looking
// for a laser or smoke every PASS_LOOK_EVERY s while the grid is all it has.
// Once on the line inside the line-up distance its speed is capped at the run
// speed. A helicopter lines up and dives from PASS_HELI_HEIGHT m.
#define PASS_PLANE_RANGE    2000
#define PASS_HELI_RANGE     1000
#define PASS_LINE_EXTRA     800
#define PASS_LINE_LEAD_S    8
#define PASS_DIVE_LEAD_S    3
#define PASS_NEAREST_SHARE  0.8
#define PASS_NEAREST_LEAD_S 0.5
#define PASS_HEIGHT_SHARE   0.5
#define PASS_LINE_OUT       1.4
#define PASS_LINE_TOL       25
#define PASS_NOSE_TOL       50
#define PASS_ORDER_EVERY    10
#define PASS_ORDER_MOVED    100
#define PASS_ORDER_LOG_S    30
#define PASS_LINE_MAX_S     180
#define PASS_LOOK_EVERY     1
#define PASS_HELI_HEIGHT    150
// THE RUN SPEED: a plane half its top speed, no more than PASS_PLANE_SPEED_MAX
// m/s and no less than PASS_STALL_MARGIN times its stall speed; a helicopter
// PASS_HELI_SPEED_SHARE of its top speed, no more than PASS_HELI_SPEED m/s.
// A helicopter must be doing PASS_HELI_MIN_SPEED m/s to commit.
#define PASS_PLANE_SPEED_MAX 160
#define PASS_SPEED_SHARE    0.5
#define PASS_STALL_MARGIN   1.1
#define PASS_HELI_SPEED     28
#define PASS_HELI_SPEED_SHARE 0.34
#define PASS_HELI_MIN_SPEED 8
// THE DIVE, each frame: the nose turns onto the aim at PASS_TURN_RATE deg/s
// (a helicopter PASS_HELI_TURN_RATE), pitches at PASS_PITCH_RATE deg/s onto
// the line of sight until inside the release range and onto the solution
// from there, banks PASS_BANK_PER_DEG deg per degree of turn left within
// PASS_BANK_LIMIT (a helicopter PASS_HELI_BANK_LIMIT) at PASS_BANK_RATE
// deg/s, and the speed closes on the run speed at PASS_ACCEL m/s2. The
// solution is worked every PASS_AIM_EVERY s. Within PASS_AIM_TOL deg of it
// in heading and pitch, held PASS_SETTLE_S s, the trigger is pulled; the
// salvo goes on while it drifts no more than PASS_HOLD_TOL deg. The dive is
// broken off when the airframe would be under PASS_FLOOR_PLANE m (a
// helicopter PASS_FLOOR_HELI) over the ground PASS_LOOK_AHEAD_S s on - room
// for the AI to pull a jet out of a steep dive - past PASS_PITCH_LIMIT deg
// nose down, past the aim, or after PASS_DIVE_MAX_S s; the nose never above
// PASS_PITCH_UP_MAX. A frame longer than PASS_FRAME_MAX s counts as that,
// never shorter than PASS_FRAME_MIN.
#define PASS_TURN_RATE      20
#define PASS_HELI_TURN_RATE 40
#define PASS_PITCH_RATE     20
#define PASS_PITCH_LIMIT    85
#define PASS_PITCH_UP_MAX   15
#define PASS_BANK_PER_DEG   3
#define PASS_BANK_LIMIT     70
#define PASS_HELI_BANK_LIMIT 30
#define PASS_BANK_RATE      60
#define PASS_ACCEL          10
#define PASS_AIM_EVERY      0.25
#define PASS_AIM_TOL        2
#define PASS_HOLD_TOL       6
#define PASS_SETTLE_S       1.5
#define PASS_FLOOR_PLANE    500
#define PASS_FLOOR_HELI     25
#define PASS_LOOK_AHEAD_S   2
#define PASS_DIVE_MAX_S     45
#define PASS_FRAME_MAX      0.1
#define PASS_FRAME_MIN      0.001
// THE SALVO: what one pass puts down of the store it carries - bombs in
// pairs, one guided round, a ripple of rockets, a burst of gun for
// PASS_GUN_BURST_S s. Pulls PASS_PULL_MIN_GAP s apart at least (the fire
// mode's reload otherwise); PASS_PULL_EXTRA pulls past the salvo with no
// round counted and the store is dry; a pull with no round out after
// PASS_FIRE_CHECK_S s is tried once more as the engine's fireAtTarget.
#define PASS_SALVO_BOMB     2
#define PASS_SALVO_GUIDED   1
#define PASS_SALVO_ROCKET   4
#define PASS_GUN_BURST_S    2
#define PASS_PULL_MIN_GAP   0.1
#define PASS_PULL_EXTRA     3
#define PASS_FIRE_CHECK_S   0.5
// THE SOLUTION (FUNC(passAim)): the round is flown in PASS_SIM_DT s steps the
// way the engine flies it (air friction times speed squared, gravity) from
// a guessed elevation until it falls through the aim's height, no longer
// than PASS_SIM_MAX_S s; the elevation is corrected by the secant of the
// range error, PASS_AIM_ITER times at most, until the range is within
// PASS_AIM_TOL_M m. The second guess is PASS_AIM_PROBE deg above the line
// of sight; no guess goes more than PASS_AIM_SPAN deg above it. Gravity is
// the mod's GRAVITY (main/script_macros.hpp).
#define PASS_SIM_DT         0.1
#define PASS_SIM_MAX_S      60
#define PASS_AIM_ITER       5
#define PASS_AIM_TOL_M      3
#define PASS_AIM_PROBE      5
#define PASS_AIM_SPAN       60
// AFTER THE PASS (FUNC(passEnd)): the AI is given its height back no lower
// than PASS_PULL_OUT_HEIGHT m, and PASS_PULL_OUT_DELAY s later the height it
// came in at; the dummy laser target stays PASS_DUMMY_LINGER s for rounds
// still flying. The speed cap comes off (PASS_NO_SPEED_CAP).
#define PASS_PULL_OUT_HEIGHT 150
#define PASS_PULL_OUT_DELAY 6
#define PASS_DUMMY_LINGER   20
#define PASS_NO_SPEED_CAP   -1
// UNGUIDED BOMBS ARE FLOWN TO THE AIM (FUNC(bombDrop)): the free fall from
// the release is worked out in BOMB_SIM_DT s steps as the engine would fly it,
// no longer than BOMB_MAX_S s, and the bomb is moved along it each frame with
// the gap between where that ends and the aim closed evenly over the fall. A
// fall ending more than BOMB_MAX_STEER m from the aim is left to the engine -
// the solution was no solution. The sea is BOMB_SEA_Z m ASL.
#define BOMB_SIM_DT         0.1
#define BOMB_MAX_S          90
#define BOMB_MAX_STEER      300
#define BOMB_SEA_Z          0
// What a store is to the pass: steered by its seeker, a bomb released at the
// airframe's speed, or a shell on a ballistic arc (gun, rockets).
#define KIND_GUIDED         "guided"
#define KIND_BOMB           "bomb"
#define KIND_SHELL          "shell"
// The pass's phases (QGVAR(pass) "phase" on the airframe) and its results.
#define PASS_LINE           "line"
#define PASS_DIVE           "dive"
#define PASS_DONE           "done"
#define PASS_NONE           "none"
#define PASS_FIRED          "fired"
#define PASS_MISSED         "missed"
#define PASS_ABORTED        "aborted"
#define PASS_LOST           "lost"
#define PASS_DRY            "dry"
// Degrees round and half round, for the shortest turn to a heading.
#define PASS_FULL_TURN      360
#define PASS_HALF_TURN      180
// The pilot's own weapons sit on this turret path.
#define TURRET_PILOT        [-1]

// LOITER IS A TASK, NOT A RUN, so it gets its own patience: an ISR asset is
// meant to sit over the objective for as long as the section is working, and
// the strike timeout would pull it off station in ten minutes. It still ends
// on RTB, on death, or here.
#define CAS_LOITER_TIMEOUT  3600

// The orbit the aircraft holds once it is on station - round the task point:
// a drone is exempt from the off-map hold (user, 2026-11-01), its camera has
// to see the grid. A strike held for CLEARED HOT orbits the same ring.
#define CAS_LOITER_RADIUS   900
// THE SUPPORT CORE'S TACTICAL FLIGHT (user, 2026-11-01): the phases its
// EFUNC(support,flightHeight) answers for - a strike at the attack altitude,
// a loiter at the off-map hold's.
#define FLY_ATTACK          "attack"
#define FLY_STATION         "station"

// How close to the task point counts as ON STATION - the ring that hands the
// gunner's seat to the drone controller. Wide, because an orbit this size
// never puts the aircraft on the point itself.
#define CAS_STATION_RING    1600
// THE CHECK-IN (user, 2026-11-02): inside that ring a drone files its AIRFRAME
// CHECK-IN in the thread that asked (EFUNC(support,checkIn)), once a run -
// these are its Line 7 remarks, a LOITER and a strike held for CLEARED HOT.
#define CHECKIN_REMARKS_LOITER "OVER THE GRID, DARK"
#define CHECKIN_REMARKS_HELD   "OVER THE GRID, HOLDING FOR CLEARED HOT"

// Seconds after ON STATION before the drone controller is put in the seat -
// the airframe and its crew are a moment old (FUNC(onStation)).
#define SEAT_DELAY          1

// THE WAY HOME (user, 2026-11-02: "all support aircraft needs to be virtual
// till tasked, then they spawn in at alt over the support module location"). A
// run that is over - egressed, recalled, out of patience - flies back to the
// module at the hold altitude and is removed, crew and airframe, inside
// CAS_HOME_RING m of it (FUNC(recover)). How often the way home is checked,
// and how long it may take before the drone is removed where it is: long
// enough to cross the biggest map at a UAV's cruise; a drone that has lost its
// waypoint to a stall is not left circling for the rest of the mission.
#define CAS_HOME_RING       600
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
// A NEW TASK IN THE THREAD (2026-11-02, the provider's "threadCards"): a new
// CAS REQUEST in a drone's strike thread, the answer to FURTHER TASKING?
// (FUNC(threadReply) "task").
#define THREAD_CARDS        [["cas", ["cas"]]]
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
// THE BOARD'S REACH CARD (FUNC(reach), the support core's "reach" hook,
// 2026-11-01). An ETA nobody can give is -1; the effect line names at most
// REACH_STORES_SHOWN stores, plain ASCII between items (the tacpad font). The
// two defaults are the module's own (FUNC(moduleController)), read the way
// FUNC(preview) reads them.
#define REACH_ETA_UNKNOWN   -1
#define REACH_SEP           " - "
#define REACH_STORES_SHOWN  3
#define REACH_DEF_DISTANCE  4000
#define REACH_DEF_SPEED     400
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

// THE ASSET'S THREAD (2026-11-01, DESIGN_SUPPORT_MESSAGING steps 3 and 4):
// what the support core's card reader (EFUNC(support,readOrder)) calls a
// strike and a REQUEST ON STATION, and the one word its follow-up hook hands
// over for CLEARED HOT and for anything that ends the task.
#define ORDER_STRIKE        "strike"
#define ORDER_STATION       "station"
#define WORD_CLEARED        "cleared"
#define WORD_STOP           "stop"
// The CANTCO words (doc 5.2) this addon gives itself.
#define WHY_NO_TARGET       "NO TARGET LOCATION"
#define WHY_NO_STORES       "NO STORES"
#define WHY_CANNOT_LASE     "CANNOT LASE %1"
#define WHY_LOST            "LOST"
#define WHY_TASKED          "TASKED"
// A laser mark: the attack is laser guided, with a store that can be.
#define MARK_LASER          "LASER"
// What makes a store laser guided (FUNC(orderStore)): the engine's laser lock,
// the laser bit of its lock systems, or ACE's semi-active laser seeker.
#define LOCK_LASER_BIT      4
#define SEEKER_LASER        "SALH"
// The most of the target description a WILCO repeats.
#define DESCRIPTION_MAX     48
#define WILCO_SEP           " - "

// THE PROMPTS AND THE BDA (2026-11-01, DESIGN_SUPPORT_MESSAGING 5.4, step 5).
// A thread's strike stays on station for its answers this long (s) - a
// strike's time on station - and says BINGO IN 2 MIN (FLASH) BINGO_LEAD s
// before it runs out, or when its fuel is down to BINGO_FUEL of a tank,
// leaving BINGO_LEAD s later. BINGO_LEAD is the 2 MIN the support core's
// prompt says - keep them in step.
#define CAS_THREAD_TIMEOUT  1800
#define BINGO_LEAD          120
#define BINGO_FUEL          0.25
#define SECONDS_PER_MINUTE  60
// What the support core's EFUNC(support,casPrompt) says (its own words), and
// the follow-up words this addon answers besides CLEARED HOT and the stops.
#define CAS_IN              "in"
#define CAS_OFF             "off"
#define CAS_REATTACK        "reattack"
#define CAS_TASKING         "tasking"
#define CAS_BINGO           "bingo"
#define WORD_BDA            "bda"
#define WORD_NO             "no"
#define WORD_TASK           "task"
// ALL ATTACK (user, 2026-11-02) is a fixed-wing flight's with escort drones -
// a CAS drone has none: NO ESCORTS - USE CLEARED HOT, asked again.
#define WORD_ALL_ATTACK     "allattack"
#define CAS_NO_ESCORTS      "noescorts"
// The run's status while it holds over the grid after a strike (the row reads
// ON STATION), and what it closes its thread with.
#define STATUS_STATION      "station"
#define STATUS_MISSION      "mission"
#define STATUS_COOLDOWN     "cooldown"

// VIRTUAL UNTIL TASKED (user, 2026-11-02: "all support aircraft needs to be
// virtual till tasked, then they spawn in at alt over the support module
// location"; it replaced the same day's "on station from the start"). No drone
// is up between runs: the row reads READY ("idle"); a tasking makes one over
// the module (FUNC(launch), FUNC(spawnDrone)), and after the run it flies home
// and is removed (FUNC(recover)). A lost drone's replacement on its way reads
// REARMING ("replacing"); the last one gone, LOST ("expended") and off the list.
#define STATUS_REPLACING    "replacing"
#define STATUS_EXPENDED     "expended"
// No run is up: what the row reads between runs. A recall, a timeout or an
// answer in a thread is for a run, never for these.
#define STATUSES_NO_RUN     [STATUS_IDLE, STATUS_COOLDOWN, STATUS_REPLACING, STATUS_EXPENDED]
// THE RESPAWN COUNT (user, 2026-11-02: "make sure there is a respawn count for
// each support, default no respawns"): the module's Respawns, 0 by default,
// and its Respawn Delay. A drone LOST uses one (FUNC(gone)); one that flies
// home does not. The last drone gone, the asset answers this (the support
// core's words) and leaves the list.
#define MODULE_RESPAWNS     0
#define MODULE_RESPAWN_DELAY 300
#define WHY_NO_AIRFRAME     "UNABLE - NO AIRFRAME"
// What the reach card and the verdict say is left (FUNC(reach), FUNC(preview)).
#define LEFT_RESPAWNS       "%1 RESPAWNS LEFT"
#define LEFT_LAST           "LAST AIRFRAME"
#define WHY_REPLACING       "REPLACING %1 S"
#define CARD_RTB            "rtb"
#define SAID_OFF_TASK      "off task - leaving the area"
#define SAID_BINGO          "BINGO"
#define SAID_WINCHESTER     "WINCHESTER"
#define SAID_NO_RESPONSE    "NO RESPONSE - RTB"
#define SAID_RTB            "RTB"
// THE BDA SAID EGRESS (user, 2026-11-02: "reattack or egress"; EGRESS = LEAVE):
// it leaves on its egress line, its thread closed with this. The decision
// words are the support core's (its readOrder's "decision").
#define SAID_EGRESS         "EGRESS - RTB"
#define BDA_REATTACK        "reattack"
#define BDA_EGRESS          "egress"

// --- CAS (2026-11-09, docs/DESIGN_MESSAGE_TEMPLATES.md, trees tree 3) -------
// The flow both CAS providers fly (this addon's drones, support_air's
// aircraft) - the words in one place (FUNC(casAsk)): READBACK after the WILCO
// (CORRECT runs in, WRONG asks a FRAGO), IP INBOUND, IN asking the clearance
// - CLEARED HOT, CONTINUE or ABORT (ALL ATTACK beside them for a fixed-wing
// flight with escorts up); Type 3 control CLEARED TO ENGAGE and ATTACK
// COMPLETE; ABORT breaks off and asks STATE INTENTIONS; a FRAGO is taken
// until IP INBOUND.
#define CAS_ASK_READBACK    "readback"
#define CAS_ASK_SEND_FRAGO  "sendfrago"
#define CAS_ASK_FRAGO_LATE  "fragolate"
#define CAS_ASK_IP_INBOUND  "ipinbound"
#define CAS_ASK_IN          "in"
#define CAS_ASK_COMPLETE    "attackcomplete"
#define CAS_ASK_INTENTIONS  "intentions"
#define CAS_ASK_LINE        "line"
#define CAS_READBACK_TEXT   "READBACK - TARGET %1 - %2"
#define CAS_READBACK_NONE   "NO RESTRICTIONS"
#define CAS_READBACK_ANSWERS "correct,wrong,frago"
#define CAS_SEND_FRAGO_TEXT "SEND FRAGO"
#define CAS_SEND_FRAGO_ANSWERS "frago,abort"
#define CAS_FRAGO_LATE_TEXT "ABORT FIRST - FRAGO NOT TAKEN AFTER IP INBOUND"
#define CAS_FRAGO_LATE_ANSWERS "abort,continue"
#define CAS_IN_HOT_TEXT     "IN - %1 - CLEARED HOT?"
#define CAS_IN_ENGAGE_TEXT  "IN - %1 - CLEARED TO ENGAGE?"
#define CAS_IN_HOT_ANSWERS  "clearedhot,continue,abort"
#define CAS_IN_HOT_ANSWERS_FW "clearedhot,continue,allattack,abort"
#define CAS_IN_ENGAGE_ANSWERS "clearedengage,abort"
#define CAS_COMPLETE_TEXT   "ATTACK COMPLETE - REQUEST BDA"
#define CAS_COMPLETE_DRONES "ATTACK COMPLETE - DRONES DESTROYED %1 - REQUEST BDA"
#define CAS_COMPLETE_ANSWERS "bda,cas,move,rtb"
#define CAS_INTENTIONS_MORE "cas"
#define CARD_IP_INBOUND     "ipinbound"
#define CARD_TEXT_KEY       "Text.A"
// The restrictions a READBACK repeats: the card's remarks, at most this much.
#define CAS_READBACK_MAX    60
// The control types (the support core's readOrder "control"): Type 3 is
// CLEARED TO ENGAGE.
#define CAS_CONTROL_ENGAGE  3
// The words the support core hands over (EFUNC(support,srvFollowUp)).
#define WORD_CAS_CORRECT    "correct"
#define WORD_CAS_WRONG      "wrong"
#define WORD_CAS_ENGAGE     "clearedengage"
#define WORD_CAS_CONTINUE   "continue"
#define WORD_CAS_ABORT      "abort"
#define WORD_CAS_HOLD       "hold"
#define WORD_CAS_MOVE       "move"
#define WORD_CAS_FRAGO      "frago"
// The readback's steps on a run ("rb"): asked, read back right.
#define RB_ASKED            "asked"
#define RB_OK               "ok"
// CONTINUE on a drone (it orbits the grid - its run in is the orbit): IN is
// asked again this many seconds on, no release meanwhile.
#define CAS_CONTINUE_DELAY  30
// What it says to a HOLD, a MOVE, an ABORT, a RE-ATTACK.
#define CAS_SAID_HOLDING    "HOLDING AT %1"
#define CAS_SAID_MOVING     "MOVING - STATION %1"
#define CAS_SAID_ABORTED    "ABORTED - NO RELEASE"
#define CAS_SAID_REATTACK   "RE-ATTACK - %1 %2 LEFT"
#define CAS_SAID_CONTINUE   "CONTINUING - NO RELEASE"
#define CAS_IP_ETA          "ETA %1"
// THE TOT (FUNC(totTime)): HHMM, HHMMSS or +minutes - the call-for-fire's
// own forms - as a mission time; the pass is not begun before it, less this
// many seconds for the dive.
#define TOT_PLUS            "+"
#define TOT_HHMM            4
#define TOT_HHMMSS          6
#define TOT_DAY_HOURS       24
#define TOT_HOUR_S          3600
#define TOT_MINUTE_S        60
#define TOT_DIVE_LEAD       20
// The status hook (2026-11-09, EFUNC(support,statusReply)).
#define STATUS_HOOK_NONE    -1

// TAKING FIRE is said in the asset's thread (user, 2026-11-05) through the
// support core's aircraft event (EFUNC(support,threadEvent)), once per
// HIT_SAID_S per airframe.
#define HIT_SAID_S          30
#define EVENT_TAKING_FIRE   "TAKING FIRE AT %1"
