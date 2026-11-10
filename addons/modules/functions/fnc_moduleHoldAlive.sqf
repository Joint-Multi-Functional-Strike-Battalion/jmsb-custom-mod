#include "script_component.hpp"
/*
 * Author: YonV
 * JMSB - Hold ALiVE module: holds ALiVE for a training mission until an admin
 * types #jmfsbalivestart. The work is the ALiVE adapter's (its fnc_hold) -
 * without ALiVE that addon is not loaded and there is nothing to hold.
 *
 * Arguments:
 * 0: Module logic <OBJECT>
 * 1: Synced units <ARRAY>
 * 2: Activated <BOOL>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_units", [], [[]]], ["_activated", true, [true]]];

if (!isServer || {!_activated}) exitWith {};

if (isNil QEFUNC(adapter_alive,hold)) exitWith {
    INFO("Hold ALiVE module: ALiVE not loaded - nothing to hold");
};

[true] call EFUNC(adapter_alive,hold);
