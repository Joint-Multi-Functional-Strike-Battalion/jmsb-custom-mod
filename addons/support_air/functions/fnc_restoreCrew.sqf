#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts a synced aircraft's crew back as the mission maker placed it: every
 * crew seat that was manned in Eden and is empty or dead now gets a man of
 * the same class with the same loadout (FUNC(register) photographed them).
 * Simplex does the same on a respawn and after an RTB.
 *
 * A seat a player sits in is his, and an aircraft with no photograph (it
 * stood empty in Eden) is left alone - FUNC(prepareAircraft) crews it with
 * the class's own crew at launch, as it always has.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: The aircraft <OBJECT>
 *
 * Return Value:
 * Men put back <NUMBER>
 *
 * Example:
 * [_logic, _veh] call jmfsb_support_air_fnc_restoreCrew
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_veh", objNull, [objNull]]];

if (isNull _logic || {!alive _veh} || {!isServer}) exitWith {0};

private _crew = _logic getVariable [QGVAR(crew), []];
if (_crew isEqualTo []) exitWith {0};

// The dead are taken out first, or the seat reads taken.
{
    if (!alive _x) then {_veh deleteVehicleCrew _x};
} forEach (crew _veh);

private _grp = group effectiveCommander _veh;
if (isNull _grp || {(units _grp) findIf {isPlayer _x} > -1}) then {
    _grp = createGroup [_logic getVariable [QGVAR(side), west], true];
};

private _put = 0;
{
    _x params ["_cls", "_role", "_turret", "_loadout"];
    private _taken = switch (_role) do {
        case "driver": {!isNull driver _veh};
        case "commander": {!isNull commander _veh};
        case "gunner": {!isNull gunner _veh};
        default {!isNull (_veh turretUnit _turret)};
    };
    if (!_taken) then {
        private _unit = _grp createUnit [_cls, getPosATL _veh, [], 0, "CAN_COLLIDE"];
        _unit setUnitLoadout _loadout;
        switch (_role) do {
            case "driver": {_unit moveInDriver _veh};
            case "commander": {_unit moveInCommander _veh};
            case "gunner": {_unit moveInGunner _veh};
            default {_unit moveInTurret [_veh, _turret]};
        };
        if (vehicle _unit isEqualTo _veh) then {
            _put = _put + 1;
        } else {
            deleteVehicle _unit;
        };
    };
} forEach _crew;

if (_put > 0) then {
    _grp allowFleeing 0;
    INFO_3("%1: %2 crew put back in '%3'",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_put,typeOf _veh);
};

_put
