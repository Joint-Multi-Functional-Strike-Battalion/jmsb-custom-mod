#include "script_component.hpp"
/*
 * Author: YonV
 * Puts the squad in the back of a QRF aircraft and starts its watch
 * (FUNC(qrfTick)). VIRTUAL UNTIL TASKED (user, 2026-11-02: "all support
 * aircraft needs to be virtual till tasked, then they spawn in at alt over the
 * support module location"): the airframe is made now over the module at its
 * flight height, engines on (FUNC(spawnAircraft)), and the squad in its cargo.
 * After the insertion it RTBs to the module and is removed there (user,
 * 2026-11-02: "egress then RTB"), virtual again. Going home uses no respawn.
 *
 * THE FLIGHT FOLLOWS THE INSERTION:
 *
 *   STATIC   low and slow at the static-line height, over the grid
 *   ASSAULT  helicopter nap of the earth, for the grid
 *
 * TACTICAL (user, 2026-11-01): out of the module at the support core's transit
 * height - a helicopter nap of the earth, a fixed-wing at its transit
 * altitude - and dark once clear of it. A static line comes to its height on
 * the way in (FUNC(qrfTick), EFUNC(support,approachHeight)); it starts on that
 * slope when the grid is close.
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
    _logic setVariable [QGVAR(abort), false, true];
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    _logic setVariable [QGVAR(plan), [], true];
    [_logic, _why, "normal", _requester] call FUNC(say);
    [_logic, "DECLINED", _why] call FUNC(threadState);
    _logic setVariable [QGVAR(sortieThread), nil];
    _logic setVariable [QGVAR(qrfJob), nil];
};

if (_logic getVariable [QGVAR(abort), false]) exitWith {["stood down"] call _fnc_standDown};

private _cls = _logic getVariable [QGVAR(cls), ""];
private _alt = if (_task isEqualTo TASK_ASSAULT) then {
    [_cls, FLY_TRANSIT] call EFUNC(support,flightHeight)
} else {
    [_cls, _logic getVariable [QGVAR(staticAlt), 250], (_logic getVariable [QGVAR(home), getPosATL _logic]) distance2D _pos] call EFUNC(support,approachHeight)
};

private _veh = [_logic, +_pos, _alt] call FUNC(spawnAircraft);
if (!alive _veh) exitWith {["could not launch"] call _fnc_standDown};
[_veh, _alt] call EFUNC(support,flyAt);

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

// DRONE ESCORTS (user, 2026-11-02: "based on lz security for helos and always
// for fix wings"): a plane's always, a helicopter's only on a YELLOW or RED LZ
// security - a `qrf` card has none - made beside it over the module.
[_logic, _veh, _pos, format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]], _logic getVariable [QGVAR(side), west]] call FUNC(escortLaunch);

_logic setVariable [QGVAR(vehicle), _veh, true];
_logic setVariable [QGVAR(status), "inbound", true];
_logic setVariable [QGVAR(ticking), true];
[_logic, format ["airborne with %1 aboard, inbound %2", count _aboard, mapGridPosition _pos], "normal", _requester] call FUNC(say);
// WHEELS UP and ON TASK in the asset's thread, if one was filed to it
// (2026-11-01; WHEELS UP for a QRF tasked by message, step 7) - WHEELS UP
// "INBOUND - ETA m:ss" to the link-up (user, 2026-11-01).
private _eta = [[_veh, _pos] call EFUNC(support,etaTo)] call EFUNC(support,etaText);
[_logic, CARD_WHEELS_UP, [mapGridPosition _veh, format [WHEELS_UP_INBOUND, _eta]] select (_eta isNotEqualTo "")] call FUNC(threadCard);
[_logic, "IN_PROGRESS"] call FUNC(threadState);

private _st = createHashMapFromArray [
    ["phase", "in"],
    ["task", _task],
    ["pos", _pos],
    ["group", _grp],
    ["jumpers", +_aboard],
    ["requester", _requester],
    ["until", CBA_missionTime + SORTIE_TIMEOUT]
];
// Kept on the module (2026-11-09): MOVE, FRAGO, HOLD and ABORT re-aim it
// (FUNC(qrfReply)).
_logic setVariable [QGVAR(qrfState), _st];
[FUNC(qrfTick), JUMP_INTERVAL, [_logic, _veh, _st]] call CBA_fnc_addPerFrameHandler;
