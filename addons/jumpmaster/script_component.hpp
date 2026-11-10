#define COMPONENT jumpmaster
#define COMPONENT_BEAUTIFIED Jumpmaster
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_JUMPMASTER
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_JUMPMASTER
    #define DEBUG_SETTINGS DEBUG_SETTINGS_JUMPMASTER
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// ---------------------------------------------------------------------------
// JUMPMASTER (user, 2026-10-30): HALO, HAHO and static-line jumps for a
// squad, asked for by its leader. BY MESSAGE since 2026-11-02 (user: "also
// want to change the halo/haho/static app in to a message based one" ... "it
// also needs a work flow"): the jump aircraft is a support asset, the leader
// files a JUMP REQUEST to it in TAC//MSG, and the aircraft answers in the
// thread - readiness, ROGER, WILCO, WHEELS UP, RED LIGHT, GREEN LIGHT, STICK
// OUT, CLOSE. The app's page, tile and map pick are gone; the flight is the
// same.
// ---------------------------------------------------------------------------
#define TYPE_HALO "HALO"
#define TYPE_HAHO "HAHO"
#define TYPE_STATIC "STATIC"
#define TYPES [TYPE_HALO, TYPE_HAHO, TYPE_STATIC]
// The types that fall free from altitude - a mask is needed up there.
#define FREEFALL_TYPES [TYPE_HALO, TYPE_HAHO]
// THE DZ IN THE SIDE'S AiTR (user, 2026-11-02: "in AiTR lz and drop zones need
// to be highlighted"; EFUNC(support,zones)): the green light under the type's
// own zone kind (halo, haho, static), and where the stick is put out when the
// wind moved the run (FUNC(windShift)).
#define ZONE_RELEASE "release"
#define EXIT_AUTO "auto"
#define EXIT_MANUAL "manual"
#define EXITS [EXIT_AUTO, EXIT_MANUAL]
#define BAY_SEATS "seats"
#define BAY_STAND "stand"
// Who sees the jump aircraft in TAC//MSG: the voice permission table's squad
// leader and admin (jmfsb_tacpad_apps_fnc_radioRole) - the client's words.
// The server takes the card from a man who leads his group, or an admin.
#define JUMPMASTER_ROLES ["SL", "ADMIN"]
#define PASSES_MIN 1
#define PASSES_MAX 4

// --- THE SUPPORT ASSET (2026-11-02) -------------------------------------------
// Provider kind and asset type "jump". ONE JMSB - JUMP AIRCRAFT MODULE IS ONE
// AIRCRAFT (user, 2026-11-02: "Jump aircraft module"): asset id "jump:<n>",
// n its place in GVAR(entities), its box B:SUPPORT:jump:0, its call sign the
// module's. A side with no module keeps its own jump aircraft, flown from the
// settings: "jump:<side>" ("jump:west"), call sign JUMP_CALLSIGN.
#define JUMP_KIND "jump"
#define JUMP_TYPE "jump"
#define JUMP_TASK "jump"
#define JUMP_CALLSIGN "SKYTRAIN"
#define ID_SEP ":"
#define JUMP_SIDES [west, east, independent]
// The row's status (the support core's MAILBOX_STATES: idle IDLE, cooldown
// REARMING, expended LOST, anything else TASKED) - tasked while the module's
// aircraft flies a run, or, for a side's own aircraft, while the viewer's own
// squad has a run up.
#define STATUS_IDLE "idle"
#define STATUS_TASKED "tasked"
#define STATUS_COOLDOWN "cooldown"
#define STATUS_EXPENDED "expended"

// --- THE MODULE (user, 2026-11-02) --------------------------------------------
// Its defaults, which Zeus's module flies as placed, and the altitudes' range -
// the same as the settings' sliders. THE RESPAWN COUNT (user, 2026-11-02: "make
// sure there is a respawn count for each support, default no respawns") took
// the Sorties attribute's place. There is no Response Delay: the aircraft is
// made at once when it is tasked (below).
#define ALT_FREEFALL_MIN 1000
#define ALT_FREEFALL_MAX 10000
#define ALT_FREEFALL_DEFAULT 6000
#define ALT_STATIC_MIN 100
#define ALT_STATIC_MAX 500
#define ALT_STATIC_DEFAULT 150
#define MODULE_PASSES 1
#define MODULE_COOLDOWN 120
#define MODULE_RESPAWNS 0
#define MODULE_RESPAWN_DELAY 300

// --- VIRTUAL UNTIL TASKED (user, 2026-11-02) ----------------------------------
// "all support aircraft needs to be virtual till tasked, then they spawn in at
// alt over the support module location" (it replaced the same day's "on
// station from the start"). A module has no aircraft until a JUMP REQUEST is
// accepted; then it is made over the module, AIR_ALT m up, engines on and
// flying (EFUNC(support,spawnAirborne)), and orbits the module dark -
// AIR_ORBIT_PLANE / AIR_ORBIT_HELI m round - for the leader's BOARD
// (FUNC(airUp)). After the run, or any ending, it flies back to the module
// and is removed inside AIR_HOME_RING m of it, with nobody aboard - or after
// AIR_HOME_TIME s wherever it is (FUNC(airHome)). Its watch: every AIR_TICK s
// (FUNC(airTick)). A side's own aircraft (no module) keeps the old flow: made
// at the run-in.
#define AIR_ALT 2000
#define AIR_ORBIT_PLANE 1500
#define AIR_ORBIT_HELI 800
#define AIR_TICK 2
#define AIR_HOME_RING 600
#define AIR_HOME_TIME 1200
// What the module's aircraft is doing (QGVAR(airPhase), server, public): none
// made, orbiting the module for the BOARD, flying a run, flying home to be
// removed, waiting out the Respawn Delay after a loss, or gone for good with
// no respawn left.
#define AIR_VIRTUAL "virtual"
#define AIR_STATION "station"
#define AIR_RUN "run"
#define AIR_HOME "home"
#define AIR_REPLACING "replacing"
#define AIR_GONE "gone"
// The row: REPLACING after a loss, RTB while it flies home.
#define STATUS_REPLACING "replacing"
#define STATUS_RTB "rtb"
#define WHY_RTB "RTB"
// What it answers with no airframe: one coming (n s left), or none left - the
// support core's WHY_NO_AIRFRAME (kept in step; addons cannot read each
// other's defines).
#define WHY_REPLACING "REPLACING IN %1 S"
#define WHY_NO_AIRFRAME "UNABLE - NO AIRFRAME"
// JUMP BOARDING BY MESSAGE (user, 2026-11-02: "have team leader send a board
// message then move the team to cargo"). After the WILCO the aircraft asks,
// BOARD_PROMPT_DELAY s on so the WILCO is filed first; the run waits in
// PHASE_BOARD for the leader's BOARD (FUNC(srvBoard)) - BOARD_WAIT_MAX s at
// most, then it is stood down.
#define PHASE_BOARD "board"
#define WORD_BOARD "board"
#define PROMPT_BOARD_TEXT "ON STATION - SEND BOARD WHEN READY"
#define PROMPT_BOARD_AGAIN "%1 - SEND BOARD WHEN READY"
#define PROMPT_BOARD_ANSWERS "board,abort"
#define BOARD_PROMPT_DELAY 3
#define BOARD_WAIT_MAX 1800
#define ETA_BOARD "BOARD TO RED LIGHT"
#define SAID_STICK_ABOARD "STICK ABOARD - %1 %2"
#define SAID_NOT_BOARDED "NOT BOARDED - STOOD DOWN"
// The module's EXIT and IN THE AIRCRAFT combos, by their index.
#define BAYS [BAY_SEATS, BAY_STAND]
// Where the type sits among the support types (transport 10 ... QRF 50).
#define JUMP_TYPE_ORDER 60
#define SUPPORT_TYPES [[JUMP_TYPE, "JUMP", "AIRCRAFT", "AIRCRAFT", JUMP_TYPE_ORDER, [[JUMP_TASK, "JUMP", "", "HALO, HAHO or static line for the squad - file a JUMP REQUEST to it", [], false, "", []]]]]
// The reach card's effect line: the altitudes flown.
#define REACH_EFFECT "HALO %1 M - HAHO %2 M - STATIC %3 M"
#define ETA_UNKNOWN -1
// The support core's order kind for the JUMP REQUEST (its JUMP_CARDS) and the
// words its reply hook is handed.
#define ORDER_JUMP "jump"
#define WORD_STOP "stop"
#define WORD_GO "go"
// THE MESSAGE TEMPLATES (docs/DESIGN_MESSAGE_TEMPLATES.md, tree 2,
// 2026-11-09): ABORT (no longer a stop - the run is stood down as ABORT always
// did it, FUNC(srvAbort)), NO DROP (FUNC(srvNoDrop)), ESCORT
// (EFUNC(support_air,escortCall)) and FRAGO (FUNC(srvFrago)).
#define WORD_ABORT "abort"
#define WORD_NO_DROP "nodrop"
#define WORD_ESCORT "escort"
#define WORD_FRAGO "frago"
// NO DROP: on the run-in or at the green light, no jump - it circles for
// another pass, which is not counted; holding over the DZ after the last pass,
// it stops putting men out and holds.
#define SAID_NO_DROP_CIRCLE "NO DROP - CIRCLING FOR PASS %1"
#define SAID_NO_DROP_NOT_RUN "NO DROP - NOT ON THE RUN"
#define PROMPT_NO_DROP_HOLD "NO DROP - HOLDING OVER THE DZ - %1 ABOARD - GO WHEN READY"
#define PROMPT_NO_DROP_ANSWERS "go"
// FRAGO: the red and green light, the pickup, the passes, the type and the
// exit, before the run starts (before BOARD, or WHEELS UP).
#define SAID_FRAGO "WILCO FRAGO - %1"
#define SAID_FRAGO_LATE "FRAGO NOT TAKEN - THE RUN HAS STARTED"
#define SAID_NO_ESCORT_MODULE "UNABLE - NO JUMP AIRCRAFT MODULE TO TAKE ESCORTS FROM"
// AN RTB WITH A LANDING POINT (user, 2026-11-09: "we need a way to set an rtb
// landing location if an aircraft has players on board"; FUNC(srvRtbLand)):
// the RTB card's LAND AT point while players are aboard
// (EFUNC(support,rtbLanding)) - it flies there and lands (a helicopter on the
// point, a plane at the nearest airfield), everyone aboard gets out once it is
// down (slower than RTB_STOPPED_KMH on the ground), then home. No airfield for
// a plane: said, and the RTB is flown as before.
#define PHASE_LAND "land"
#define RTB_LAND_MODE "GET OUT"
#define RTB_STOPPED_KMH 5
#define RTB_LEAVE_DIST 4000
// A man standing in the bay is set down this way off the hull's heading.
#define RTB_EXIT_BEARING 90
#define SAID_RTB_LANDING "RTB - LANDING AT %1 - %2 ABOARD"
#define SAID_RTB_LANDED "LANDED AT %1 - PAX OFF - RTB"
#define SAID_RTB_NO_FIELD "UNABLE TO LAND - NO AIRFIELD ON THIS MAP"
// STATUS (the support core's "status" hook): the run's phase and pass.
#define STATUS_RUN "%1 - %2 - PASS %3 OF %4 - %5 ABOARD"
#define STATUS_IDLE_WORD "IDLE"
// THE PICKUP: the leader's men this close to it (m, 2D) are the stick. An
// empty pickup is where the leader is.
#define JUMP_PICKUP_RADIUS 200
// The red and green lights at least this far apart (m): the heading is the
// line through them.
#define JUMP_RUN_MIN 100

// THE CARDS the aircraft files in the thread (jmfsb_support's built-ins, the
// deck's when it has them), their text line, and FLASH.
#define CARD_WHEELS_UP "wheelsup"
#define CARD_RED_LIGHT "redlight"
#define CARD_GREEN_LIGHT "greenlight"
#define CARD_STICK_OUT "stickout"
#define CARD_INBOUND "inbound"
#define CARD_TEXT_KEY "Text.A"
#define PRIORITY_FLASH "high"
// What it says. CANTCO: the readiness check and the card's own gaps.
#define WHY_BY_CARD "BY MESSAGE - FILE A JUMP REQUEST"
#define WHY_LEADERS "SQUAD LEADERS ONLY"
#define WHY_NO_TYPE "NO JUMP TYPE"
#define WHY_NO_RED "NO RED LIGHT"
#define WHY_NO_GREEN "NO GREEN LIGHT"
#define WHY_RUN_SHORT "RED AND GREEN LIGHT TOO CLOSE"
#define WHY_TASKED "TASKED"
#define WHY_NOBODY "NOBODY AT THE PICKUP"
#define WHY_NO_CHUTE "%1 %2 WITHOUT A PARACHUTE"
#define WHY_NO_MASK "%1 %2 WITHOUT A MASK"
#define WHY_NO_AIRCRAFT "NO JUMP AIRCRAFT"
#define WHY_NO_LAUNCH "COULD NOT LAUNCH"
// A module's aircraft turning round after a run.
#define WHY_COOLDOWN "COOLDOWN %1 S"
#define WORD_MAN "MAN"
#define WORD_MEN "MEN"
// ROGER, WILCO's words, and the ETA's.
#define WILCO_SEP " - "
#define WILCO_TYPE "%1 %2 M"
#define WILCO_MEN "%1 %2"
#define WILCO_PASSES "%1 PASS%2"
#define WILCO_EXITS [[EXIT_AUTO, "AUTO EXIT"], [EXIT_MANUAL, "MANUAL EXIT"]]
#define WILCO_WIND "SHIFTED %1 M FOR WIND"
#define WILCO_LEFT "%1 NOT AT THE PICKUP"
#define ETA_RED "RED LIGHT IN"
// The milestones' detail lines.
#define SAID_ABOARD "%1 ABOARD"
#define SAID_PASS "PASS %1 OF %2"
#define SAID_STAND_BY "STAND BY"
#define SAID_HOOK_UP "STAND UP, HOOK UP"
#define SAID_AUTO "%1 OUT ON THE LIGHT"
#define SAID_MANUAL "JUMP FROM THE ACTION MENU"
#define SAID_OUT "%1 OUT - %2 ABOARD"
#define SAID_CIRCLING "CIRCLING FOR PASS %1"
#define SAID_LEAVING "STICK OUT - LEAVING THE DZ"
#define SAID_EMPTY "CABIN EMPTY - LEAVING THE DZ"
#define SAID_GO "%1 OUT OVER THE DZ"
#define SAID_NO_RESPONSE "NO RESPONSE"
#define SAID_LOST "AIRCRAFT LOST"
#define SAID_OUT_OF_TIME "OUT OF TIME - %1 PUT OUT"
#define SAID_STOOD_DOWN "STOOD DOWN BEFORE WHEELS UP"
// THE ASKS (the support core's prompt, D9 on the last one): men still aboard
// after the last pass, and after an ABORT.
#define PROMPT_HOLD_TEXT "MEN STILL ABOARD - HOLDING OVER THE DZ"
#define PROMPT_HOLD_ANSWERS "go,nodrop,abort"
#define PROMPT_ABORTED_TEXT "ABORTED - HOLDING OVER THE DZ - %1 ABOARD - JUMP WHEN READY"
#define PROMPT_ABORTED_ANSWERS "go,nodrop"
// The run's path on the asset row (the support pin draws it from the
// aircraft while the thread is IN_PROGRESS): [point, word] each.
#define PLAN_RUN_IN "RUN-IN"
#define PLAN_RED "RED"
#define PLAN_GREEN "GREEN"

// THE FLIGHT PATH, m: the aircraft appears RUN_IN before the red light on the
// line through it and the green light, carries straight on RUN_OUT past the
// green light before turning, and a manual stick's window is WINDOW_LEN past
// it. POINT_RING is how close to a turning point counts as there.
#define RUN_IN 3000
#define RUN_OUT 1500
#define WINDOW_LEN 1500
#define POINT_RING 600
// A plane appears at this share of its top speed (km/h in config).
#define PLANE_START_SPEED 0.6
#define KMH_PER_MS 3.6
// The hold over the drop zone while men are still aboard after the last pass.
#define HOLD_RADIUS 800
// Gone: this far from the green light with nobody aboard, and a run lasts
// this long at most.
#define LEAVE_DIST 4000
#define RUN_MAX_S 1800
// The run's watch, s.
#define RUN_TICK 0.5

// THE STICK: seconds between jumpers out, the static line's pull after exit
// and its canopy watch (support_air's JUMP_INTERVAL, STATIC_OPEN_DELAY and
// CHUTE_TICK, whose chuteTick opens the canopy).
#define JUMP_INTERVAL 0.7
#define STATIC_OPEN_DELAY 1
#define CHUTE_TICK 0.1
// Out behind the aircraft, not through it: clearance behind the tail and
// under the belly, m, and the spread either side.
#define EXIT_TAIL_GAP 3
#define EXIT_BELLY_GAP 3
#define EXIT_SIDE 2
// STANDING IN THE BAY (setting "stand"): fixed to the hull in two files
// either side of the centreline, this far apart, from this share of the
// hull's length back of centre to this share forward, this high over the
// hull's floor. Fixed, not walked: the engine does not carry a walking man
// in a moving aircraft; an aircraft that does gets "seats" and its own bay.
#define STAND_FILE_X 0.8
#define STAND_SPACING 1
#define STAND_FROM -0.35
#define STAND_TO 0.1
#define STAND_FLOOR 1.2
// The side's cargo aircraft - a module with no class, and a side's own jump
// aircraft (the Jump aircraft setting is retired, 2026-11-02): west, east,
// independent.
#define DEFAULT_AIRCRAFT ["B_T_VTOL_01_infantry_F", "O_T_VTOL_02_infantry_F", "B_T_VTOL_01_infantry_F"]

// A run's phases.
#define PHASE_IN "in"
#define PHASE_RED "red"
#define PHASE_GREEN "green"
#define PHASE_CIRCLE "circle"
#define PHASE_HOLD "hold"
#define PHASE_LEAVE "leave"

// The manual exit's place in the action menu.
#define ACTION_PRIORITY 10
#define NOTIFY_TITLE "JUMPMASTER"

// WIND (user, 2026-10-30): where the stick lands. The engine carries a canopy
// with the wind and a free-falling man not at all, so the drift is the wind
// for the seconds under canopy at this sink rate - the engine's canopies,
// near enough (FUNC(drift)). From this much drift, m, the aircraft shifts the
// run upwind by it (FUNC(windShift), automatic since 2026-11-02).
#define CANOPY_SINK_MS 5
#define WIND_MIN_M 20
// THE FREEFALL READOUT (FUNC(altCell)) on the phone's status row -
// jmfsb_devices' cell: icon word, value, state (its STATE_OFF .. STATE_ALERT)
// - from this height over the ground, red at this share of the pull
// altitude. The watch that takes it off the row again (FUNC(altWatch)) looks
// every this many seconds for the man this low out of any vehicle.
#define ALT_ICON "ALT"
#define ALT_MIN_AGL 20
#define ALT_PULL_K 0.5
#define ALT_WATCH_S 1
#define ALT_DOWN_M 2
#define JM_STATE_OFF 0
#define JM_STATE_OK 1
#define JM_STATE_WARN 2
#define JM_STATE_ALERT 3
