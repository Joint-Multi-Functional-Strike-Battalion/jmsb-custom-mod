#include "script_component.hpp"
/*
 * Author: JMSB
 * The one-line state of a fires asset: what it is doing and what it has left.
 * The support page offers SITREP for every type, artillery included.
 *
 * Arguments:
 * 0: Asset id, "fires:<n>" <STRING>
 *
 * Return Value:
 * 0: Readable <BOOL>
 * 1: The line <STRING>
 *
 * Example:
 * ["fires:0"] call jmfsb_support_fires_fnc_sitrep
 *
 * Public: No
 */

params [["_assetId", "", [""]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, "that asset is gone"]};

([_logic] call FUNC(available)) params ["", "_status", "_why"];

private _left = ([_logic] call FUNC(ordnance)) apply {
    _x params ["_name", "_rounds"];
    if (_rounds < 0) then {format ["%1 unlimited", _name]} else {format ["%1 %2", _name, _rounds]}
};

private _more = switch (_logic getVariable [QGVAR(type), ""]) do {
    case TYPE_ARTY: {format [" %1 guns.", _logic getVariable [QGVAR(gunCount), 0]]};
    case TYPE_CRUISE: {format [" Salvo up to %1, %2 m/s at %3 m.", _logic getVariable [QGVAR(salvo), 1], _logic getVariable [QGVAR(speed), 0], _logic getVariable [QGVAR(altitude), 0]]};
    case TYPE_LOITER: {format [" Loiter %1 s.", _logic getVariable [QGVAR(loiterTime), 0]]};
    default {""};
};

[true, format [
    "%1 - %2. %3.%4",
    _logic getVariable [QGVAR(callsign), "FIRES"],
    [toUpper _status, _why] select (_why isNotEqualTo ""),
    ["Nothing left", _left joinString ", "] select (_left isNotEqualTo []),
    _more
]]
