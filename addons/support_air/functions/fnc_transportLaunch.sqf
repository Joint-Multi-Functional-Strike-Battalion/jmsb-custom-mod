#include "script_component.hpp"
/*
 * Author: YonV
 * Gets a transport helicopter out - the synced one from its stand, or the
 * class made when it is tasked (user, 2026-11-02: "all support aircraft needs
 * to be virtual till tasked, then they spawn in at alt over the support module
 * location"): in the air over the module, nap of the earth, engines on
 * (FUNC(spawnAircraft)) - and starts its watch, which flies whatever the
 * current order is. After the task it flies the card's egress, RTBs to the
 * module, lands, unloads and is removed (user, 2026-11-02: "rtb via egress"),
 * virtual again - ready for the next card, full of fuel. Going home costs no
 * respawn; only a lost airframe does (FUNC(lost)).
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
    [_logic, "DECLINED", "stood down"] call FUNC(threadState);
    _logic setVariable [QGVAR(sortieThread), nil];
    _logic setVariable [QGVAR(liftJob), nil];
};

private _order = _logic getVariable [QGVAR(order), []];
private _synced = _logic getVariable [QGVAR(synced), objNull];
// Made nap of the earth - a SLINGLOAD too: its hook is empty until the load
// point, where it climbs by the rope and the load (FUNC(transportStep)).
private _veh = if (alive _synced) then {_synced} else {
    [_logic, _order param [1, []], [_logic getVariable [QGVAR(cls), ""], FLY_TRANSIT] call EFUNC(support,flightHeight)] call FUNC(spawnAircraft)
};
if (!alive _veh) exitWith {
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    _logic setVariable [QGVAR(plan), [], true];
    [_logic, "could not launch", "high", _requester, false] call FUNC(say);
    [_logic, "DECLINED", "could not launch"] call FUNC(threadState);
    _logic setVariable [QGVAR(sortieThread), nil];
    _logic setVariable [QGVAR(liftJob), nil];
};
if (isNull ([_logic, _veh] call FUNC(prepareAircraft))) exitWith {
    if (!alive _synced) then {[_veh] call FUNC(sweep)};
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    _logic setVariable [QGVAR(plan), [], true];
    [_logic, "has no crew", "high", _requester, false] call FUNC(say);
    [_logic, "DECLINED", "has no crew"] call FUNC(threadState);
    _logic setVariable [QGVAR(sortieThread), nil];
    _logic setVariable [QGVAR(liftJob), nil];
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

// DRONE ESCORTS (user, 2026-11-02: "based on lz security for helos"): two
// rotary drones only when the request's LZ security is YELLOW or RED, made
// beside it. Decided once, at the launch; later orders keep them.
[_logic, _veh, _order param [1, []], format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], _logic getVariable [QGVAR(side), west]] call FUNC(escortLaunch);

_logic setVariable [QGVAR(vehicle), _veh, true];
_logic setVariable [QGVAR(ticking), true];

// WHEELS UP and ON TASK in the asset's thread, if one was filed to it
// (2026-11-01; WHEELS UP for a lift tasked by message, step 7) - WHEELS UP
// "INBOUND - ETA m:ss" to the first point (user, 2026-11-01: "need more
// information like after rw inbound eta").
private _eta = [[_veh, _order param [1, []]] call EFUNC(support,etaTo)] call EFUNC(support,etaText);
[_logic, CARD_WHEELS_UP, [mapGridPosition _veh, format [WHEELS_UP_INBOUND, _eta]] select (_eta isNotEqualTo "")] call FUNC(threadCard);
[_logic, "IN_PROGRESS"] call FUNC(threadState);

// THE FIRST LEG AT ONCE (2026-11-05, the user's RPT 16:23: RAVEN hovered over
// its module and never left for the pickup): the current order is planned
// here, so the helicopter has its leg the moment it is out - not a tick later
// - and the watch starts on that order's serial.
private _st = createHashMapFromArray [["serial", _logic getVariable [QGVAR(serial), 0]], ["phase", ""]];
[_logic, _veh, _st, _order] call FUNC(transportPlan);
[FUNC(transportTick), AIR_TICK, [_logic, _veh, _st]] call CBA_fnc_addPerFrameHandler;
