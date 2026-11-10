#include "script_component.hpp"
/*
 * Author: YonV
 * The one-line state of a logistics asset for the SITREP button: what it is
 * doing, where its lead aircraft is, how many replacements it has left for
 * aircraft lost (user, 2026-11-02) and how much it can bring.
 *
 * Arguments:
 * 0: Asset id, "logi:<n>" <STRING>
 *
 * Return Value:
 * 0: Answered <BOOL>
 * 1: The line <STRING>
 *
 * Example:
 * ["logi:0"] call jmfsb_support_logistics_fnc_sitrep
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, "that asset is gone"]};

([_logic] call FUNC(available)) params ["", "_status", "_why"];

private _veh = _logic getVariable [QGVAR(vehicle), objNull];
private _where = if (alive _veh) then {
    format ["at %1, %2 m", mapGridPosition _veh, round ((getPosATL _veh) select 2)]
} else {
    "nothing out"
};

private _left = _logic getVariable [QGVAR(left), -1];
private _count = if (_left < 0) then {"unlimited"} else {format ["%1 of %2", _left, _logic getVariable [QGVAR(stock), 0]]};

[true, format [
    "%1 - %2, %3. %4 spare airframes, %5 per order, %6 items in the catalog.",
    _logic getVariable [QGVAR(callsign), DEF_CALLSIGN],
    [toUpper _status, _why] select (_why isNotEqualTo ""),
    _where,
    _count,
    _logic getVariable [QGVAR(capacity), DEF_CAPACITY],
    count (_logic getVariable [QGVAR(catalog), []])
]]
