#include "script_component.hpp"
/*
 * Author: YonV
 * What this asset is doing, as one token, and whether it can take an order -
 * the ONE answer the row, the "available" code, the reach card and the order
 * all read, so a row that reads idle is never refused.
 *
 * A module with an empty catalog stays on the page and says EXPENDED. One
 * whose last airframe is gone - an aircraft lost with no Respawns left (user,
 * 2026-11-02: "a respawn count for each support, default no respawns"; a
 * delivery that goes home uses none) - is GONE: it leaves the SUPPORT list
 * (FUNC(entityRow)) and says UNABLE - NO AIRFRAME. After a loss with one left
 * it is REPLACING until the Respawn Delay is up.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * 0: Can be tasked now <BOOL>
 * 1: Status token <STRING>
 * 2: Why not, "" when it can <STRING>
 *
 * Example:
 * [_logic] call jmfsb_support_logistics_fnc_available
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {[false, "gone", "that asset is gone"]};

private _callsign = _logic getVariable [QGVAR(callsign), DEF_CALLSIGN];
private _status = _logic getVariable [QGVAR(status), STATUS_IDLE];

// NO AIRFRAME LEFT (user, 2026-11-02: "a respawn count for each support,
// default no respawns"): its respawns used, the asset is gone (FUNC(finish)).
if (_logic getVariable [QGVAR(gone), false]) exitWith {[false, STATUS_GONE, WHY_NO_AIRFRAME]};
if ((_logic getVariable [QGVAR(catalog), []]) isEqualTo []) exitWith {[false, STATUS_EXPENDED, format ["%1 has nothing to deliver", _callsign]]};

if (_status isEqualTo STATUS_LAUNCHING) exitWith {[false, _status, format ["%1 is launching", _callsign]]};
if (_status isNotEqualTo STATUS_IDLE) exitWith {[false, _status, format ["%1 is already on a delivery", _callsign]]};

private _respawnAt = _logic getVariable [QGVAR(respawnAt), 0];
if (CBA_missionTime < _respawnAt) exitWith {
    [false, STATUS_REPLACING, format ["%1 has a replacement aircraft in %2s", _callsign, ceil (_respawnAt - CBA_missionTime)]]
};

private _readyAt = _logic getVariable [QGVAR(readyAt), 0];
if (CBA_missionTime < _readyAt) exitWith {
    [false, STATUS_COOLDOWN, format ["%1 is turning round - %2s", _callsign, ceil (_readyAt - CBA_missionTime)]]
};

[true, STATUS_IDLE, ""]
