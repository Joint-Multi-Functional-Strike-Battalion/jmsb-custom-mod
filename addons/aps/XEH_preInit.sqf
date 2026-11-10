#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// THE TIER TABLE - the same numbers tools/gen_us_factions.py builds the
// factions' ammunition to (TIER / DEFAULT_TIER there): 4 peer+, 3 peer, 2
// near-peer, 1 and 0 irregular. Keyed lower-case on the faction class. A
// faction not here - a mod's, or the base game's - takes GVAR(defaultTier),
// and a module or the Tier Overrides setting can move any of them.
GVAR(tierTable) = createHashMapFromArray [
    ["jmfsb_csat", 4], ["jmfsb_csat_tna", 4], ["jmfsb_pla_ard", 4], ["jmfsb_pla_wdl", 4],
    ["jmfsb_raf_wdl", 3], ["jmfsb_raf_ard", 3], ["jmfsb_raf_alp", 3],
    ["jmfsb_us_jtf_wdl", 3], ["jmfsb_us_jtf_des", 3], ["jmfsb_us_jtf_tna", 3], ["jmfsb_us_jtf_ocp", 3],
    ["jmfsb_eudf", 3], ["jmfsb_eudf_arc", 3], ["jmfsb_eudf_ard", 3],
    ["jmfsb_marine_wdl", 3], ["jmfsb_marine_des", 3],
    ["jmfsb_himf", 2], ["jmfsb_aaf", 2], ["jmfsb_ldf", 2],
    ["jmfsb_fia", 1], ["jmfsb_fia_ind", 1], ["jmfsb_insurgents", 1],
    ["jmfsb_syndikat", 0],
    // the base game's own, for a mission that places them
    ["blu_f", 3], ["blu_t_f", 3], ["blu_w_f", 3], ["opf_f", 3], ["opf_t_f", 3], ["opf_r_f", 3],
    ["ind_f", 2], ["ind_e_f", 2], ["ind_c_f", 0], ["ind_g_f", 1], ["blu_g_f", 1], ["opf_g_f", 1],
    ["blu_ctrg_f", 3], ["opf_v_f", 4]
];

// THE FITS. Charges per side, how far out the launcher looks, which
// projectile families it engages, and whether it takes on tank rounds
// (the enhanced fit alone - shells are too fast to fly out to, so they are
// killed on sight at APS_SHELL_RANGE). A BASIC fit covers the front half
// only; everything above is all-round.
//                    charges  range  families                                                          shells  front-only
GVAR(fits) = createHashMapFromArray [
    [FIT_BASIC,    [2,   100, ["RocketCore"],                                                     false,  true]],
    [FIT_LIGHT,    [2,   100, ["RocketCore"],                                                     false,  false]],
    [FIT_MEDIUM,   [3,   100, ["RocketCore", "MissileCore", "SubmunitionCore"],                   false,  false]],
    [FIT_HEAVY,    [5,   100, ["RocketCore", "MissileCore", "SubmunitionCore", "ammo_Penetrator_Base"], false, false]],
    [FIT_ENHANCED, [6,   200, ["RocketCore", "MissileCore", "SubmunitionCore", "ammo_Penetrator_Base"], true,  false]]
];

// WHAT THE CREW CALLS IT, by side - the brand, then the grade.
GVAR(brands) = createHashMapFromArray [
    [west, "Trophy"], [east, "Afganit"], [independent, "Iron Fist"], [civilian, "APS"]
];
GVAR(grades) = createHashMapFromArray [
    [FIT_BASIC, "(basic)"], [FIT_LIGHT, "LV"], [FIT_MEDIUM, "MV"], [FIT_HEAVY, "HV"], [FIT_ENHANCED, "HV-E"]
];

// projectiles the launchers never engage: our own blasts and the game's
// helicopter-explosion effects, which are ammo classes too
GVAR(blacklist) = [QGVAR(blast), QGVAR(pulse), "SmallSecondary", "HelicopterExploSmall", "HelicopterExploBig"];

GVAR(moduleUp) = false;
GVAR(hardKill) = true;
GVAR(rfBurst) = true;
GVAR(rfAir) = true;
GVAR(debug) = false;
GVAR(tierOverride) = createHashMap;
GVAR(fitOverride) = createHashMap;

ADDON = true;
