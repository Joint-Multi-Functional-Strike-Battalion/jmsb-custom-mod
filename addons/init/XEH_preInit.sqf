#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A -- Tinkered with by YonV
 * The mission's preInit, as an addon's. This was scripts\preInit.sqf, wired
 * into description.ext's Extended_PreInit_EventHandlers; it is CfgEventHandlers
 * now and runs the same order for the same reasons.
 */

ADDON = false;

// Guards the one-shot build in FUNC(missionConfigsReady), which is called from
// both this preInit and the mission's own handover.
GVAR(configsBuilt) = false;

#include "XEH_PREP.hpp"

// Hoisted: a comma inside a macro argument reads as an argument separator, so
// the select cannot be written inline in an INFO call.
private _phase = ["preInit","EDEN"] select is3DEN;

INFO(_phase,"Initializing CBA Settings...");

// What is loaded. Read by nearly every system that follows, so it is answered
// once here rather than re-asked at every call site.
EGVAR(patches,usesACE)          = isClass (configFile >> "CfgPatches" >> "ace_main");
EGVAR(patches,usesACEArsenal)   = isClass (configFile >> "CfgPatches" >> "ace_arsenal");
EGVAR(patches,usesACETagging)   = isClass (configFile >> "CfgPatches" >> "ace_tagging");
EGVAR(patches,usesACEX)         = isClass (configFile >> "CfgPatches" >> "acex_main");
EGVAR(patches,usesKat)          = isClass (configFile >> "CfgPatches" >> "kat_main");
EGVAR(patches,usesACRE)         = isClass (configFile >> "CfgPatches" >> "acre_sys_core");
// TFAR (classic or standalone). Then jmfsb_adapter_tfar tunes from the PAC net
// plan; with neither radio mod voice is game VoIP (jmfsb_voice).
EGVAR(patches,usesTFAR)         = isClass (configFile >> "CfgPatches" >> "task_force_radio") || {isClass (configFile >> "CfgPatches" >> "tfar_core")};
EGVAR(patches,usesZen)          = isClass (configFile >> "CfgPatches" >> "zen_main");
// ALiVE IS DELIBERATELY NOT IN THIS LIST. EGVAR(patches,usesAlive) is set by
// EFUNC(adapter_alive,XEH_preInit) instead, because that addon is the only one
// allowed to know ALiVE exists - see addons/adapter_alive. A mission
// reading jmfsb_patches_usesAlive gets nil, not false, when the adapter's PBO
// was skipped for want of ALiVE_main.
EGVAR(patches,usesACEAX)        = isClass (configFile >> "CfgPatches" >> "aceax_main");
// Advanced Combat Medicine. jmfsb_acm sets its treatment tiers; jmfsb_evac
// stands down behind it, because ACM brings its own evacuation.
EGVAR(patches,usesACM)          = isClass (configFile >> "CfgPatches" >> "ACM_main");

EGVAR(Staging,ZoneStatus) = false;
GVAR(isPlayer) = hasInterface || {isPlayer player};


#include "initSettings.inc.sqf"

INFO(_phase,"Initialization of CBA Settings completed...");

ADDON = true;

// Everything past here needs a mission. In Eden the settings above are all
// that is wanted - the rest reads mission config and places things.
if (is3DEN) exitWith {};

INFO("preInit","Initializing...");

// THE DATABASES ARE BUILT WHEN THE MISSION HANDS ITS CONFIGS OVER, not here.
// CBA runs addon preInit handlers BEFORE the mission's, so at this moment
// config\loadConfigs.sqf has not run yet and there is nothing to build from.
// FUNC(missionConfigsReady) is called from both ends and does the work once,
// whichever arrives first - see that function.
EGVAR(DATABASE,DONE) = false;
EGVAR(PYLONS,DONE) = false;
EGVAR(gear,Radio) = false;

call FUNC(missionConfigsReady);

call FUNC(chatCommands);
// THE ZEN MODULES USED TO REGISTER HERE. They are in XEH_postInit.sqf now, and
// the file says why - preInit is too early for zen_custom_modules_fnc_register.

call FUNC(eventHandlers);

INFO("preInit","Initialization completed.");
