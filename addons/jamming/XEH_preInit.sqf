#include "script_component.hpp"

ADDON = false;

#include "XEH_PREP.hpp"

#include "initSettings.inc.sqf"

// The zone registry: one flat public array, entries in the ZONE_* layout the
// model reads. Zones only ever enter through spawnZoneAt or spawnTempZone.
if (isServer) then {
    missionNamespace setVariable [QGVAR(jammers), [], true];
};

// ARMED FLAG, DECLARED AT PREINIT. Module functions run BETWEEN preInit and
// postInit, so declaring this in postInit was wrong twice over: the module
// read it before it existed, and postInit then set it back to false AFTER the
// module had armed the system.
GVAR(moduleUp) = false;

// THE JAM-MODEL KNOBS, at the values FUNC(jamFactor) falls back to - the
// jammerLoop comment always promised "the model attributes at their defaults
// are the old inline maths exactly", but the definitions were never written
// anywhere: not settings, not module attributes. Every read was an undefined
// variable that killed the client loop and the server's zone spawner - the
// whole addon was dead. Declared here, on every machine, because zoneModel
// runs on the server and jammerLoop/jamHud on clients.
GVAR(jamLos) = false;
GVAR(jamBurnthrough) = false;
GVAR(jamBurnRef) = 500;
GVAR(jamCurve) = "LINEAR";
GVAR(jamDuty) = 100;
GVAR(jamConeEnable) = false;
GVAR(jamUavs) = false;
GVAR(detectorRange) = 1000;
// THE FIELD METER IS OFF BY DEFAULT. The JAM live tile and the tacpad JAM app
// already say how jammed the sky is; the bottom-screen DEGRADED/SMOTHERED bar
// was a third copy that sat over the map. Left as a variable a mission or a
// script can flip back on, not a permanent fixture.
GVAR(jamHudEnabled) = false;

// The zones' noise at the core in the RF link budget (FUNC(rfNoise)), until
// the module says otherwise; and the per-frame memo that keeps the hook cheap.
GVAR(rfNoiseDbm) = JAM_RF_CORE_DBM;
GVAR(rfNoiseFrame) = -1;
GVAR(rfNoiseMemo) = createHashMap;

// The uplink's own field. Small on purpose: it is the last hundred metres
// of the assault on it, not a second sphere.
GVAR(gpsUplinkRadius) = 400;

// Off until the module says otherwise, like every other operation value:
// FUNC(spawnObjectiveJammers) reads it on the server before the module has
// necessarily run, and an undefined read there killed the whole spawner once
// already - see the jam-model knobs above.
GVAR(gpsEnable) = false;
GVAR(siteObjectives) = false;

ADDON = true;
