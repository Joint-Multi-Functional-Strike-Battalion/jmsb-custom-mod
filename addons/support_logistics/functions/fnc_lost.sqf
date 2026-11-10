#include "script_component.hpp"
/*
 * Author: YonV
 * One delivery aircraft down - shot down (MPKilled), or on the ground and
 * unable to move (its watch, 2026-11-05). Counts it once and tells the side;
 * its watch sees the wreck, accounts its load as not delivered and ends its
 * part of the delivery (FUNC(dropTick), FUNC(slingTick)). The delivery
 * itself was spent when it launched.
 *
 * Then the module's Respawns decide (user, 2026-11-02: "a respawn count for
 * each support, default no respawns"; the same day, virtual until tasked:
 * only a LOSS uses one, a delivery that goes home is despawned for nothing).
 * A respawn left: one is used and the asset reads REPLACING until the Respawn
 * Delay is up - the next delivery is made then. None left: the asset is gone
 * when the delivery ends (FUNC(finish)) - off the SUPPORT list, UNABLE - NO
 * AIRFRAME. Every aircraft lost counts, each helicopter of a sling delivery.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: What killed it <OBJECT> (optional, default objNull)
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _veh, _killer] call jmfsb_support_logistics_fnc_lost
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_killer", objNull, [objNull]]];

if (isNull _logic || {!isServer}) exitWith {};
// ONCE PER AIRFRAME (2026-11-05): one down on the ground and unable to move
// is counted by its watch (Simplex's commission watch counts a crash-landing
// as killed), and the wreck may still be destroyed after that.
if (_veh getVariable [QGVAR(counted), false]) exitWith {};
_veh setVariable [QGVAR(counted), true];

_logic setVariable [QGVAR(lost), (_logic getVariable [QGVAR(lost), 0]) + 1, true];
WARNING_3("%1 lost '%2' to '%3'",_logic getVariable [ARR_2(QGVAR(callsign),DEF_CALLSIGN)],typeOf _veh,typeOf _killer);

// NO RESPAWN LEFT (user, 2026-11-02): this was its last airframe;
// FUNC(finish) takes the asset off the list when the delivery ends.
private _left = _logic getVariable [QGVAR(left), RESPAWNS_UNLIMITED];
if (_left isEqualTo 0) exitWith {
    _logic setVariable [QGVAR(noAirframe), true];
    [_logic, format ["is down at %1 - no replacement", mapGridPosition _veh], "high"] call FUNC(say);
};

if (_left > 0) then {_logic setVariable [QGVAR(left), _left - 1, true]};
private _delay = _logic getVariable [QGVAR(respawnDelay), DEF_RESPAWN];
_logic setVariable [QGVAR(respawnAt), CBA_missionTime + _delay, true];
[_logic, format ["is down at %1 - replacement in %2 sec", mapGridPosition _veh, round _delay], "high"] call FUNC(say);
