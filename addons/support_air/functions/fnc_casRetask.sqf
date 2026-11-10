#include "script_component.hpp"
/*
 * Author: YonV
 * Server: a strike card for a CAS aircraft already in the air (2026-11-01,
 * DESIGN_SUPPORT_MESSAGING 1.1, 5.4 and step 5) - a `cas` card filed to the box
 * of an aircraft on station (FUNC(srvThread)), or a new `cas` card filed in a
 * thread it strikes for, the answer to FURTHER TASKING? (FUNC(threadReply)).
 *
 *   ON STATION, ANY AIRCRAFT   a strike from the hold (FUNC(casJob)) in that
 *                              thread, replacing the strike it had there
 *   A HELICOPTER'S ATTACK RUN  the run's new target: it holds short of it
 *                              (FUNC(casTick) "in") until CLEARED HOT
 *
 * The card's checks again on the airframe in the air: a target, danger close
 * (EFUNC(support,dangerClose)), the store or a laser (EFUNC(cas,orderStore)).
 * Taken: WILCO with the ETA from where it is, then the READBACK (2026-11-09,
 * docs/DESIGN_MESSAGE_TEMPLATES.md tree 3, EFUNC(cas,casAsk)): CORRECT lets it
 * run in to the IP (FUNC(casJob), FUNC(casRun)), where IN asks the clearance.
 * The order's type of control and TOT go with it (FUNC(casFlow)). A strike
 * from station re-tasked while running in turns back to the hold first.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Thread id <STRING>
 * 2: The order, from EFUNC(support,readOrder) <HASHMAP>
 * 3: Who asked <OBJECT>
 *
 * Return Value:
 * Why it was not taken, "" when it was <STRING>
 *
 * Example:
 * [_logic, _threadId, _order, _issuer] call jmfsb_support_air_fnc_casRetask
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_threadId", "", [""]],
    ["_order", createHashMap, [createHashMap]],
    ["_issuer", objNull, [objNull]]
];

private _veh = _logic getVariable [QGVAR(vehicle), objNull];
if (!alive _veh) exitWith {WHY_NOT_ON_STATION};
private _target = _order getOrDefault ["target", []];
if (_target isEqualTo []) exitWith {WHY_NO_TARGET};
([_order, _logic getVariable [QGVAR(side), west]] call EFUNC(support,dangerClose)) params ["_safe", "_unsafeWhy"];
if (!_safe) exitWith {_unsafeWhy};
([_veh, _order] call EFUNC(cas,orderStore)) params ["_armed", "_unarmedWhy", "_mag"];
if (!_armed) exitWith {_unarmedWhy};

private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];
private _callsign = _logic getVariable [QGVAR(callsign), "AIR"];
private _st = _logic getVariable [QGVAR(sortieState), createHashMap];
private _desc = _order getOrDefault ["description", ""];
private _label = _order getOrDefault ["label", ""];
if (_label isNotEqualTo "") then {_desc = trim format ["%1 (%2)", _desc, _label]};
private _ingress = _order getOrDefault ["ingress", []];
private _egress = _order getOrDefault ["egress", []];

private _fnc_wilco = {
    params ["_eta"];
    private _words = [[_eta] call EFUNC(support,etaText)];
    if (_desc isNotEqualTo "") then {_words pushBack (_desc select [0, DESCRIPTION_MAX])};
    [_assetId, "ACCEPTED", (_words select {_x isNotEqualTo ""}) joinString WILCO_SEP, _callsign, false, _threadId] call EFUNC(support,state);
};

private _why = "";
if (_logic getVariable [QGVAR(onStation), false]) then {
    // ON STATION: a strike from the hold.
    private _route = [getPosATL _veh];
    if (_ingress isNotEqualTo []) then {_route pushBack _ingress};
    _route pushBack _target;
    [[typeOf _veh, _route, SPEED_FULL] call FUNC(flightTime)] call _fnc_wilco;
    private _job = createHashMapFromArray [
        ["thread", _threadId],
        ["pos", _target],
        ["ingress", _ingress],
        ["egress", _egress],
        ["mag", _mag],
        ["danger", _order getOrDefault ["dcTick", false]],
        ["requester", _issuer],
        ["cleared", false]
    ];
    {_job set _x} forEach ([_order] call FUNC(casFlow));
    _logic setVariable [QGVAR(job), _job];
    // Re-tasked on the way in: the pass under way is over, back to the hold
    // for the READBACK (FUNC(casTick) "back" keeps a job that has not begun).
    if ((_st getOrDefault ["phase", ""]) in JOB_PHASES_IN) then {
        [_veh, "re-tasked", "", true] call EFUNC(cas,passEnd);
        [_veh, _st get "hold", "FULL"] call FUNC(moveTo);
        _st set ["phase", "back"];
    };
    INFO_3("%1 strike from station on %2 for %3 - readback asked",_callsign,mapGridPosition _target,name _issuer);
} else {
    // A HELICOPTER'S RUN in its own thread: the new target.
    if ((_st getOrDefault ["mode", ""]) isNotEqualTo "run") exitWith {_why = WHY_NOT_ON_STATION};
    if ((_logic getVariable [QGVAR(sortieThread), ""]) isNotEqualTo _threadId) exitWith {_why = WHY_TASKED};
    [[typeOf _veh, [getPosATL _veh, _target], SPEED_FULL] call FUNC(flightTime)] call _fnc_wilco;
    // A pass still under way on the old target is over; the new one comes in
    // from where it is (2026-11-05).
    [_veh, "re-tasked", "", true] call EFUNC(cas,passEnd);
    {_st set _x} forEach [
        ["pos", _target],
        ["inDir", -1],
        ["outDir", [-1, _target getDir _egress] select (_egress isNotEqualTo [])],
        ["egress", _egress],
        ["danger", _order getOrDefault ["dcTick", false]],
        ["requester", _issuer],
        ["struck", false],
        ["again", false],
        ["inSaid", false],
        ["phase", "in"]
    ];
    {_st set _x} forEach ([_order] call FUNC(casFlow));
    _veh setVariable [QEGVAR(cas,ordnance), _mag];
    _logic setVariable [QGVAR(cleared), false];
    _logic setVariable [QGVAR(status), "inbound", true];
    [_veh, _target, "FULL"] call FUNC(moveTo);
    INFO_3("%1 run re-tasked onto %2 by %3",_callsign,mapGridPosition _target,name _issuer);
};
if (_why isNotEqualTo "") exitWith {_why};

// THE READBACK (2026-11-09): the next frame, so the WILCO is out first.
[{
    params ["_assetId", "_threadId", "_callsign", "_order"];
    [_assetId, _threadId, CAS_ASK_READBACK, [mapGridPosition (_order getOrDefault ["target", [0, 0, 0]]), _order getOrDefault ["remarks", ""]], _callsign, {_this call FUNC(threadTimeout)}] call EFUNC(cas,casAsk);
}, [_assetId, _threadId, _callsign, _order]] call CBA_fnc_execNextFrame;
""
