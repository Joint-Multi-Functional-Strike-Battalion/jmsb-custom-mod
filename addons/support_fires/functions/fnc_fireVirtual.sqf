#include "script_component.hpp"
/*
 * Author: JMSB
 * Schedules one virtual battery's part of a fire mission. Nothing is fired
 * from anywhere: the mission is a timetable of rounds, each one leaving its
 * gun on the battery's rhythm (FUNC(virtualShot)) and arriving a time of
 * flight later (FUNC(virtualRound)).
 *
 * THE TIMETABLE, Simplex's fire mission:
 *   response  - the wait before the first round: the module's random response
 *               time plus the DELAY the requester asked for
 *   volley    - every gun fires its rounds, one per reload plus the INTERVAL
 *               asked for; guns within a salvo a moment apart
 *   repeat    - REPEAT more volleys, each starting once the one before has
 *               landed and the battery's cooldown has passed (Simplex's loop,
 *               whose delay defaults to and cannot be under the cooldown)
 * Each round is aimed by the sheaf type (FUNC(aimPoint)). Fewer rounds left
 * than asked fires what is left. SHOT and SPLASH are called per volley; the
 * mission finishes once the last round is down.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target position, ATL <ARRAY>
 * 2: [kind, rounds per gun, sheaf (m), guns (0 all), name, sheaf type, delay, interval, repeat, coordinate] <ARRAY>
 * 3: Mission token <NUMBER>
 * 4: Wait before the first round (s) <NUMBER>
 *
 * Return Value:
 * [rounds scheduled, guns, time of flight (s), volleys], [] when it cannot fire <ARRAY>
 *
 * Example:
 * [_logic, _pos, ["he", 2, 50, 0, "HE", 0, 0, 0, 0, 0], 1, 30] call jmfsb_support_fires_fnc_fireVirtual
 *
 * Public: No
 */

params ["_logic", "_target", "_opts", "_token", "_response"];
_opts params [
    ["_kind", "", [""]], ["_rounds", 1, [0]], ["_sheaf", 0, [0]], ["_want", 0, [0]], "",
    ["_sheafType", SHEAF_CONVERGED, [0]], "", ["_interval", 0, [0]], ["_repeat", 0, [0]]
];

private _stock = _logic getVariable [QGVAR(stock), []];
private _index = _stock findIf {(_x select 3) isEqualTo _kind};
if (_index < 0) exitWith {[]};
(_stock select _index) params ["", ["_left", 0], ["_cls", ""]];
if (_left isEqualTo 0 || _cls isEqualTo "") exitWith {[]};

private _origin = _logic getVariable [QGVAR(origin), getPosATL _logic];
private _ball = [_origin distance2D _target, _logic getVariable [QGVAR(muzzleVelocity), 0], _logic getVariable [QGVAR(highAngle), true]] call FUNC(ballistics);
if (_ball isEqualTo []) exitWith {[]};
_ball params ["_angle", "_tof", "_steep"];
// A round is spawned VA_DESCENT_TIME before it lands and never before it is
// shot, so a flat shot shorter than that lands VA_DESCENT_TIME after the shot.
private _eta = _tof max VA_DESCENT_TIME;

private _guns = _logic getVariable [QGVAR(gunCount), 1];
if (_want > 0) then {_guns = _want min _guns};
private _volleys = 1 + (0 max _repeat);
private _total = _guns * _rounds * _volleys;
if (_left > 0) then {_total = _total min _left};
_volleys = ceil (_total / (_guns * _rounds));

private _gap = (_logic getVariable [QGVAR(reload), 1]) + (0 max _interval);
private _volleyLen = (_rounds - 1) * _gap + (_guns - 1) * VA_GUN_STAGGER;
private _cycle = _volleyLen + _eta + VA_SETTLE + (_logic getVariable [QGVAR(cooldown), 0]);
private _dir = _origin getDir _target;
private _grid = mapGridPosition _target;

_logic setVariable [QGVAR(status), STATUS_FIRING, true];

private _shot = 0;
private _lastFire = _response;
for "_v" from 0 to (_volleys - 1) do {
    private _start = _response + _v * _cycle;
    private _volleyWord = ["", format ["volley %1 of %2 - ", _v + 1, _volleys]] select (_volleys > 1);
    [_logic, _token, format ["shot, over - %1impact grid %2 in %3 sec", _volleyWord, _grid, round _eta], "high", _start] call FUNC(sayLater);
    [_logic, _token, format ["splash grid %1, over", _grid], "high", _start + _eta - SPLASH_LEAD] call FUNC(sayLater);
    for "_r" from 0 to (_rounds - 1) do {
        for "_g" from 0 to (_guns - 1) do {
            if (_shot < _total) then {
                _lastFire = _start + _r * _gap + _g * VA_GUN_STAGGER;
                private _aim = [_target, _dir, _sheafType, _sheaf, _g, _guns, _r, _rounds] call FUNC(aimPoint);
                [{_this call FUNC(virtualShot)}, [_logic, _token, _kind, _cls, _aim, _angle, _steep, _tof, _dir], _lastFire] call CBA_fnc_waitAndExecute;
                _shot = _shot + 1;
            };
        };
    };
};

[{
    params ["_logic", "_token"];
    [_logic, _token, "rounds complete, over"] call FUNC(finish);
}, [_logic, _token], _lastFire + _eta + VA_SETTLE] call CBA_fnc_waitAndExecute;

[_shot, _guns, _eta, _volleys]
