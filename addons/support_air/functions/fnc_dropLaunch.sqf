#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts a logistics aircraft in the air over the module and starts its watch
 * (FUNC(dropTick)).
 *
 * A SLING LOAD IS HOOKED ON AT THE MODULE: the crate is created and filled
 * under the helicopter and hung on it before it leaves. A helicopter that
 * will not take it (too heavy for this airframe) drops by parachute instead
 * and says so, rather than arriving with an empty hook.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target position ATL <ARRAY>
 * 2: Parachute release height above the terrain, m <NUMBER>
 * 3: Who asked <OBJECT>
 * 4: The load picked - comma-separated list names <STRING> (optional, default the module's first)
 * 5: Crate signal class, "" for none <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, _pos, 250, player, "magazines", "SmokeShellBlue"] call jmfsb_support_air_fnc_dropLaunch
 *
 * Public: No
 */

// How far below the helicopter a sling crate is created before it is hooked.
#define SLING_HANG 12

params [["_logic", objNull, [objNull]], ["_pos", [], [[]]], ["_height", 250, [0]], ["_requester", objNull, [objNull]], ["_load", "", [""]], ["_signal", "", [""]]];

if (isNull _logic) exitWith {};

if (_logic getVariable [QGVAR(abort), false]) exitWith {
    private _left = _logic getVariable [QGVAR(left), -1];
    if (_left >= 0) then {_logic setVariable [QGVAR(left), _left + 1, true]};
    _logic setVariable [QGVAR(abort), false, true];
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    _logic setVariable [QGVAR(plan), [], true];
    [_logic, "stood down", "normal", _requester] call FUNC(say);
};

private _sling = _logic getVariable [QGVAR(sling), false];
private _alt = [_height, SLING_CRUISE] select _sling;

private _veh = [_logic, _pos, _alt] call FUNC(spawnAircraft);
if (!alive _veh) exitWith {
    // It never flew, so the drop is given back.
    private _left = _logic getVariable [QGVAR(left), -1];
    if (_left >= 0) then {_logic setVariable [QGVAR(left), _left + 1, true]};
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    _logic setVariable [QGVAR(plan), [], true];
    [_logic, "could not launch", "high", _requester, false] call FUNC(say);
};

private _grp = group driver _veh;
_grp setBehaviour "CARELESS";
_grp setCombatMode "BLUE";

private _crate = objNull;
if (_sling) then {
    _crate = createVehicle [_logic getVariable [QGVAR(crateClass), "B_supplyCrate_F"], (getPosATL _veh) vectorAdd [0, 0, -SLING_HANG], [], 0, "CAN_COLLIDE"];
    [_crate, _logic, _load] call FUNC(fillCrate);
    if !(_veh setSlingLoad _crate) then {
        WARNING_2("'%1' would not take '%2' on the hook - dropping it by parachute",typeOf _veh,typeOf _crate);
        deleteVehicle _crate;
        _crate = objNull;
        _sling = false;
        _alt = _height;
        _veh flyInHeight _alt;
    };
};

[_veh, _pos, "NORMAL"] call FUNC(moveTo);

_logic setVariable [QGVAR(vehicle), _veh, true];
_logic setVariable [QGVAR(status), "inbound", true];
_logic setVariable [QGVAR(ticking), true];
[_logic, format ["airborne with your crate, inbound %1", mapGridPosition _pos], "normal", _requester] call FUNC(say);

private _st = createHashMapFromArray [
    ["phase", "in"],
    ["pos", _pos],
    ["sling", _sling],
    ["crate", _crate],
    ["requester", _requester],
    ["load", _load],
    ["signal", _signal],
    ["until", CBA_missionTime + SORTIE_TIMEOUT]
];
[FUNC(dropTick), AIR_TICK, [_logic, _veh, _st]] call CBA_fnc_addPerFrameHandler;
