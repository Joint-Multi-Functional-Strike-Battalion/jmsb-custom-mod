#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: takes one zone out of the registry by id and publishes once. For a
 * caller that laid a zone with FUNC(zoneOnObject) and switches it off before
 * its object dies.
 *
 * Arguments:
 * 0: Zone id <STRING>
 *
 * Return Value:
 * Whether a zone was removed <BOOL>
 *
 * Example:
 * ["jmfsb_jamming_z12"] call jmfsb_jamming_fnc_removeZone
 *
 * Public: Yes
 */

params [["_id", "", [""]]];

if (!isServer || _id isEqualTo "" || {isNil QGVAR(jammers)}) exitWith {false};

private _before = count GVAR(jammers);
GVAR(jammers) = GVAR(jammers) select {(_x param [ZONE_ID, ""]) isNotEqualTo _id};
if (count GVAR(jammers) == _before) exitWith {false};

[] call FUNC(publishZones);
true
