#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

#include "initSettings.inc.sqf"

// ARMED FLAG, DECLARED AT PREINIT. Module functions run BETWEEN preInit and
// postInit, so declaring this in postInit was wrong twice over: the module
// read it before it existed, and postInit then set it back to false AFTER the
// module had armed the system.
GVAR(moduleUp) = false;

// The zones somebody has drawn. Declared here for the same reason moduleUp is:
// a module function runs before postInit, and pushBack onto nil is not a zone.
GVAR(zones) = [];

// When each zone last called artillery, keyed by its index in GVAR(zones).
GVAR(artyLast) = createHashMap;

// FPV WRECKS GO AS SOON AS THEY BLOW, on every machine - see FUNC(fpvWatch).
// The Switchblade airframes by their base class, whoever flies them: the mod's
// own Killed cleanup is clientInit, so on a dedicated server nobody else takes
// a Switchblade's wreck away - and Drongo's Drone Tweaks keeps the 600 on its
// anti-armour list, not the FPV one, so both lists are read.
GVAR(fpvWatched) = [];
[QGVAR(UAV_06_IED_I)] call FUNC(fpvWatch);
["SwitchBlade_Base"] call FUNC(fpvWatch);
[{missionNamespace getVariable ["ddtReady", false]}, {
    {[_x] call FUNC(fpvWatch)} forEach (
        (missionNamespace getVariable ["ddtClassesFPV", []])
        + (missionNamespace getVariable ["ddtClassesFPVAT", []])
    );
}, [], UAS_DDT_WAIT_S] call CBA_fnc_waitUntilAndExecute;

#include "initSettings.inc.sqf"

ADDON = true;
