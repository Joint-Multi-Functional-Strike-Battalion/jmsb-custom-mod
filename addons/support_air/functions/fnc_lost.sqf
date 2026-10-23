#include "script_component.hpp"
/*
 * Author: JMSB
 * One aircraft down. Counts it against the module and tells the side; the
 * sortie's own watch sees the wreck and ends the sortie (FUNC(finish)).
 *
 * WHAT A LOSS COSTS depends on what the module counts: a transport counts
 * airframes, and CAS, drops and QRF have already spent the sortie when it
 * launched. Then the module's Respawn Delay decides: -1 and the asset is
 * gone for good; otherwise it reads REPLACING until the delay is up - and a
 * synced aircraft is rebuilt on its stand then (FUNC(respawn)), the way a
 * Simplex support replaces its vehicle.
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
 * [_logic, _veh, _killer] call jmfsb_support_air_fnc_lost
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_killer", objNull, [objNull]]];

if (isNull _logic) exitWith {};

private _lost = (_logic getVariable [QGVAR(lost), 0]) + 1;
_logic setVariable [QGVAR(lost), _lost, true];

WARNING_3("%1 lost '%2' to '%3'",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],typeOf _veh,typeOf _killer);

// The MPKilled handlers run this on the server only, wherever the aircraft
// was local - a synced aircraft a player took the stick of still counts and
// is still announced.
if (!isServer) exitWith {};

private _delay = _logic getVariable [QGVAR(respawnDelay), RESPAWN_NEVER];
private _airframes = _logic getVariable [QGVAR(airframes), 0];
private _capped = _airframes > 0 && _lost >= _airframes;

if (_delay < 0 || _capped) exitWith {
    _logic setVariable [QGVAR(dead), true, true];
    [_logic, format ["is down at %1 - no replacement", mapGridPosition _veh], "high"] call FUNC(say);
};

_logic setVariable [QGVAR(respawnAt), CBA_missionTime + _delay, true];
[_logic, format ["is down at %1 - replacement in %2 sec", mapGridPosition _veh, round _delay], "high"] call FUNC(say);

if (_veh isEqualTo (_logic getVariable [QGVAR(synced), objNull])) then {
    [FUNC(respawn), [_logic, _veh], _delay] call CBA_fnc_waitAndExecute;
};
