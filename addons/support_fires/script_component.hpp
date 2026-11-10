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

// The server's machine id - an order goes there by remoteExec (review S6).
#define SERVER_OWNER        2

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
#define SLOT_ADJUST         36

// ADJUST FIRE (TAC//SUPPORT v2 build step 6, 2026-11-01): what SLOT_ADJUST
// carries - the observer's call on an adjust mission (the ARTY screen's
// adjust pad). Unset or ADJ_NONE is an ordinary fire mission, as before.
//   ADJ_ROUND  one round from one gun, then the battery HOLDS for him
//   ADJ_FFE    the whole order (rounds per gun, guns, sheaf), then it holds
//   ADJ_END    end of mission: the held battery stands down, nothing fired
// While it holds, only that observer may call it again (FUNC(adjustFor)).
#define ADJ_NONE            0
#define ADJ_ROUND           1
#define ADJ_FFE             2
#define ADJ_END             3
// Where the call sits in an artillery order's options (FUNC(readOpts)).
#define OPT_ADJUST          10
// The other places in those options a call for fire by message sets after
// FUNC(readOpts) (2026-11-02, TARGET SHAPE and METHOD OF FIRE): rounds per
// gun, the sheaf (m) and its type, and - past readOpts' own - the free
// attitude of a linear target or a creeping walk (deg, -1 none) and its
// length (m, 0 none).
#define OPT_ROUNDS          1
#define OPT_SHEAF           2
#define OPT_SHEAF_TYPE      5
#define OPT_ATTITUDE        11
#define OPT_LENGTH          12
// FUNC(adjustFor)'s answers: refused, an order of its own, the held mission's.
#define ADJ_STATE_REFUSED   -1
#define ADJ_STATE_NEW       0
#define ADJ_STATE_HELD      1
// The held battery's status token, and how long it waits for the observer's
// next call after a salvo lands before it ends the mission itself (s).
#define STATUS_ADJUST       "adjusting"
#define ADJ_HOLD            300
// The rounds of an adjust mission the battery publishes for the observer's
// round log and map (the newest this many).
#define ROUNDS_KEPT         32

// Stepper ranges. A slot the player never touched reads as its minimum, which
// is what the screen shows for it - so every minimum below is a real order.
// The tops of ROUNDS, DELAY, INTERVAL and REPEAT are the module's own (its Max
// attributes, the Simplex limits); 0 there takes the stepper off the page.
#define SHEAF_STEP          25
// The smallest impact area the JFO HUD draws for a mission, m (FUNC(impactSet)).
#define IMPACT_MIN_RADIUS   50
// SHEAF_MAX is the default of the module's Max Sheaf Length (m) since
// 2026-11-02 (QGVAR(sheafMax), user: TARGET SHAPE): the top of the board's
// SHEAF stepper, of an AREA's radius, and of a LINEAR target's or a CREEPING
// walk's length - never over SHEAF_LIMIT.
#define SHEAF_MAX           300
#define SHEAF_LIMIT         1000
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
// A LINEAR target of a call for fire (2026-11-02): the guns spread along a
// line at any attitude, each over its own stretch of it (FUNC(aimPoint)). No
// stepper offers it and no module names it - the module's PARALLEL allows it.
// SHEAF_NAMES are what a mission's sheaf is called in its marker and
// acknowledgement, the linear one included.
#define SHEAF_LINEAR        4
#define SHEAF_NAMES         ["CONVERGED", "PARALLEL", "BOX", "CREEPING", "LINEAR"]
// A creeping barrage's guns stand side by side this far apart (m), across
// the walk.
#define CREEP_LANE          30
// THE GAP JITTERS (2026-11-02; the idea and the formula are Tun Firesupport
// by Tuntematon / Armafinland, its fnc_fire.sqf): a gun's next round comes
// the gap plus or minus JITTER_SHARE of it and JITTER_SHORT over it seconds -
// the jitter widens as the gap shortens - and never sooner than JITTER_FLOOR
// of the gap.
#define JITTER_SHARE        0.1
#define JITTER_SHORT        1.1
#define JITTER_FLOOR        0.3
#define DEG_FULL            360
// ELLIPTICAL DISPERSION (user, 2026-11-02, from the Tun Firesupport review): a
// round's own scatter round its aim point is an ellipse along the line of fire
// - the module's Dispersion is the range error, DISP_DEFLECTION_SHARE of it the
// deflection error across the line (FUNC(scatter)).
#define DISP_DEFLECTION_SHARE 0.4
// AIMING ERROR REMOVED BY ADJUSTING (user, 2026-11-02, from the Tun
// Firesupport review): the module's Aiming Error (m) moves a mission's first
// salvo off the point as one - an offset drawn once per salvo, inside an
// ellipse of that size along the line of fire, DISP_DEFLECTION_SHARE across.
// Every correction the observer calls multiplies it by AIM_DECAY, and so does
// the FIRE FOR EFFECT after them (FUNC(aimError)); under the gun's own
// Dispersion it is gone and only the dispersion is left.
#define VA_DEF_AIM_ERROR    100
#define AIM_DECAY           0.5
// AIRBURST (user, 2026-11-02, from the Tun Firesupport review): a card whose
// Engagement asks for AIRBURST fires HE that bursts AIRBURST_MIN to
// AIRBURST_MAX m over the ground on its own charge (FUNC(virtualRound)) -
// the fire for effect only: an adjusting round bursts on impact, as an FDC
// adjusts with a quick fuze. Where the fuze sits in an artillery order's
// options, after OPT_LENGTH.
#define FUZE_AIRBURST       "airburst"
#define OPT_FUZE            13
#define AIRBURST_MIN        7
#define AIRBURST_MAX        12
#define WORDS_AIRBURST      "%1 AIRBURST"
// SHOT AND SPLASH CUES (user, 2026-11-02; a splash cue is Tun Firesupport's
// idea): as the battery files SHOT or SPLASH in its thread, the caller - the
// issuer and the card's observer - hears a short cue on his machine
// (FUNC(cue), FUNC(cueLocal)). Vanilla Arma 3 sounds: the mod has no radio cue
// of its own, and Tun's voice clips are not copied. [card, CfgSounds class].
#define CUE_SOUNDS          [["shot", "Beep_Target"], ["splash", "FD_Start_F"]]

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
// Time between a gun's rounds is the module's reload (plus the INTERVAL
// asked for); the guns within one salvo are this far apart, so a sheaf lands
// as a ripple. VOLLEYS FOLLOW ON THE GUN'S OWN RHYTHM (2026-11-05, Simplex's
// loop): the next volley's first round is one gap after the gun's last, with
// no cooldown and no wait for the splash between them - the cooldown is paid
// once, at the mission's end (FUNC(finish)).
#define VA_GUN_STAGGER      0.4
// A mission waits this long after its last impact before it ends or holds,
// so the last round is down first.
#define VA_SETTLE           2
// The arc solver divides by the distance: a target on the battery is this far.
#define BALL_MIN_DIST       1
// THE TARGET'S HEIGHT OVER THE BATTERY (m), terrain to terrain, the sea at 0
// (2026-11-05: the arc is solved through the target's height, as Simplex's
// solver does it, so a battery on a hill fires down and the time of flight,
// the descent and the ETA say so). FUNC(ballistics)' fourth argument.
#define RISE(origin,target) ((0 max (getTerrainHeightASL (target))) - (0 max (getTerrainHeightASL (origin))))
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
// The longest CONTINUOUS FOR n MIN a call for fire may ask (2026-11-02).
#define VA_DEF_MAX_CONTINUOUS 10

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

// ------------------------------------------------------------------- reach --
// THE BOARD'S REACH CARD (FUNC(reach), the support core's "reach" hook,
// 2026-11-01). An ETA nobody can give is -1. Distances in the reason are
// kilometres to one decimal ("OUT OF RANGE 14.2/12 KM"); the effect line
// names at most REACH_ORD_SHOWN round types, plain ASCII between items (the
// tacpad font). A loitering module without a transit time has this reach -
// unlimited, so no ETA can be worked out from it (FUNC(moduleLoiter)).
#define REACH_ETA_UNKNOWN   -1
#define REACH_SEP           " - "
#define REACH_ORD_SHOWN     3
#define REACH_UNLIMITED     "UNL"
#define REACH_KM_DECIMALS   1
#define M_PER_KM            1000
#define LM_REACH_UNLIMITED  1e7

// ------------------------------------------------------------------ thread --
// THE BATTERY ACTS ON ITS THREAD (2026-11-01, DESIGN_SUPPORT_MESSAGING step 6;
// user: "per the doc i want to use the messaging system to call ai support").
// A CALL FOR FIRE filed to a battery's box is read by the support core
// (EFUNC(support,readOrder), kind "fire") and fired by FUNC(srvThread); the
// observer's replies come to FUNC(threadReply). See README, "Call for fire by
// message".
#define ORDER_FIRE          "fire"
// Warno 1, as the reader words it (suppress fires as fire for effect).
#define MISSION_ADJUST      "adjust"
#define MISSION_FFE         "ffe"
#define MISSION_IMMEDIATE   "immediate"
#define MISSION_WORDS       [["adjust", "ADJUST"], ["ffe", "FFE"], ["suppress", "SUPPRESS"], ["immediate", "IMMEDIATE SUPPRESSION"]]
// Control, as the reader words it: AT MY COMMAND holds the battery laid until
// the observer's CONFIRM; TIME ON TARGET times the first round onto the TOT
// line; CANNOT OBSERVE turns an adjust into fire for effect.
#define CONTROL_COMMAND     "command"
#define CONTROL_TOT         "tot"
#define CONTROL_CANNOT      "cannot"
// The card's shell as the battery's round kind (FUNC(stockFromTable)).
// AIRBURST fires HE with the airburst fuze (FUZE_AIRBURST, 2026-11-02).
#define SHELL_KINDS         [["HE", "he"], ["SMOKE", "smoke"], ["ILLUM", "illum"], ["CLUSTER", "cluster"], ["GUIDED", "guided"], ["AIRBURST", "he"]]
#define SHELL_AIRBURST      "AIRBURST"
// A round's kind from its ammo config (FUNC(ammoKind)) - the second column of
// SHELL_KINDS - and the CfgAmmo simulations that tell flares and smoke apart.
#define KIND_HE             "he"
#define KIND_SMOKE          "smoke"
#define KIND_ILLUM          "illum"
#define KIND_CLUSTER        "cluster"
#define KIND_GUIDED         "guided"
#define SIM_ILLUM           "shotilluminating"
#define SIM_SMOKE           ["shotsmoke", "shotsmokex"]
// A CFF SHIFT's target (the order's "method"; support's FIRE_BY_SHIFT). Its
// guns are laid for the known point's height plus the card's UP / DOWN
// (FUNC(layHeight)); the flattest descent the miss is worked out on (deg).
#define FIRE_BY_SHIFT       "shift"
#define LAY_MIN_DESCENT     5
// The words the core hands the "reply" hook (EFUNC(support,srvFollowUp)).
#define WORD_STOP           "stop"
#define WORD_ADJUST         "adjust"
#define WORD_FFE            "ffe"
#define WORD_REPEAT         "repeat"
#define WORD_CHECKFIRE      "checkfire"
#define WORD_CONFIRM        "confirm"
#define WORD_BDA            "bda"
// RECORD AS TARGET (user, 2026-11-02): the observer's `record` card - a word
// and a reply id alike.
#define WORD_RECORD         "record"
// THE MESSAGE TEMPLATES (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09): ABORT
// is no longer a stop - the battery checks fire and asks for intentions
// (PROMPT_ABORT); a second CALL FOR FIRE in the thread is a new mission on the
// same guns (WORD_TASK); a FRAGO (WORD_FRAGO) re-lays the mission from the
// order with its changes - shell, fuze, rounds, sheaf, method, or a new
// target - and fires it as the mission was called.
#define WORD_ABORT          "abort"
// Each call for fire takes the three in its thread (the provider's
// "threadCards" - the support core takes them from the issuer, WORD_TASK).
#define THREAD_FIRE_CARDS   ["callforfire", "cffpolar", "cffshift"]
#define THREAD_CARDS        [["callforfire", THREAD_FIRE_CARDS], ["cffpolar", THREAD_FIRE_CARDS], ["cffshift", THREAD_FIRE_CARDS]]
#define WORD_TASK           "task"
#define WORD_FRAGO          "frago"
// What fires again once the rounds in the air are down - and a new mission or
// a FRAGO, which re-lay the guns, likewise.
#define WORDS_FIRE          ["adjust", "ffe", "repeat", "confirm", "task", "frago"]
// The observer's corrections, along and across his line to the target.
#define DIR_ADD             "ADD"
#define DIR_DROP            "DROP"
#define DIR_LEFT            "LEFT"
#define DIR_RIGHT           "RIGHT"
#define RIGHT_ANGLE         90
#define HALF_TURN           180
// Laid on the target and waiting AT MY COMMAND - busy, so nobody else takes it.
#define STATUS_LAID         "laid"
// The cards the battery files in its thread, as itself
// (EFUNC(support,fileCard)): SHOT with its time of flight, SPLASH 5 s before
// impact, and its PROMPTS (doc 5.4): what it asks, and the reply ids it offers
// as answers, comma-separated.
#define CARD_SHOT           "shot"
#define CARD_SPLASH         "splash"
#define CARD_PROMPT         "prompt"
#define CARD_TEXT_KEY       "Text.A"
#define CARD_ANSWERS_KEY    "Answers.A"
#define PROMPT_ADJUST       "ADJUST?"
#define ANSWERS_ADJUST      "adjust,ffe,close"
#define PROMPT_COMPLETE     "ROUNDS COMPLETE - REQUEST BDA"
#define ANSWERS_COMPLETE    "bda,repeat,close"
#define PROMPT_UNOBSERVED   "ROUNDS COMPLETE - END OF MISSION?"
#define PROMPT_EOM          "END OF MISSION?"
#define ANSWERS_EOM         "close,repeat"
#define PROMPT_COMMAND      "READY - AT MY COMMAND"
#define ANSWERS_COMMAND     "execute,close"
#define PROMPT_CHECK_FIRE   "CHECK FIRE - HOLDING"
#define ANSWERS_CHECK_FIRE  "adjust,ffe,repeat,record,close"
#define PROMPT_NO_RESPONSE  "NO RESPONSE - HOLDING"
#define ANSWER_SEP          ","
// ROUNDS COMPLETE (2026-11-09): the battery files the card, what it has left
// as its text, before it asks for the BDA or the end of the mission.
#define CARD_ROUNDS_COMPLETE "roundscomplete"
// ABORT (2026-11-09): check fire, then the battery's intentions - its own
// answers, since MOVE and RTB mean nothing to guns.
#define PROMPT_ABORT        "ABORTED - CHECK FIRE - STATE INTENTIONS"
#define ANSWERS_ABORT       "repeat,adjust,ffe,callforfire,close"
// A new mission or a FRAGO the battery cannot lay: why, and the last mission
// still stands; a FRAGO laid says so (the WILCO of a mission already under way
// is not said twice - EFUNC(support,state)).
#define PROMPT_RETASK       "%1 - LAST MISSION STANDS"
#define ANSWERS_RETASK      "repeat,adjust,ffe,close"
#define SAID_FRAGO          "WILCO FRAGO - %1"
#define SAID_FRAGO_LAID     "RE-LAID"
// A volley's prompt comes as its last round lands - its SPLASH_LEAD before
// it, and never sooner than this after the volley's SPLASH (s), so it is
// filed second (FUNC(threadVolley), 2026-11-02).
#define PROMPT_LAG          0.5
// A BATTERY'S END-OF-MISSION PROMPTS (user, 2026-11-02): what it has left
// (FUNC(stockWords), "12 HE, 6 SMOKE LEFT") in the words, and RECORD AS TARGET
// among the answers. A launcher's keep the plain words above.
#define PROMPT_COMPLETE_LEFT    "ROUNDS COMPLETE - %1 - REQUEST BDA"
#define PROMPT_UNOBSERVED_LEFT  "ROUNDS COMPLETE - %1 - END OF MISSION?"
#define PROMPT_EOM_LEFT     "%1 - END OF MISSION?"
#define ANSWERS_COMPLETE_ARTY   "bda,record,repeat,close"
#define ANSWERS_EOM_ARTY    "close,record,repeat"
#define STOCK_LEFT          "%1 LEFT"
#define STOCK_ITEM          "%1 %2"
#define STOCK_SEP           ", "
#define STOCK_NONE          "NO ROUNDS LEFT"
// RECORD AS TARGET: the battery names the mission's point - where its last
// correction put it - a target, TARGET_FORMAT of its two letters
// (QGVAR(targetPrefix), FUNC(targetPrefix)) and a running number from
// TARGET_FIRST, and puts a map marker of that name on the map for its side.
// The name is a grid on any card (support gridPos reads a marker). A number
// that is already a marker - an Eden marker named so, a pre-planned target -
// is skipped. The client waits at most TARGET_WAIT s for a marker it is told
// about to arrive (JIP).
#define PROMPT_RECORDED     "RECORDED AS TARGET %1"
#define WHY_NO_RECORD       "NO TARGET NUMBER LEFT"
#define TARGET_FORMAT       "%1%2"
#define TARGET_FIRST        1001
#define TARGET_LAST         9999
#define TARGET_LETTERS      2
#define TARGET_PATTERN      "^%1\d{4}$"
#define TARGET_MARK_ICON    "mil_destroy"
#define TARGET_MARK_COLOR   "ColorRed"
#define TARGET_MARK_ALPHA   1
#define TARGET_WAIT         30
#define LETTER_A            65
#define LETTER_Z            90
#define ALPHABET            26
// D9 for artillery (user, 2026-11-01): a prompt left this long (s) is asked
// again as NO RESPONSE - HOLDING; this long, the battery stands down.
#define PROMPT_HOLD         180
#define PROMPT_END          300
// How long an observer's call waits for the rounds in the air to land (s).
// Not down by then (a continuous fire is minutes long): the call is dropped
// and the battery says so (2026-11-05) - a prompt with no D9 waits, since
// the mission is still firing; CHECK FIRE is taken at once.
#define CALL_WAIT           120
#define PROMPT_IN_AIR       "ROUNDS IN THE AIR - CALL AGAIN AFTER SPLASH"
#define ANSWERS_IN_AIR      "checkfire,close"
// What the battery closes its thread with.
#define SAID_EOM            "END OF MISSION"
#define SAID_NO_RESPONSE    "NO RESPONSE - END OF MISSION"
#define SAID_CANNOT_FIRE    "CANNOT FIRE"
// CANTCO words (doc 5.2), besides the reach card's own (FUNC(reach)).
#define WHY_NO_TARGET       "NO TARGET LOCATION"
#define WHY_NO_STORES       "NO STORES"
#define WHY_NO_STORES_OF    "NO STORES %1"
#define WHY_LOST            "LOST"
#define WHY_NO_TOT          "NO TOT"
#define WHY_TOT             "CANNOT MAKE TOT"
// A REQUEST ON STATION is an order to get in the air, never a fire mission
// (user, 2026-11-02): a battery or launcher answers it CANTCO.
#define ORDER_STATION       "station"
#define WHY_NOT_AIR         "NOT AN AIR ASSET"
// WILCO's words.
#define WILCO_SEP           " - "
#define DESCRIPTION_MAX     48
#define WHEN_COMMAND        "AT MY COMMAND"
#define WORD_DANGER_CLOSE   "DANGER CLOSE"
// TIME ON TARGET: the TOT line as HHMM or HH:MM, game time, at most TOT_MAX s
// of mission time ahead. The game clock runs timeMultiplier times mission
// time (never under TIME_MULTIPLIER_MIN, the engine's own floor). To the
// second and relative since 2026-11-02 (user): HHMMSS (HH:MM:SS), and +M -
// M game minutes from now (+5, +5 MIN). Groups: hours, minutes, the seconds
// with their colon, the seconds.
#define TOT_PATTERN         "^(\d{1,2}):?(\d{2})(:?(\d{2}))?$"
#define TOT_REL_PATTERN     "^\+ *(\d{1,3}) *(M|MIN)?$"
#define TOT_WORDS           "TOT %1"
#define TOT_PAD             2
#define HOURS_PER_DAY       24
#define SECONDS_PER_HOUR    3600
#define SECONDS_PER_MINUTE  60
#define SECONDS_PER_DAY     86400
#define TIME_MULTIPLIER_MIN 0.1
#define TOT_MAX             3600
// SHOT's words: an artillery salvo's or a missile's time of flight. A
// mission of several volleys numbers them on SHOT and SPLASH (2026-11-05:
// volleys follow on the gun's rhythm, so a volley's SHOT can come before the
// one before it has splashed, as in Simplex - the number says which is which).
#define CARD_TOF            "TOF %1"
#define CARD_TOF_VOLLEY     "VOLLEY %1 OF %2 - TOF %3"
#define CARD_VOLLEY         "VOLLEY %1 OF %2"
// TARGET SHAPE (user, 2026-11-02): the card's Shape line as the support core
// words it (FUNC(threadShape)). An AREA needs CONVERGED (else BOX) among the
// module's Sheaf Types, a LINEAR target PARALLEL, a CREEPING walk CREEPING -
// else CANTCO WHY_NO_SHEAF. No size on the card: SHAPE_AREA_DEF m of radius,
// SHAPE_LENGTH_DEF m of line or walk. WILCO's words for each, and the
// attitude written as three figures.
#define SHAPE_AREA          "area"
#define SHAPE_LINEAR        "linear"
#define SHAPE_CREEPING      "creeping"
#define SHAPE_AREA_DEF      100
#define SHAPE_LENGTH_DEF    200
#define WHY_NO_SHEAF        "SHEAF NOT AVAILABLE"
#define WORDS_AREA          "AREA %1 M"
#define WORDS_LINEAR        "LINEAR %1 M ATT %2"
#define WORDS_CREEPING      "CREEPING %1 M DIR %2"
#define DEG_FIGURES         3
// METHOD OF FIRE (user, 2026-11-02; FUNC(threadMethod)): INTERVAL n S and n
// VOLLEYS, or CONTINUOUS FOR n MIN - each gun firing one round per reload
// plus the interval for that long, up to the module's Max Continuous Fire.
#define WORDS_INTERVAL      "INTERVAL %1 S"
#define WORDS_VOLLEYS       "%1 VOLLEYS"
#define WORDS_CONTINUOUS    "CONTINUOUS %1 MIN"
#define WHY_NO_CONTINUOUS   "CONTINUOUS FIRE NOT AVAILABLE"
// THE COMPOSER'S PREVIEW BEFORE SEND (user, 2026-11-02, from the Tun
// Firesupport review; FUNC(cardPreview), the support core's "cardPreview"
// hook): one verdict line and the footprint on the player's map, worked out
// on his machine from what the server published, through the reads the
// server decides with. The marker specs are the support core's pinMarker's;
// an ellipse is drawn as a closed line of PREVIEW_ELLIPSE_POINTS points.
#define PREVIEW_ICON        "icon"
#define PREVIEW_RING        "ring"
#define PREVIEW_LINE        "line"
#define PREVIEW_COLOUR_OK   "ColorOrange"
#define PREVIEW_COLOUR_BAD  "ColorRed"
#define PREVIEW_ICON_TARGET "mil_destroy"
#define PREVIEW_ICON_END    "mil_dot"
#define PREVIEW_ICON_LABEL  "EmptyIcon"
#define PREVIEW_ICON_SIZE   1
#define PREVIEW_END_SIZE    0.6
#define PREVIEW_BRUSH       "Border"
#define PREVIEW_ALPHA       1
#define PREVIEW_ELLIPSE_POINTS 24
#define PREVIEW_CANTCO      "CANTCO - %1"
#define PREVIEW_IN_RANGE    "IN RANGE %1 (MIN %2, MAX %3)"
#define PREVIEW_DC          "DANGER CLOSE - FRIENDLY %1 M"
#define PREVIEW_DC_REFUSED  "%1 - FRIENDLY %2 M"
#define PREVIEW_LABEL       "%1 %2"
#define PREVIEW_TOF         "TOF %1 S"
#define PREVIEW_WALK_END    "WALK END"

// ------------------------------------------------------------ thread strike --
// CRUISE MISSILES AND LOITERING MUNITIONS BY MESSAGE (2026-11-01; user: they
// get the `callforfire` card and must act on it, as artillery does). A CALL
// FOR FIRE to their box is one launch (FUNC(threadStrike)); see README, "Call
// for fire by message". There is no adjusting missile: an ADJUST Warno is
// refused, none ticked is fire for effect.
#define WHY_NO_ADJUST       "ADJUST NOT AVAILABLE"
// A loitering munition hunts: when it strikes is not known.
#define WHY_TOT_HUNT        "TOT NOT AVAILABLE"
// Engagement shells a missile or munition cannot be: its warhead is its own.
#define STRIKE_SHELLS_NONE  ["SMOKE", "ILLUM"]
// WILCO's load, singular and plural, and a munition's transit to the point.
#define LOAD_MISSILES       ["MISSILE", "MISSILES"]
#define LOAD_MUNITIONS      ["MUNITION", "MUNITIONS"]
#define WORDS_TRANSIT       "TRANSIT %1 S"
// The launch is down and it waits for the observer's BDA - busy, the thread
// open, the target still marked.
#define STATUS_HOLDING      "holding"
#define SAID_COMPLETE       "rounds complete, over"
// What is still in the air: a battery's rounds, missiles, munitions.
#define STATUSES_AIRBORNE   [STATUS_FIRING, STATUS_INBOUND, STATUS_STATION]
// The observer's words a launch hears; adjust, fire for effect and check fire
// are artillery's.
// ABORT, a new mission and a FRAGO too (2026-11-09) - a launcher's ABORT ends
// it as CLOSE does: what is in the air flies on.
#define WORDS_STRIKE        [WORD_STOP, WORD_REPEAT, WORD_CONFIRM, WORD_BDA, WORD_ABORT, WORD_TASK, WORD_FRAGO]
