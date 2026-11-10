#include "script_component.hpp"
/*
 * Author: YonV
 * Starts the prune that retires a jammer site once its emitter is dead.
 *
 * Called by FUNC(moduleController) - never on its own. The Jamming module is
 * the enable, so a mission with no module never reaches here.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Example:
 * [] call jmfsb_jamming_fnc_start
 */

if (!isServer) exitWith {};

// NOTHING IS PLACED HERE. Sites used to be spread over a commander's ALiVE
// objectives from this function; they are placed by hand now, one JMSB -
// Jammer Site module each, and a module places itself the moment it is armed.
// What is left is the prune.

// A zone dies with its emitter - destroyed OR hacked, either one.
[{
    [] call FUNC(pruneJammers);
    // Published for the device's button gate - a count only, never the
    // positions, which a client has no business reading out of a variable.
    missionNamespace setVariable
        [QGVAR(zoneCount), count (["jam", [], true] call FUNC(getZones)), true];
}, JAM_PRUNE_TICK, []] call CBA_fnc_addPerFrameHandler;
