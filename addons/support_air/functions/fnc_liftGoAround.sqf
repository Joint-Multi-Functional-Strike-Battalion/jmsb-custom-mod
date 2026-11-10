#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a transport goes around (FM 3-21.38 Table 3-3: "do not land -
 * circle and begin another approach"). The leg it was flying in to its point
 * is flown again straight at it (its ROUTE is behind it): ropes in (ACE's
 * cut, the rappel's taken in), the flight control let go, the LZ STATUS asked
 * again on the way, and at the point the circle, the mark and CLEARED TO LAND
 * again (FUNC(liftTick), EFUNC(support,lzClear)). WAVE OFF from aboard
 * (FUNC(srvWaveOff), 2026-11-08) and the GO AROUND command when the core's
 * landing wait does not take it - after CLEARED TO LAND on final, an
 * extraction's low hover, a rope hover (FUNC(liftReply), 2026-11-09).
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * Gone around - the grid of the point it comes in to again, "" when it cannot
 * (on the ground, no order) <STRING>
 *
 * Example:
 * [_logic] call jmfsb_support_air_fnc_liftGoAround
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {""};
private _job = _logic getVariable [QGVAR(liftJob), createHashMap];
private _veh = _logic getVariable [QGVAR(vehicle), objNull];
if (count _job isEqualTo 0 || {!alive _veh} || {isTouchingGround _veh}) exitWith {""};
private _order = +(_logic getVariable [QGVAR(order), []]);
if (_order isEqualTo []) exitWith {""};

// ropes in
if (!isNil "ace_fastroping_fnc_cutRopes" && {(_veh getVariable ["ace_fastroping_deployedRopes", []]) isNotEqualTo []}) then {
    [_veh] call ace_fastroping_fnc_cutRopes;
};
[_veh, false] call FUNC(rappelRopes);
{_x setVariable [QGVAR(rappelled), nil]} forEach crew _veh;

// the core's landing wait over - asked again at the point
[_job get "thread", WORD_ABORT] call EFUNC(support,lzClearReply);

// the leg again, straight at the point, LZ STATUS? asked on the way
private _opts = +(_order param [7, createHashMap]);
_opts set ["via", []];
_order set [7, _opts];
private _task = _order select 0;
{_job set _x} forEach [
    ["askAt", _task],
    ["inboundTo", (_job getOrDefault ["inboundTo", []]) + [_task]],
    ["asked", false],
    ["holding", false],
    ["landing", ""],
    ["landAt", []],
    ["down", false],
    ["step", JOB_FLYING]
];
_logic setVariable [QGVAR(order), _order];
_logic setVariable [QGVAR(serial), (_logic getVariable [QGVAR(serial), 0]) + 1];
INFO_2("liftGoAround: %1 going around for %2",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],mapGridPosition (_order select 1));
mapGridPosition (_order select 1)
