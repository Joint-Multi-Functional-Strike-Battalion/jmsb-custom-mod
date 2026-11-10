#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the delivery's lead aircraft on its way in, from its watch
 * (FUNC(dropTick), FUNC(slingTick)) every tick of the leg in (user,
 * 2026-11-01: "need more information like after rw inbound eta etc etc and an
 * alert to pop smoke when its close"): the support core's INBOUND - ETA every
 * minute and 1 MIN OUT - POP SMOKE, FLASH, with the issuer's popup
 * (EFUNC(support,inbound)), in the thread a message tasked it with. The other
 * helicopters of a sling order say nothing - one voice per delivery.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: The point it flies to <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh, _pos] call jmfsb_support_logistics_fnc_inbound
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_pos", [], [[]]]];

if (!isServer || {isNull _logic}) exitWith {};
if (_veh isNotEqualTo (_logic getVariable [QGVAR(vehicle), objNull])) exitWith {};
private _job = _logic getVariable [QGVAR(threadJob), createHashMap];
if ((_job getOrDefault ["step", ""]) isNotEqualTo JOB_FLYING) exitWith {};

[
    format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]],
    _job getOrDefault ["thread", ""],
    _logic getVariable [QGVAR(callsign), DEF_CALLSIGN],
    _veh,
    _pos
] call EFUNC(support,inbound);
