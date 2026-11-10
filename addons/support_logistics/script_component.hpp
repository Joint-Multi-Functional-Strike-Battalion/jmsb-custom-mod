#define COMPONENT support_logistics
#define COMPONENT_BEAUTIFIED Support Logistics
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_SUPPORT_LOGISTICS
    #define DEBUG_MODE_FULL
#endif
#ifdef DEBUG_SETTINGS_SUPPORT_LOGISTICS
    #define DEBUG_SETTINGS DEBUG_SETTINGS_SUPPORT_LOGISTICS
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The server's machine id - an order goes there by remoteExec (review S6).
#define SERVER_OWNER        2

// ---------------------------------------------------------------- provider --
// THE SUPPORT PROVIDER this addon registers with the support core
// (addons/support/README.md), kind "logi". Every asset id is "logi:<n>", n
// the module's index in GVAR(entities). The row type is "logistics" - the
// key support_air listed its Logistics Drop under before it moved here
// (user, 2026-11-01), so the screen keeps its LOGISTICS tab.
#define SUPPORT_KIND        "logi"
#define TYPE_LOGISTICS      "logistics"
// Between the kind and the index in an asset id - what FUNC(catalogNames)
// finds an asset's id inside a box id by.
#define ASSET_ID_SEP        ":"
// Where the type sits in the ASSET list: transport 10, CAS 20, artillery 30,
// then this, then support_air's QRF at 50.
#define ORDER_LOGISTICS     40

// Task tokens. "rtb" is the core's.
#define TASK_RTB            "rtb"
#define TASK_AIRDROP        "AIRDROP"
#define TASK_SLING          "SLING"
// The delivery point in the side's AiTR (user, 2026-11-02: "in AiTR lz and drop
// zones need to be highlighted"; EFUNC(support,zones)), by method.
#define ZONE_RESUPPLY       "resupply"
#define ZONE_SLING          "sling"

// ------------------------------------------------------------- the catalog --
// One orderable thing, as the server publishes it on the module
// (QGVAR(catalog)) and every screen reads it:
//   [name, kind, class, cargo, custom, mass, hook, load]
// name   what the ITEM stepper and every line say, upper case, unique
// kind   ITEM_VEHICLE / ITEM_OBJECT (an editor-placed reference) or
//        ITEM_CRATE (a crate filled from PAC arsenal lists)
// class  CfgVehicles class created for the delivery
// cargo  the reference's editor inventory, [weapons, magazines, items,
//        backpacks], each [[classes], [counts]]; [] for a PAC crate
// custom the reference's paint and parts (BIS_fnc_getVehicleCustomization),
//        [] for none
// mass   kg, read off the reference (or a crate made for the purpose);
//        -1 when it could not be read
// hook   the class has sling points at all
// load   a PAC crate's arsenal lists, comma-separated; "" otherwise
#define ITEM_NAME           0
#define ITEM_KIND           1
#define ITEM_CLASS          2
#define ITEM_CARGO          3
#define ITEM_CUSTOM         4
#define ITEM_MASS           5
#define ITEM_HOOK           6
#define ITEM_LOAD           7

#define ITEM_VEHICLE        "vehicle"
#define ITEM_OBJECT         "object"
#define ITEM_CRATE          "crate"

// What a reference area is searched for, and what is never an item in it.
#define CATALOG_KINDS       ["AllVehicles", "Thing", "ReammoBox_F"]
#define CATALOG_NEVER       ["CAManBase", "Animal", "Logic"]

// --------------------------------------------------------------- steppers --
// PARAMETER SLOTS (support core README). 27 DROP HEIGHT and 47 MARKING came
// over from support_air with the Logistics Drop and mean what they meant
// there (47 was CRATE SIGNAL). 46, support_air's CONTENTS, is retired: a PAC
// load is now an item of the catalog. 49-51 are new (2026-11-01):
//   49 CART   the order as [[catalog index, count], ...] - THE REAL SHAPE,
//             for the v2 board's cart. Read first when it holds a pair.
//   50 ITEM   a catalog index - the v1 screen's list stepper
//   51 COUNT  how many of it - the v1 screen's stepper
// Without a cart, ITEM and COUNT make a one-entry cart (FUNC(readCart)).
#define SLOT_DROP_ALT       27
#define SLOT_MARK           47
#define SLOT_CART           49
#define SLOT_ITEM           50
#define SLOT_COUNT          51

// Value tables behind the index steppers. Entry 0 is the module's own value.
#define DROP_ALT_TABLE      [0, 150, 250, 400, 600]
#define DROP_ALT_WORDS      ["MODULE", "150 M", "250 M", "400 M", "600 M"]
// Marking: index 0 is the module's Signal, the rest a choice per request -
// the class each one sets off on the landed item. The module's combo is the
// same table without MODULE: 0 smoke ... 4 none.
#define MARK_WORDS          ["MODULE", "SMOKE", "IR STROBE", "CHEMLIGHT", "FLARE", "NONE"]
#define MARK_CLASSES        ["", "SmokeShellBlue", "B_IRStrobe", "Chemlight_blue", "F_40mm_White", ""]
#define MARK_MODULE_OFFSET  1

// COUNT is at least one; the cap is the module's capacity (FUNC(tasks)), and
// anything a cart says is clamped to this before the capacity check.
#define COUNT_MIN           1
#define COUNT_MAX           99

// [label, slot, step, min, max, display, list, bar] - the core's stepper
// shape. ITEM and COUNT are per asset and added by FUNC(tasks).
#define STEP_DROP_ALT       ["DROP HEIGHT", SLOT_DROP_ALT, 1, 0, 4, DROP_ALT_WORDS, [], true]
#define STEP_MARK           ["MARKING", SLOT_MARK, 1, 0, 5, MARK_WORDS, [], false]

// ------------------------------------------------------- task declarations --
// [token, label, meta, guidance, steppers, needsPoint, pointLabel]. The
// delivery point is the task's own point - required, it is where it all goes.
#define DECL_AIRDROP [TASK_AIRDROP, "AIRDROP", "PARACHUTE", "Flies over the point and puts the order out under chutes, one item after another", [STEP_DROP_ALT, STEP_MARK], true, "DELIVERY POINT"]
#define DECL_SLING   [TASK_SLING, "SLING LOAD", "HOOK", "Brings each item in on a helicopter's hook and sets it down on the point", [STEP_MARK], true, "DELIVERY POINT"]

#define SUPPORT_TYPES [ \
    [TYPE_LOGISTICS, "LOGISTICS", "DELIVERY", "DELIVERIES", ORDER_LOGISTICS, [DECL_AIRDROP, DECL_SLING]] \
]

// ------------------------------------------------------------------ status --
#define STATUS_IDLE         "idle"
#define STATUS_COOLDOWN     "cooldown"
#define STATUS_EXPENDED     "expended"
#define STATUS_LAUNCHING    "launching"
#define STATUS_REPLACING    "replacing"
#define STATUS_INBOUND      "inbound"
#define STATUS_DROPPING     "dropping"
#define STATUS_SETTING      "setting down"
#define STATUS_LEAVING      "rtb"
// THE RESPAWN COUNT (user, 2026-11-02: "make sure there is a respawn count for
// each support, default no respawns"): its last airframe gone, the asset is
// gone - no row on the SUPPORT list (FUNC(entityRow)), and a card to its box
// answers this (FUNC(srvThread), FUNC(check)).
#define STATUS_GONE         "gone"
#define WHY_NO_AIRFRAME     "UNABLE - NO AIRFRAME"

// ----------------------------------------------------------- module values --
// The attributes' own defaults (CfgVehicles.hpp), for a logic that lacks one.
#define DEF_CALLSIGN        "MULE"
#define DEF_CRATE           "B_supplyCrate_F"
#define DEF_LISTS           "magazines"
#define DEF_CAPACITY        4
// Respawns (user, 2026-11-02: "default no respawns"): replacements for
// aircraft lost - a delivery that goes home uses none. -1 unlimited.
#define DEF_RESPAWNS        0
#define RESPAWNS_UNLIMITED  -1
// How the respawns left read on the reach card, the verdict and the SITREP:
// two or more, one, none (indexed from the end, FUNC(reach)).
#define SPARE_WORDS         ["%1 SPARE AIRFRAMES", "1 SPARE AIRFRAME", "LAST AIRFRAME"]
#define DEF_DROP_HEIGHT     250
#define DEF_OPEN_HEIGHT     -1
#define DEF_UNLOAD_HEIGHT   12
#define DEF_COOLDOWN        300
#define DEF_ITEM_COOLDOWN   30
#define DEF_RESPAWN         300
#define DEF_MAG_COUNT       10
#define DEF_ITEM_COUNT      2
// The side's vanilla heavy helicopter, by [west, east, independent] - what
// the Logistics Drop flew when its class was blank.
#define DEF_AIRCRAFT        ["B_Heli_Transport_03_unarmed_F", "O_Heli_Transport_04_covered_F", "I_Heli_Transport_02_F"]

// Fulfillment, the module's combo: one helicopter takes one load, or one
// helicopter flies per item.
#define FULFIL_ONE          0
#define FULFIL_EACH         1

// The lowest a drop may be released from, and the lowest a chute may be set
// to open at (m above the terrain).
#define DROP_HEIGHT_MIN     100
#define OPEN_HEIGHT_MIN     40
// THE UNLOAD HEIGHT is how high over the point the load hangs in the hover
// before it is lowered to the ground (2026-11-05, the set-down on Simplex's
// method - the load is put down, not dropped), no lower than this. It is
// carried at the support core's sling height - nap of the earth plus the
// rope and the load (user, 2026-11-01: the module's Sling Flight Height is
// retired).
#define UNLOAD_HEIGHT_MIN   5
// Cooldown Starts: 0 when the last aircraft is gone, 1 at the request.
#define COOLDOWN_AT_END     0
#define COOLDOWN_AT_START   1

// ---------------------------------------------------------------- flying --
// THE SUPPORT CORE'S TACTICAL FLIGHT (user, 2026-11-01): the phase its
// EFUNC(support,flightHeight) and EFUNC(support,flyAt) answer for between the
// base and the point - nap of the earth for a helicopter (higher with a load
// on the hook), the fixed-wing transit altitude for a plane.
#define FLY_TRANSIT         "transit"
// The sling watch, seconds.
#define AIR_TICK            1
// The airdrop watch is finer: it puts one item out every DROP_INTERVAL.
#define DROP_TICK           0.25
#define DROP_INTERVAL       1
// A sortie that has not finished in this long is written off and swept.
#define SORTIE_TIMEOUT      1800
// The plan label of the leg home to the module (row field 8), where every
// delivery aircraft is removed (user, 2026-11-02: virtual until tasked).
#define PLAN_BASE           "BASE"
// Close enough to the module, home, to be removed (despawned back to virtual,
// user 2026-11-02).
#define HOME_RING           600
// Past the point, where an airdrop aircraft is pointed so it never turns
// back over the drop to reach a waypoint it overflew.
#define OVERFLY             2000
#define KMH_PER_MS          3.6
// AIRDROP (2026-11-05, modelled on Simplex Support Services' logistics; no
// code of it used): the first item leaves this many seconds of flight short
// of the point and this much more (m), so the chute drifts onto it, not past
// - plus STICK_CENTRE of the stick's length, so the middle of the stick,
// not its first item, is on the point (Simplex offsets its release point by
// half the stick the same way).
#define CHUTE_LEAD_TIME     2
#define CHUTE_LEAD_EXTRA    80
#define STICK_CENTRE        0.5
// A flying height is given to the AI again only when it changes by more
// than this (m): the shared controller climbs a stuck helicopter, and a
// watch that set the height back every tick undid that. HEIGHT_UNSET is
// none given yet (the watch state's "flyZ").
#define HEIGHT_TOLERANCE    1
#define HEIGHT_UNSET        -1
// Clearance behind the tail and under the belly when an item is put out (m).
#define TAIL_GAP            4
#define BELLY_GAP           4
// Only what the engine simulates falls: anything else hangs where it is
// made, so it opens its chute at once whatever the module says.
#define FREEFALL_KINDS      ["AllVehicles", "ThingX"]
// How long a free-falling item has to reach its opening height.
#define FREEFALL_PATIENCE   120
// SLING (2026-11-05, the set-down on Simplex's method, flown by
// support_air's own flight control - EFUNC(support_air,heliTake) - not the
// AI): the load hangs SLING_HANG m below the helicopter when it is hooked on
// (the hang is read off the rope and the load once they exist; this is the
// fallback). SLING_APPROACH m out the control takes the airframe and flies
// it, no faster than SLING_APPROACH_SPEED m/s, to a hover with the load the
// module's Unload Height over the point's surface; there (inside
// SLING_HOVER_RING m across and SLING_HOVER_BAND m up or down) it is lowered
// until the load rests on the ground - its underside within SLING_SET_DOWN m
// of the surface, or touching it - and the hook is let go. Not down
// SLING_PATIENCE s after the take, the load is let go where it hangs, said in
// the RPT. The point's surface - ground, roof, deck, the sea at SEA_LEVEL
// ASL - is the highest thing from SURFACE_SCAN_UP m above the terrain down
// to SURFACE_SCAN_DOWN m below it, the load itself looked past.
#define SLING_HANG          12
#define SLING_APPROACH      200
#define SLING_APPROACH_SPEED 12
#define SLING_HOVER_RING    6
#define SLING_HOVER_BAND    4
#define SLING_SET_DOWN      1.5
#define SLING_PATIENCE      90
#define SURFACE_SCAN_UP     50
#define SURFACE_SCAN_DOWN   2
#define SEA_LEVEL           0
// The watches' phases (the state's "phase"): the leg in; an airdrop's stick
// going out; a sling helicopter's unload hover and lowering; the leg home.
#define PHASE_IN            "in"
#define PHASE_DROP          "drop"
#define PHASE_HOVER         "hover"
#define PHASE_LOWER         "lower"
#define PHASE_OUT           "out"
// Helicopters of one sling order fly side by side this far apart (m), and
// set their loads down as far apart.
#define SLING_SPACING       60

// THE VERDICT AND THE REACH CARD. The ETA is support_air's estimate
// (EFUNC(support_air,flightTime)) at its NORMAL speed word, index 0 there.
#define ETA_SPEED_NORMAL    0
#define ETA_UNKNOWN         -1
#define REACH_SEP           " - "

// ------------------------------------------------------ resupply by message --
// STEP 7 (user, 2026-11-01: "per the doc i want to use the messaging system to
// call ai support"; DESIGN_SUPPORT_MESSAGING 5.4 and step 7). What the support
// core's card reader calls the cards (EFUNC(support,readOrder)), and the words
// its follow-up hook hands over.
#define ORDER_SUPPLY        "supply"
#define ORDER_DROP          "drop"
#define WORD_STOP           "stop"
#define WORD_RECEIVED       "received"
#define WORD_NOTFOUND       "notfound"
// THE MESSAGE TEMPLATES (docs/DESIGN_MESSAGE_TEMPLATES.md, 2026-11-09): ABORT
// (no longer a stop - a delivery stands down as RTB does), ESCORT, FRAGO and a
// RESUPPLY REQUEST filed in the thread ("task" - another run), and what the
// asset says to them.
#define WORD_ABORT          "abort"
#define WORD_ESCORT         "escort"
#define WORD_FRAGO          "frago"
#define WORD_TASK           "task"
#define SAID_FRAGO_LOADED   "FRAGO NOT TAKEN - LOADED"
#define SAID_FRAGO_DELIVERED "FRAGO NOT TAKEN - DELIVERED - SEND A NEW RESUPPLY REQUEST"
#define SAID_STILL_RUNNING  "UNABLE - STILL ON THE LAST RUN - SEND IT AFTER THE RECEIPT"
#define SAID_NO_RUN         "UNABLE - %1"
// Another RESUPPLY REQUEST in the thread (the provider's "threadCards").
#define THREAD_CARDS        [["resupply", ["resupply"]]]
// The CANTCO words (doc 5.2) this addon gives itself.
#define WHY_NO_TARGET       "NO TARGET LOCATION"
#define WHY_TASKED          "TASKED"
#define WHY_LOST            "LOST"
#define WHY_NO_STORES_OF    "NO STORES %1"
#define WHY_NO_METHOD       "NO %1"
// THE AIRDROP CARD IS A PARADROP (report-card review, user 2026-11-02,
// decision 3): a transport flies it; supplies by air are a RESUPPLY with
// METHOD AIRDROP. One filed to a logistics box is answered with this.
#define WHY_PARADROP        "PARADROP IS A TRANSPORT CARD - SEND RESUPPLY"
// The card's method words, as the task tokens.
#define METHODS             [["AIRDROP", TASK_AIRDROP], ["SLING", TASK_SLING]]
// A marking's colour, as the class it sets off: [marking word, [[colour,
// class], ...]]. A colour not listed keeps the marking's own class.
#define MARK_COLOURS [ \
    ["SMOKE", [["RED", "SmokeShellRed"], ["GREEN", "SmokeShellGreen"], ["YELLOW", "SmokeShellYellow"], ["PURPLE", "SmokeShellPurple"], ["ORANGE", "SmokeShellOrange"], ["BLUE", "SmokeShellBlue"], ["WHITE", "SmokeShell"]]], \
    ["CHEMLIGHT", [["RED", "Chemlight_red"], ["GREEN", "Chemlight_green"], ["YELLOW", "Chemlight_yellow"], ["BLUE", "Chemlight_blue"]]] \
]
// After the last item: the receipt (doc 5.4), and what the thread closes with.
#define PROMPT_RECEIPT      "PACKAGE AWAY - CONFIRM RECEIPT"
#define ANSWERS_RECEIPT     "received,notfound"
#define SAID_RECEIVED       "RECEIVED"
#define SAID_NOT_FOUND      "NOT FOUND - LANDED AT %1"
#define SAID_SILENT         "NO RESPONSE"
#define SAID_RETASKED       "RE-TASKED"
// The job's steps (QGVAR(threadJob)): on its way, asked for the receipt, or
// stood down by the issuer.
#define JOB_FLYING          "flying"
#define JOB_RECEIPT         "receipt"
#define JOB_STOPPED         "stopped"
// The WILCO's words.
#define WILCO_SEP           " - "
// ON THE WAY IN (user, 2026-11-01: "need more information like after rw
// inbound eta"): WHEELS UP "INBOUND - ETA m:ss" at the launch, then the
// support core's INBOUND and 1 MIN OUT - POP SMOKE (FUNC(inbound)).
#define CARD_WHEELS_UP      "wheelsup"
#define CARD_TEXT_KEY       "Text.A"
#define WHEELS_UP_INBOUND   "INBOUND - %1"

// TAKING FIRE is said in the asset's thread (user, 2026-11-05) through the
// support core's aircraft event (EFUNC(support,threadEvent)), once per
// HIT_SAID_S per airframe.
#define HIT_SAID_S          30
#define EVENT_TAKING_FIRE   "TAKING FIRE AT %1"
