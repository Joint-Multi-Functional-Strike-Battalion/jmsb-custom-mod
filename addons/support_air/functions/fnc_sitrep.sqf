#include "script_component.hpp"
/*
 * Author: JMSB
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
private _kind = _logic getVariable [QGVAR(kind), ""];
private _veh = _logic getVariable [QGVAR(vehicle), objNull];

private _where = if (alive _veh) then {
    format ["at %1, %2 m, fuel %3", mapGridPosition _veh, round ((getPosATL _veh) select 2), (str round (fuel _veh * 100)) + "%"]
} else {
    "at base"
};

private _left = _logic getVariable [QGVAR(left), -1];
private _stock = _logic getVariable [QGVAR(stock), 0];
private _noun = switch (_kind) do {
    case KIND_CAS: {"sorties"};
    case KIND_LOGISTICS: {"drops"};
    case KIND_QRF: {"squads"};
    default {"airframes"};
};
private _count = switch (true) do {
    case (_kind isEqualTo KIND_TRANSPORT): {
        private _max = _logic getVariable [QGVAR(airframes), 0];
        if (_max <= 0) then {"unlimited"} else {format ["%1 of %2", _max - (_logic getVariable [QGVAR(lost), 0]), _max]}
    };
    case (_left < 0): {"unlimited"};
    default {format ["%1 of %2", _left, _stock]};
};

[true, format [
    "%1 - %2, %3. %4 %5.",
    _callsign,
    [toUpper _status, _why] select (_why isNotEqualTo ""),
    _where,
    _count,
    _noun
]]
