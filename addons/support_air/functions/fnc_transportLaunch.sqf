#include "script_component.hpp"
/*
 * Author: JMSB
 * Gets a transport helicopter out - the synced one, or the class over the
 * module - and starts its watch, which flies whatever the current order is.
 *
 * SEATS: a module that offers fewer seats than the helicopter has locks the
 * rest, so the PASSENGERS list on TAC//SUPPORT and the seats a man can take
 * agree.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Who asked <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, player] call jmfsb_support_air_fnc_transportLaunch
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_requester", objNull, [objNull]]];

if (isNull _logic) exitWith {};

if (_logic getVariable [QGVAR(abort), false]) exitWith {
    _logic setVariable [QGVAR(abort), false, true];
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    _logic setVariable [QGVAR(plan), [], true];
    [_logic, "stood down", "normal", _requester] call FUNC(say);
};

private _order = _logic getVariable [QGVAR(order), []];
private _synced = _logic getVariable [QGVAR(synced), objNull];
private _veh = if (alive _synced) then {_synced} else {
    [_logic, _order param [1, []], _order param [3, HOME_HEIGHT]] call FUNC(spawnAircraft)
};
if (!alive _veh) exitWith {
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    _logic setVariable [QGVAR(plan), [], true];
    [_logic, "could not launch", "high", _requester, false] call FUNC(say);
};
if (isNull ([_logic, _veh] call FUNC(prepareAircraft))) exitWith {
    if (!alive _synced) then {[_veh] call FUNC(sweep)};
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    _logic setVariable [QGVAR(plan), [], true];
    [_logic, "has no crew", "high", _requester, false] call FUNC(say);
};

private _seats = _logic getVariable [QGVAR(seats), 0];
if (_seats > 0) then {
    {
        _x params ["", "", "_cargoIndex"];
        if (_cargoIndex >= _seats) then {_veh lockCargo [_cargoIndex, true]};
    } forEach (fullCrew [_veh, "cargo", true]);
};

// ACE's rope item, for a transport that may fast-rope (FUNC(stockRopes)).
[_logic, _veh] call FUNC(stockRopes);

_logic setVariable [QGVAR(vehicle), _veh, true];
_logic setVariable [QGVAR(ticking), true];

// Serial -1: the watch plans the current order on its first tick.
[FUNC(transportTick), AIR_TICK, [_logic, _veh, createHashMapFromArray [["serial", -1], ["phase", ""]]]] call CBA_fnc_addPerFrameHandler;
