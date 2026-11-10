#define COMPONENT training
#define COMPONENT_BEAUTIFIED Training
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_TRAINING
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_TRAINING
    #define DEBUG_SETTINGS DEBUG_SETTINGS_TRAINING
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// FUNC(garrison) defaults, as CBA_fnc_taskDefend takes them: the chance a man
// patrols instead of taking a building, the chance he holds it in combat, and
// the fewest positions a building needs to be used.
#define DEFAULT_PATROL      0.2
#define DEFAULT_HOLD        0.5
#define DEFEND_THRESHOLD    2

// FUNC(areaOf): a marker icon or an object with no area is a point - garrison
// this far round it.
#define POINT_RADIUS        100

// FUNC(garrison): tries at a random dry spot in the area before falling back
// to its centre.
#define SPAWN_TRIES         20

// FUNC(resetPads): a target counts as on its pad within this, and its
// replacement comes this long after the wreck is cleared.
#define PAD_RADIUS          5
#define PAD_RESPAWN_DELAY   2
#define PAD_ICON            "\a3\ui_f\data\igui\cfg\simpletasks\types\target_ca.paa"

// FUNC(mout): the chance a spawn point is manned when the call gives none.
#define MOUT_CHANCE         30
#define MOUT_ICON_CREATE    "\a3\ui_f_curator\data\displays\rscdisplaycurator\modegroups_ca.paa"
#define MOUT_ICON_CLEAR     "\a3\ui_f\data\igui\cfg\simpletasks\types\exit_ca.paa"

// Notifications (jmfsb_notify).
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// ---- TAC//TRAINING app (user, 2026-11-07) ------------------------------------
#define APP_ID              "training"
#define APP_W               0.70
#define APP_H               0.78
#define APP_REFRESH         1
// Who gets it: the Trainer skill (PAC tag), or Sergeant and up - on a server
// whose PAC serverId is training.
#define TRAINER_TAG         "TRN"
#define TRAINER_MIN_RANK    "SERGEANT"
#define TRAINING_SERVER     "training"
#define TAB_MEDICAL         "medical"
#define TAB_AREAS           "areas"
#define TAB_VEHICLES        "vehicles"
#define TRAINING_TABS       [[TAB_MEDICAL, "PATIENTS"], [TAB_AREAS, "TRAINING AREAS"], [TAB_VEHICLES, "VEHICLE RANGES"]]

// Patients: the spawn points are JMSB - Medical Training modules' (FUNC(stretchers)).
#define STRETCHER_LIFT      0.35
// A synced object whose class name holds one of these is a station terminal,
// not a spawn point (FUNC(stretchers), FUNC(medicalLaptops)).
#define TERMINAL_WORDS      ["laptop", "computer", "terminal"]
#define LAPTOP_ICON         "\a3\ui_f\data\igui\cfg\actions\heal_ca.paa"
#define PATIENT_ANIM        "AinjPpneMstpSnonWnonDnon"
#define SECOND_WOUND_CHANCE 0.5
#define ARREST_DELAY        1
#define PRESETS             [["light", "LIGHT"], ["moderate", "MODERATE"], ["severe", "SEVERE"], ["arrest", "ARREST"], ["random", "RANDOM"], ["custom", "CUSTOM"]]
#define PRESET_RANDOM_FROM  ["light", "moderate", "severe", "arrest"]
#define BODY_PARTS          ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"]
#define BODY_LABELS         ["HEAD", "TORSO", "L ARM", "R ARM", "L LEG", "R LEG"]
#define LIMBS               ["leftarm", "rightarm", "leftleg", "rightleg"]
// jmfsb_medic's state words, by its patientState index.
#define MEDIC_STATE_WORDS   ["ARREST", "UNCONSCIOUS", "WOUNDED", "OK", "DEAD"]
// Wound kinds as ACE's damage types, and the damage each severity deals.
#define WOUND_KINDS         [["", "NONE"], ["bullet", "GSW"], ["explosive", "BLAST"], ["stab", "STAB"], ["punch", "BLUNT"]]
#define WOUND_SEVERITY      [[0.3, "LIGHT"], [0.6, "MEDIUM"], [1.2, "HEAVY"]]

// Training areas: JMSB - Training Area modules (FUNC(areas)); type by the
// module's Type index. A module with no area set is AREA_DEFAULT_SIZE m round.
#define AREA_DEFAULT_SIZE   75

#define TA_TYPES            [["cqb", "CQB"], ["city", "CITY"], ["patrol", "PATROL"], ["base", "BASE"]]
#define DENSITIES           [["light", "LIGHT"], ["medium", "MEDIUM"], ["heavy", "HEAVY"]]
#define TEAM_SIZE           4
#define CQB_MOVER_SHARE     0.2
#define CQB_SHARE           [0.15, 0.3, 0.5]
#define CITY_SHARE          [0.08, 0.15, 0.25]
#define CITY_PATROL_SHARE   0.25
#define BASE_SHARE          [0.2, 0.35, 0.5]
#define BASE_STATICS        [1, 2, 4]
#define BASE_VEHICLES       [0, 1, 2]
#define PATROL_TEAMS        [2, 4, 6]
// Open ground each extra man needs when a type counts its capacity, m2.
#define OPEN_GROUND_PER_MAN 2500
#define MIN_MEN             2
#define MAX_MEN             60
#define PATROL_STEP         50
#define PATROL_MAX          1000
#define PATROL_WAYPOINTS    6
#define PREVIEW_TIME        60
#define PREVIEW_COLOUR      "ColorRed"
#define RING_ALPHA          0.5
#define MAP_CTRL_TYPE       101
#define MAP_ANIM_TIME       0.3
#define FLAT_GRADIENT       0.3

// Vehicle ranges: JMSB - Vehicle Range modules (FUNC(vehRanges), user
// 2026-11-07): moving targets with no ammo, edge to edge and back. A
// direction is [label, heading of travel]; the module's Direction is its index.
#define VR_DIRECTIONS       [["N > S", 180], ["S > N", 0], ["E > W", 270], ["W > E", 90], ["NE > SW", 225], ["SW > NE", 45], ["NW > SE", 135], ["SE > NW", 315]]
#define VR_DEFAULT_COUNT    2
#define VR_MAX_COUNT        8
#define VR_DEFAULT_SPEED    30
#define VR_SPEED_STEP       10
#define VR_MAX_SPEED        80
#define VR_KMH_PER_MS       3.6
// Side by side across the run, this far apart; the turn points this far in
// from the edge; the edge is found in steps of VR_STEP; a run shorter than
// VR_MIN_RUN falls back to the centre line.
#define VR_LANE_GAP         30
#define VR_EDGE_INSET       15
#define VR_STEP             5
#define VR_MIN_RUN          40
#define VR_WP_RADIUS        10
#define VR_FLY_HEIGHT       100
// The crew: no targeting, no fighting, never get out.
#define VR_DISABLE_AI       ["AUTOTARGET", "TARGET", "AUTOCOMBAT", "SUPPRESSION", "FSM"]
#define SECONDS_PER_MINUTE  60

#define NOTE_TITLE          "Training"
#define NOTE_INFO           [0.761, 0.659, 0.471, 1]
