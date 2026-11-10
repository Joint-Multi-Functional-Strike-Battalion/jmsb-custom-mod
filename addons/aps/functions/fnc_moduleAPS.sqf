#include "script_component.hpp"
/*
 * Author: YonV
 * Reads the module and arms active protection. PLACING THE MODULE IS THE
 * ENABLE - with no module this system does nothing at all.
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

// THE MODULE IS NOT THE ENABLE - see FUNC(arm). APS arms itself from its CBA
// settings at postInit; this module exists to override the switches and to
// carry a mission's own tier and fit tables. Placing one is optional, and it
// is applied whether it runs before or after the settings armed the system -
// a module that arrives second refits every vehicle to its tables.
if !([_logic] call FUNC(arm)) then {
    INFO("JMSB - APS module placed, but APS is switched off in settings - nothing to apply it to");
};
