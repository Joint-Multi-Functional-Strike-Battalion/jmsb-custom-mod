#include "script_component.hpp"
/*
 * Author: YonV
 * The "reach" code of provider "fires" (support core README, 2026-11-01):
 * whether this asset can put its fires on one map point, how soon and with
 * what - its row of the board's reach card. Asked once per target click on
 * the viewer's machine, so it reads only what the server published on the
 * module, through the same reads as the verdict before CONFIRM
 * (FUNC(preview)): FUNC(available), FUNC(gunRanges), FUNC(ballistics).
 *
 * THE ETA IS THE QUICKEST THE ORDER CAN BE: the module's shortest response,
 * then the flight - no DELAY, which is the player's to add on the screen.
 *
 *   artillery  response + time of flight    "4 GUNS - HE 24 RDS - SMOKE 12 RDS"
 *   cruise     response + boost + cruise    "6 MISSILES LEFT - SALVO 2"
 *   loitering  the transit, as the preview  "4 MUNITIONS LEFT"
 *              reads it; unknown without one
 *
 * CANNOT: "TASKED" (firing, inbound, on station), "NO STORES", "COOLDOWN n S",
 * "OUT OF RANGE 14.2/12 KM", "TOO CLOSE 1.2/2 KM", "NO FIRING SOLUTION".
 *
 * Arguments:
 * 0: Asset id, "fires:<n>" <STRING>
 * 1: The point, [x, y, z] ATL <ARRAY>
 *
 * Return Value:
 * 0: Can service the point now <BOOL>
 * 1: ETA in seconds, -1 unknown <NUMBER>
 * 2: Why not, "" when it can <STRING>
 * 3: Effect, one line <STRING>
 * 4: Task tokens valid at the point <ARRAY of STRINGs>
 *
 * Example:
 * ["fires:0", [1000, 2000, 0]] call jmfsb_support_fires_fnc_reach
 *
 * Public: No
 */

params [["_assetId", "", [""]], ["_pos", [], [[]]]];

private _logic = [_assetId] call FUNC(logicOf);
if (isNull _logic) exitWith {[false, REACH_ETA_UNKNOWN, "GONE", "", []]};

private _type = _logic getVariable [QGVAR(type), ""];

// THE EFFECT: what it would put on the point, from what it has left.
private _effect = switch (_type) do {
    case TYPE_ARTY: {
        private _words = (([_logic] call FUNC(ordnance)) select [0, REACH_ORD_SHOWN]) apply {
            _x params ["_name", "_left"];
            format ["%1 %2 RDS", _name, [str _left, REACH_UNLIMITED] select (_left < 0)]
        };
        ([format ["%1 GUNS", _logic getVariable [QGVAR(gunCount), 0]]] + _words) joinString REACH_SEP
    };
    case TYPE_CRUISE: {
        format ["%1 MISSILES LEFT%2SALVO %3", _logic getVariable [QGVAR(left), 0], REACH_SEP, _logic getVariable [QGVAR(salvo), 1]]
    };
    case TYPE_LOITER: {format ["%1 MUNITIONS LEFT", _logic getVariable [QGVAR(left), 0]]};
    default {""};
};

// BUSY, SPENT OR REARMING - the one rule the row and the order read.
([_logic] call FUNC(available)) params ["_ok", "_status"];
if (!_ok) exitWith {
    private _why = switch (_status) do {
        case STATUS_EXPENDED: {"NO STORES"};
        case STATUS_COOLDOWN: {format ["COOLDOWN %1 S", ceil ((_logic getVariable [QGVAR(readyAt), 0]) - CBA_missionTime)]};
        default {"TASKED"};
    };
    [false, REACH_ETA_UNKNOWN, _why, _effect, []]
};
if (count _pos < 2) exitWith {[false, REACH_ETA_UNKNOWN, "NO TARGET POINT", _effect, []]};

// THE RANGE, the limits FUNC(inRange) and the map rings read.
private _origin = _logic getVariable [QGVAR(origin), getPosATL _logic];
private _dist = _origin distance2D _pos;
([_logic] call FUNC(gunRanges)) params ["_min", "_max"];
private _km = {
    params ["_m"];
    parseNumber ((_m / M_PER_KM) toFixed REACH_KM_DECIMALS)
};
if (_dist > _max) exitWith {
    [false, REACH_ETA_UNKNOWN, format ["OUT OF RANGE %1/%2 KM", [_dist] call _km, [_max] call _km], _effect, []]
};
if (_dist < _min) exitWith {
    [false, REACH_ETA_UNKNOWN, format ["TOO CLOSE %1/%2 KM", [_dist] call _km, [_min] call _km], _effect, []]
};

(_logic getVariable [QGVAR(response), [0, 0]]) params [["_respMin", 0]];
private _eta = REACH_ETA_UNKNOWN;
private _solved = true;
switch (_type) do {
    case TYPE_ARTY: {
        // The arc the battery would fire; a point inside the limits it cannot
        // solve for is refused by FUNC(inRange) too.
        private _ball = [_dist, _logic getVariable [QGVAR(muzzleVelocity), VA_DEF_MV], _logic getVariable [QGVAR(highAngle), true], RISE(_origin,_pos)] call FUNC(ballistics);
        _solved = _ball isNotEqualTo [];
        if (_solved) then {_eta = _respMin + ((_ball param [1, 0]) max VA_DESCENT_TIME)};
    };
    case TYPE_CRUISE: {
        _eta = _respMin + CM_BOOST_TIME + _dist / (_logic getVariable [QGVAR(speed), 1]);
    };
    case TYPE_LOITER: {
        private _reach = _logic getVariable [QGVAR(reach), 0];
        if (_reach > 0 && _reach < LM_REACH_UNLIMITED) then {_eta = _respMin + _dist / (_reach / LM_TRANSIT_MAX)};
    };
};
if (!_solved) exitWith {[false, REACH_ETA_UNKNOWN, "NO FIRING SOLUTION", _effect, []]};

[true, _eta, "", _effect, ([_type, _logic] call FUNC(taskDecls)) apply {_x select 0}]
