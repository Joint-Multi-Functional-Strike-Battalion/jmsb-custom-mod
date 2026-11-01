#include "script_component.hpp"
/*
 * Author: JMSB
 * One man put aboard the jump aircraft, on the machine he is local to: in a
 * cargo seat, or standing in the bay fixed to the hull (setting "stand": two
 * files either side of the centreline, by his place in the stick). JUMP goes
 * in his action menu, open from the red light on (QGVAR(mayJump), set by
 * FUNC(light)), whichever exit the leader picked.
 *
 * Sent by the server (FUNC(srvLaunch)) by remoteExec and taken only from the
 * server (review S7: it was the `board` CBA event, which any client could
 * raise to put anyone into any vehicle).
 *
 * Arguments:
 * 0: The man <OBJECT>
 * 1: The aircraft <OBJECT>
 * 2: Bay - BAY_SEATS or BAY_STAND <STRING>
 * 3: His place in the stick <NUMBER>
 * 4: Jump type <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, _veh, "seats", 0, "HALO"] remoteExecCall ["jmfsb_jumpmaster_fnc_board", _unit]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_veh", objNull, [objNull]], ["_bay", BAY_SEATS, [""]], ["_slot", 0, [0]], ["_type", TYPE_HALO, [""]]];

if !([] call EFUNC(common,fromServer)) exitWith {
    WARNING_1("board: refused - not from the server (machine %1)",remoteExecutedOwner);
};
if (!alive _unit || {isNull _veh} || {!local _unit}) exitWith {};

_unit setVariable [QGVAR(mayJump), false];
if (vehicle _unit isNotEqualTo _unit) then {
    unassignVehicle _unit;
    moveOut _unit;
};

if (_bay isEqualTo BAY_STAND) then {
    (boundingBoxReal _veh) params ["_lo", "_hi"];
    private _len = (_hi select 1) - (_lo select 1);
    private _rows = (floor ((STAND_TO - STAND_FROM) * _len / STAND_SPACING)) max 1;
    private _x = [-STAND_FILE_X, STAND_FILE_X] select (_slot mod 2);
    private _y = STAND_FROM * _len + ((floor (_slot / 2)) mod _rows) * STAND_SPACING;
    _unit attachTo [_veh, [_x, _y, (_lo select 2) + STAND_FLOOR]];
    _unit setDir 0;
} else {
    _unit moveInCargo _veh;
    if (vehicle _unit isNotEqualTo _veh) then {_unit moveInAny _veh};
};

private _id = _unit getVariable [QGVAR(action), -1];
if (_id >= 0) then {_unit removeAction _id};
_id = _unit addAction [
    "<t color='#FF4040'>JUMP</t>",
    {
        params ["_target", "", "", "_args"];
        [_target, _args select 0, _args select 1] call FUNC(jump);
    },
    [_veh, _type],
    ACTION_PRIORITY, true, true, "",
    format ["_target getVariable ['%1', false] && {(vehicle _target) getVariable ['%2', false] || {(attachedTo _target) getVariable ['%2', false]}}", QGVAR(mayJump), QGVAR(jumpAircraft)]
];
_unit setVariable [QGVAR(action), _id];
