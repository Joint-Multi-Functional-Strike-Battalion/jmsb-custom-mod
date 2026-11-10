#include "script_component.hpp"
/*
 * Author: YonV
 * The one-line state of an air asset for the SITREP button: what it is
 * doing, where its aircraft is, and what it has left - the number the man on
 * the radio is actually deciding on.
 *
 * Arguments:
 * 0: Asset id, "air:<n>" <STRING>
 *
 * Return Value:
 * 0: Answered <BOOL>
 * 1: The line <STRING>
 *
 * Example:
 * ["air:0"] call jmfsb_support_air_fnc_sitrep
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, "that asset is gone"]};

([_logic] call FUNC(available)) params ["", "_status", "_why"];

private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
private _veh = _logic getVariable [QGVAR(vehicle), objNull];

private _where = if (alive _veh) then {
    format ["at %1, %2 m, fuel %3", mapGridPosition _veh, round ((getPosATL _veh) select 2), (str round (fuel _veh * 100)) + "%"]
} else {
    "at base"
};

// THE RESPAWN COUNT (user, 2026-11-02: "make sure there is a respawn count for
// each support, default no respawns"): the spare airframes left.
[true, format [
    "%1 - %2, %3. %4 spare airframes.",
    _callsign,
    [toUpper _status, _why] select (_why isNotEqualTo ""),
    _where,
    _logic getVariable [QGVAR(respawnsLeft), 0]
]]
