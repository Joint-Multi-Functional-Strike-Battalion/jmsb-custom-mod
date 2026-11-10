#define COMPONENT evac
#define COMPONENT_BEAUTIFIED Evac
#include "\z\jmfsb\addons\main\script_mod.hpp"

// #define DEBUG_MODE_FULL
// #define DISABLE_COMPILE_CACHE

#ifdef DEBUG_ENABLED_EVAC
    #define DEBUG_MODE_FULL
#endif
#ifdef DEBUG_SETTINGS_EVAC
    #define DEBUG_SETTINGS DEBUG_SETTINGS_EVAC
#endif

#include "\z\jmfsb\addons\main\script_macros.hpp"

// Medic-gated evac that replaces engine respawn. A downed (ACE-unconscious)
// player is "evacuated" by a medic:
//   1. the ACTUAL player is fully healed in place (ace_medical_treatment_fnc_fullHeal)
//      and placed on the medic - same object, so their loadout is untouched;
//   2. a separate AI clone is spawned at the downed spot with the same loadout AND
//      the player's exact injuries copied across (the full ACE medical var surface
//      + hitpoint damage), then knocked unconscious.
// The AI is alive and fully mortal - it keeps the wounds it was cloned with, so it
// can still bleed out or go into cardiac arrest and die - but it NEVER wakes: any
// wake-up (treated to stable vitals, epi, etc.) is caught on the ace_unconscious
// event and immediately re-knocked-out. Set the mission to no respawn so the medic
// evac is the only way back. Pure ACE medical - no ACM dependency.

#define EVAC_DEFAULT_TIME 10   // seconds: medic evac progress-bar time

// The server's own evac checks (FUNC(evacServer), review S6). The action
// reaches 4 m; the server allows some drift while the bar runs and the call
// travels. One casualty is not evacuated twice inside the guard.
#define SERVER_OWNER 2
#define EVAC_RANGE 10          // metres, medic to casualty
#define EVAC_GUARD 10          // seconds between two evacs of one casualty
#define EVAC_SETTLE 1          // seconds before the clone takes its injuries
#define EVAC_PLACE_DIST 1.5    // metres: where the healed player is put, beside the medic
#define EVAC_PLACE_DIR 90      // degrees, relative to the medic
#define EVAC_FAIL_COLOR [0.831, 0.267, 0.267, 1]
