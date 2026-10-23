#include "script_component.hpp"
/*
 * Author: JMSB
 * Reads the module and arms jamming. PLACING THE MODULE IS THE ENABLE - with no
 * module this system does nothing at all.
 *
 * THIS MODULE IS THE GLOBAL TUNING. It sets what is true of every jamming field
 * on the map - burn-through, the rolled radius bounds, the GPS domain.
 *
 * WHERE a jammer stands has TWO answers here, and they add up rather than
 * replace each other. A JMSB - Jammer Site module is one emitter placed on the
 * spot by a mission maker or a Zeus, and it works whether or not ALiVE is
 * running. On top of that, when the adapter is loaded and its commanders are
 * up, FUNC(spawnObjectiveJammers) spreads emitters over a share of each
 * commander's objectives - the three attributes below are that half's tuning
 * and do nothing without ALiVE.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Synchronised units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!_activated || {isNull _logic}) exitWith {};
if (!isServer) exitWith {};

// One module runs this system. A second would re-arm it and place everything
// twice over, so it says so in the log rather than quietly doing it.
if (GVAR(moduleUp)) exitWith {
    WARNING("a second JMSB - Jamming module was placed - ignored, one module runs this system");
};
GVAR(moduleUp) = true;

GVAR(largeRadius) = _logic getVariable ["largeRadius", 3000];
GVAR(smallRadius) = _logic getVariable ["smallRadius", 1000];
// ALiVE-only tuning: what share of a commander's objectives get an emitter, and
// the ceiling per side. Read unconditionally so the values exist for
// FUNC(spawnObjectiveJammers) to find; without ALiVE nothing reads them.
GVAR(objectiveShare) = _logic getVariable ["objectiveShare", 30];
GVAR(maxPerSide) = _logic getVariable ["maxPerSide", 8];

// EDEN CHECKBOXES ARRIVE AS 0 AND 1, NOT false AND true. Read straight into a
// GVAR and handed to `&&`, that is "Error &&: Type Number, expected Bool" -
// which is exactly what the 14:48 RPT showed 51 times from FUNC(jammerLoop)
// line 29 and once a tick from FUNC(spawnObjectiveJammers) line 105, with the
// GPS spawner dying on the spot every pass. Coerced here, once, so nothing
// downstream has to know an attribute from a variable.
private _bool = {
    params ["_v"];
    if (_v isEqualType 0) then { _v > 0 } else { _v isEqualTo true }
};

// The GPS domain. Default ON, unlike the model knobs in preInit: placing this
// module is already the deliberate act, and a jamming module that denies the
// net and the data link but silently leaves GPS alone would be the surprising
// answer, not the safe one.
GVAR(gpsEnable) = [_logic getVariable ["gpsEnable", true]] call _bool;
GVAR(gpsUplinkRadius) = _logic getVariable ["gpsUplinkRadius", 400];
GVAR(siteObjectives) = [_logic getVariable ["siteObjectives", false]] call _bool;

// Burn-through. These overwrite the preInit defaults, which are the values
// FUNC(jamFactor) falls back to on a machine the module has not reached.
//
// BROADCAST, because this file exits on !isServer and FUNC(jammerLoop) reads
// jamBurnthrough on every CLIENT to decide whether to ask ACRE for the set's
// power. Server-local, a dedicated server's players would never burn through
// anything however big their radio - the same trap jmfsb_reaction documents on
// its watts threshold. burnRef needs no broadcast: it is stamped into each
// zone's model at spawn and travels with the registry.
GVAR(jamBurnRef) = _logic getVariable ["burnRef", 500];

// The zones' noise in the RF link budget. Server only: FUNC(rfNoise) runs
// inside RF's server tick and nowhere else.
GVAR(rfNoiseDbm) = _logic getVariable ["rfNoise", JAM_RF_CORE_DBM];
missionNamespace setVariable [
    QGVAR(jamBurnthrough), [_logic getVariable ["burnThrough", true]] call _bool, true];

// THE PRUNE STARTS AT ONCE, and does not wait for anything. Hand-placed Jammer
// Site modules arm themselves the moment they are placed, so the retire-a-dead-
// emitter pass has to be running whether or not ALiVE ever turns up. jmfsb held
// this behind the adapter's ready event, which here would mean a mission with no
// ALiVE never pruning anything.
[] call FUNC(start);

// THE ALiVE HALF, IF THERE IS ONE. Objective emitters need commanders and their
// objectives, so they wait for the adapter. Both paths are covered: a module is
// normally placed long before ALiVE finishes initialising, but one armed
// afterwards would otherwise wait forever on an event that has already fired.
if (!isNil QEFUNC(adapter_alive,objectivesFor)) then {
    if (EGVAR(adapter_alive,ready)) then {
        private _n = [] call FUNC(spawnObjectiveJammers);
        INFO_1("%1 objective jammer site(s) queued",_n);
    } else {
        [QEGVAR(adapter_alive,ready), {
            private _n = [] call FUNC(spawnObjectiveJammers);
            INFO_1("%1 objective jammer site(s) queued",_n);
        }] call CBA_fnc_addEventHandler;
    };
};
