#include "script_component.hpp"
/*
 * Author: JMSB
 * Puts a CAS sortie in the air and starts its watch (FUNC(casTick)).
 *
 * TWO WAYS TO FLY IT, by task:
 *
 *   ATTACK RUN and LOITER - the AI flies and nothing else. CARELESS, BLUE,
 *   targeting off: the same reasoning as the CAS drones (addons/cas
 *   FUNC(request)) - air AI handed a target decides for itself whether to
 *   shoot it, so the run releases through EFUNC(cas,fireAt) and only there.
 *
 *   SAD - the crew is let off the leash: COMBAT, RED, targeting on, holding
 *   an orbit over the grid. The watch adds the scripted strikes on what is
 *   painted or known (FUNC(casStrike)) so a SAD that the AI is shy about
 *   still puts ordnance down.
 *
 * WHERE IT COMES FROM, Simplex-style. A CLASS aircraft is not flown out of
 * an airbase: it appears the module's Ingress Distance out on the INGRESS
 * bearing (the module's side of the target when none was picked), and when
 * the sortie is over it leaves the same distance out on the EGRESS bearing
 * (straight through when none) and is removed there. A SYNCED aircraft takes
 * off from its stand, flies to the ingress point at the run-in distance
 * before it turns in, and goes home to its stand afterwards.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: "sad", "loiter" or "run" <STRING>
 * 2: Target position ATL <ARRAY>
 * 3: Working height above the terrain, m <NUMBER>
 * 4: Orbit radius, m <NUMBER>
 * 5: Passes, for a run <NUMBER>
 * 6: Magazine class to use, "" for the heaviest aboard <STRING>
 * 7: Who asked <OBJECT>
 * 8: Options - "ingress", "egress" (points, [] for auto), "danger" (BOOL) <HASHMAP>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "run", _pos, 600, 500, 2, "", player, createHashMap] call jmfsb_support_air_fnc_casLaunch
 *
 * Public: No
 */

params [
    ["_logic", objNull, [objNull]],
    ["_mode", "run", [""]],
    ["_pos", [], [[]]],
    ["_alt", 600, [0]],
    ["_radius", RADIUS_MIN, [0]],
    ["_passes", 1, [0]],
    ["_mag", "", [""]],
    ["_requester", objNull, [objNull]],
    ["_opts", createHashMap, [createHashMap]]
];

if (isNull _logic) exitWith {};

// RECALLED WHILE IT WAS STILL ON THE GROUND: the sortie never flew, so it is
// given back.
private _fnc_giveBack = {
    private _left = _logic getVariable [QGVAR(left), -1];
    if (_left >= 0) then {_logic setVariable [QGVAR(left), _left + 1, true]};
    _logic setVariable [QGVAR(plan), [], true];
};
if (_logic getVariable [QGVAR(abort), false]) exitWith {
    call _fnc_giveBack;
    _logic setVariable [QGVAR(abort), false, true];
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    [_logic, "stood down", "normal", _requester] call FUNC(say);
};

// THE LEGS. In on the ingress bearing, out on the egress bearing.
private _ingress = _opts getOrDefault ["ingress", []];
private _egress = _opts getOrDefault ["egress", []];
private _home = _logic getVariable [QGVAR(home), getPosATL _logic];
private _inDir = _pos getDir ([_ingress, _home] select (_ingress isEqualTo []));
private _outDir = if (_egress isEqualTo []) then {_inDir + 180} else {_pos getDir _egress};
private _reach = (_logic getVariable [QGVAR(ingressDistance), 6000]) max INGRESS_FLOOR;
private _runIn = _logic getVariable [QGVAR(runIn), 3000];

private _synced = _logic getVariable [QGVAR(synced), objNull];
private _fromStand = alive _synced;
private _veh = if (_fromStand) then {_synced} else {
    [_logic, _pos, _alt, _pos getPos [_reach, _inDir]] call FUNC(spawnAircraft)
};

// A launch that fails never flew, so its sortie is given back too.
if (!alive _veh) exitWith {
    call _fnc_giveBack;
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    [_logic, "could not launch", "high", _requester, false] call FUNC(say);
};

private _grp = [_logic, _veh] call FUNC(prepareAircraft);
if (isNull _grp) exitWith {
    call _fnc_giveBack;
    if (!_fromStand) then {[_veh] call FUNC(sweep)};
    _logic setVariable [QGVAR(status), STATUS_IDLE, true];
    [_logic, "has no crew", "high", _requester, false] call FUNC(say);
};

[_grp, _mode] call FUNC(casPosture);

// What the strike release reads off the airframe (EFUNC(cas,fireAt)).
_veh setVariable [QEGVAR(cas,ordnance), _mag];
_veh setVariable [QEGVAR(cas,fired), false];

// A synced aircraft with an ingress picked flies to it first and turns in
// from there; a class aircraft already starts on that bearing.
private _entry = if (_fromStand && {_ingress isNotEqualTo []}) then {_pos getPos [_runIn, _inDir]} else {[]};

_veh engineOn true;
_veh flyInHeight _alt;
if (_entry isEqualTo []) then {
    [_veh, _pos, ["NORMAL", "FULL"] select (_mode isEqualTo "run")] call FUNC(moveTo);
} else {
    [_veh, _entry, "FULL"] call FUNC(moveTo);
};

_logic setVariable [QGVAR(vehicle), _veh, true];
_logic setVariable [QGVAR(status), "inbound", true];
_logic setVariable [QGVAR(ticking), true];

private _exit = if (_fromStand) then {[]} else {_pos getPos [_reach, _outDir]};
private _plan = [];
if (_entry isNotEqualTo []) then {_plan pushBack [_entry, PLAN_IN]};
_plan pushBack [_pos, toUpper _mode];
_plan pushBack [[_pos getPos [_runIn, _outDir], _exit] select (_exit isNotEqualTo []), PLAN_OUT];
_logic setVariable [QGVAR(plan), _plan, true];

private _st = createHashMapFromArray [
    ["phase", ["in", "entry"] select (_entry isNotEqualTo [])],
    ["mode", _mode],
    ["pos", _pos],
    ["radius", _radius],
    ["passes", _passes],
    ["requester", _requester],
    ["until", CBA_missionTime + SORTIE_TIMEOUT],
    ["next", 0],
    ["entry", _entry],
    ["outDir", [-1, _outDir] select (_egress isNotEqualTo [])],
    ["danger", _opts getOrDefault ["danger", false]],
    ["exit", _exit]
];

INFO_3("%1 airborne for %2 on %3",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_mode,mapGridPosition _pos);
[_logic, format ["airborne, inbound %1", mapGridPosition _pos], "normal", _requester] call FUNC(say);

[FUNC(casTick), AIR_TICK, [_logic, _veh, _st]] call CBA_fnc_addPerFrameHandler;
