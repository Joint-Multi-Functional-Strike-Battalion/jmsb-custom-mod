#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts a QRF aircraft in the air over the module with the squad in the back
 * and starts its watch (FUNC(qrfTick)).
 *
 * THE FLIGHT FOLLOWS THE INSERTION:
 *
 *   STATIC   low and slow at the static-line height, over the grid
 *   ASSAULT  helicopter at ASSAULT_CRUISE, for the grid
 *
 * THE SQUAD IS THE PLAYERS' SIDE (D59) and is made in the cargo seats; a
 * soldier the aircraft has no seat for is not made, and the RPT says how
 * many were left behind.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: "STATIC" or "ASSAULT" <STRING>
 * 2: Target position ATL <ARRAY>
 * 3: Who asked <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "STATIC", _pos, player] call jmfsb_support_air_fnc_qrfLaunch
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_task", TASK_STATIC, [""]],
    ["_pos", [], [[]]],
    ["_requester", objNull, [objNull]]
];

if (isNull _logic) exitWith {};

private _fnc_standDown = {
    params ["_why"];
    private _left = _logic getVariable [QGVAR(left), -1];
    if (_left >= 0) then {_logic setVariable [QGVAR(left), _left + 1, true]};
    _logic setVariable [QGVAR(abort), false, true];
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    _logic setVariable [QGVAR(plan), [], true];
    [_logic, _why, "normal", _requester] call FUNC(say);
};

if (_logic getVariable [QGVAR(abort), false]) exitWith {["stood down"] call _fnc_standDown};

private _alt = [_logic getVariable [QGVAR(staticAlt), 250], ASSAULT_CRUISE] select (_task isEqualTo TASK_ASSAULT);

private _veh = [_logic, +_pos, _alt] call FUNC(spawnAircraft);
if (!alive _veh) exitWith {["could not launch"] call _fnc_standDown};

private _crew = group driver _veh;
_crew setBehaviour "CARELESS";
_crew setCombatMode "BLUE";

private _grp = createGroup [_logic getVariable [QGVAR(side), west], true];
private _wanted = [_logic] call FUNC(qrfSquad);
{
    private _unit = _grp createUnit [_x, [0, 0, 0], [], 0, "CAN_COLLIDE"];
    _unit moveInCargo _veh;
    if (vehicle _unit isNotEqualTo _veh) then {
        deleteVehicle _unit;
    } else {
        _unit assignAsCargo _veh;
    };
} forEach _wanted;

private _aboard = units _grp;
if (_aboard isEqualTo []) exitWith {
    [_veh] call FUNC(sweep);
    deleteGroup _grp;
    ["has no seats for the squad"] call _fnc_standDown;
};
if (count _aboard < count _wanted) then {
    WARNING_3("%1: '%2' seats %3 of the squad - the rest stay behind",_logic getVariable [ARR_2(QGVAR(callsign),"QRF")],typeOf _veh,count _aboard);
};

_grp allowFleeing 0;
_grp setBehaviour "CARELESS";
if (!isNil QEFUNC(adapter_alive,profileIgnore)) then {
    [_grp] call EFUNC(adapter_alive,profileIgnore);
};

[_veh, _pos, ["NORMAL", "LIMITED"] select (_task isEqualTo TASK_STATIC)] call FUNC(moveTo);

_logic setVariable [QGVAR(vehicle), _veh, true];
_logic setVariable [QGVAR(status), "inbound", true];
_logic setVariable [QGVAR(ticking), true];
[_logic, format ["airborne with %1 aboard, inbound %2", count _aboard, mapGridPosition _pos], "normal", _requester] call FUNC(say);

private _st = createHashMapFromArray [
    ["phase", "in"],
    ["task", _task],
    ["pos", _pos],
    ["group", _grp],
    ["jumpers", +_aboard],
    ["requester", _requester],
    ["until", CBA_missionTime + SORTIE_TIMEOUT]
];
[FUNC(qrfTick), JUMP_INTERVAL, [_logic, _veh, _st]] call CBA_fnc_addPerFrameHandler;
