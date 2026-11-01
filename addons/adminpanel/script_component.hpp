#define COMPONENT adminpanel
#define COMPONENT_BEAUTIFIED Admin Panel
#include "\z\jmfsb\addons\main\script_mod.hpp"

// The engine's own control styles and grid constants - ST_LEFT, ST_CENTER and
// friends. The console is a real dialog rather than something drawn onto the
// map, so unlike the tacpad's panels it declares its controls in config.
#include "\a3\ui_f\hpp\defineCommonGrids.inc"
#include "\a3\ui_f\hpp\defineResincl.inc"
#include "\a3\ui_f\hpp\defineResinclDesign.inc"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_ADMINPANEL
    #define DEBUG_MODE_FULL
#endif
    #ifdef DEBUG_SETTINGS_ADMINPANEL
    #define DEBUG_SETTINGS DEBUG_SETTINGS_ADMINPANEL
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// The tacpad's shared geometry - PAD, RULE_THICK, and where the ADMIN strip sits
// on the map screen. The console is a dialog of its own, but the button that
// opens it is a panel on the map like everything else in the suite.
#include "\z\jmfsb\addons\tacpad\shared.inc.hpp"

// EVERY CONTROL NUMBER, ONCE. The ported functions each carried their own copy
// of the handful of idcs they touched - forty-five files with a #define block at
// the top, which is forty-five places for a number to fall out of step with the
// dialog. They are declared here and the copies are gone.
#include "ui\idcs.inc.hpp"

// The one type height every control in the console, the message box and TIME /
// WEATHER is set to; inline <t size> varies it (FUNC(style), FUNC(fitHost)).
#define ADMIN_FONT_BASE (0.8 * (0.025 * safeZoneH))

// The device dialog's id (jmfsb_devices IDD_TABLET): the console's parent and
// the rectangle it is fitted to whenever the tablet is up, in any display mode
// (FUNC(openDisplay), FUNC(fitHost)). A number, not that addon's header - this
// addon is GPL and takes nothing of the suite's code.
#define ADMIN_TABLET_IDD 8970

// --- Time / weather (FUNC(envLoad) and friends) -----------------------------
// What the combos offer. Weather is in tens of percent, wind in m/s.
#define ENV_MINUTE_STEP     5
#define ENV_SPEEDS          [1, 2, 4, 6, 12, 24, 60, 120]
#define ENV_PERCENT_STEP    10
#define ENV_WIND_STEP       2
#define ENV_WIND_MAX        20
// Presets as [overcast %, rain %, fog %, wind m/s]. Rain only falls under heavy
// overcast - the engine's rule - so STORM carries full cloud with it.
#define ENV_PRESET_CLEAR    [0, 0, 0, 2]
#define ENV_PRESET_CLOUDY   [60, 0, 0, 4]
#define ENV_PRESET_STORM    [100, 100, 10, 14]
#define ENV_PRESET_FOGGY    [40, 0, 60, 0]
#define ENV_NOON            12
#define ENV_READOUT_TICK    1
// Below this the wind has no direction worth keeping; a set wind blows north.
#define ENV_WIND_CALM       0.1
#define ENV_PERCENT         100
#define ENV_MINUTES_PER_HOUR 60

// A picture showing a render-to-texture camera - PLAYER VIEW (FUNC(fitHost) keeps its shape).
#define RENDER_TARGET_TAG "r2t("

// --- Who may act (review S1-S7, 2026-10-31) ----------------------------------
// The server is always machine 2; `admin` answers 2 for a #login'd admin. The
// server's admin list has sources (jmfsb_common_fnc_adminSource): the mod's
// list and the grants made from this console are this addon's.
#define ADMIN_SERVER        2
#define ADMIN_LOGGED        2
#define ADMIN_SOURCE_MOD    "mod"
#define ADMIN_SOURCE_GRANT  "grant"
#define ADMIN_SP_IDS        ["_SP_AI_", "_SP_PLAYER_"]
// The SECRETS dialog's rows (review R4): the server's names
// (jmfsb_common's SECRET_NAMES, same order) and what the rows say.
#define SECRET_KEYS         ["livekitKey", "livekitSecret", "pacdbUrl", "pacdbKey"]
#define SECRET_LABELS       ["VOICE SERVER - API KEY", "VOICE SERVER - API SECRET", "DATABASE - CONNECTION STRING", "DATABASE - SERVICE KEY"]
// How often, in seconds, a client publishes its FPS for the console (review P8).
#define ADMIN_FPS_PERIOD    5

// --- STABILIZE (FUNC(stabilize), FUNC(stabilizeLocal)) ----------------------
// What ACM's casualty conversion asks of the patient himself (its
// ACM_evacuation_fnc_canConvert): no wound bleeding and, under its Require
// antibiotics setting, 0.9 of a 1 g dose of Ertapenem in him. ACE's six body
// parts, bandaged with ACM's pressure bandage (ACE's field dressing without
// ACM) pass after pass; the passes cap the work on a man who keeps bleeding.
// The dose is the 1 g ACM's own syringes label, IV, into the torso - the one
// part a tourniquet never occludes.
#define ACM_PATCH                 "ACM_evacuation"
#define ACM_REQUIRE_ANTIBIOTICS   "ACM_evacuation_requireAntibiotics"
#define ACE_VAR_BLEEDING          "ace_medical_woundBleeding"
#define ACE_VAR_UNCONSCIOUS       "ACE_isUnconscious"
#define STABLE_BODY_PARTS         ["head", "body", "leftarm", "rightarm", "leftleg", "rightleg"]
#define STABLE_BANDAGE_ACM        "PressureBandage"
#define STABLE_BANDAGE_ACE        "FieldDressing"
#define STABLE_BANDAGE_PASSES     20
#define STABLE_ERTAPENEM          "Ertapenem_IV"
#define STABLE_ERTAPENEM_IM       "Ertapenem"
#define STABLE_ERTAPENEM_MG       1000
#define STABLE_ERTAPENEM_MIN      0.9
#define STABLE_ERTAPENEM_PART     "body"
#define STABLE_ERTAPENEM_CARD     "Ertapenem IV (1g)"
// The console's notification colours: done, refused, news for the man acted on
#define NOTE_DONE                 [0.4, 0.702, 0.4, 1]
#define NOTE_FAIL                 [0.831, 0.267, 0.267, 1]
#define NOTE_INFO                 [0.871, 0.361, 0.188, 1]
// The server's machine id, for the requests that go to it (review R1)
#define SERVER_OWNER              2
// How long the server keeps a STABILIZE waiting for the patient's answer
#define STABLE_ANSWER_S           30
