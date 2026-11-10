#include "script_component.hpp"
/*
 * Author: YonV
 * Schedules one virtual battery's part of a fire mission. Nothing is fired
 * from anywhere: the mission is a timetable of rounds, each one leaving its
 * gun on the battery's rhythm (FUNC(virtualShot)) and arriving a time of
 * flight later (FUNC(virtualRound)).
 *
 * ADJUST FIRE (2026-11-01): the options' adjust call (OPT_ADJUST) makes
 * ADJ_ROUND one round from one gun on the point, and ends an ADJ_ROUND or
 * ADJ_FFE salvo in a hold for the observer (FUNC(adjustHold)) instead of the
 * mission's end. Each salvo is numbered (QGVAR(salvo)) for the round log.
 *
 * THE TIMETABLE, modelled on Simplex Support Services' fire mission (the
 * method read, no code of it used; 2026-11-05):
 *   response  - the wait before the first round: the module's random response
 *               time plus the DELAY the requester asked for
 *   volley    - every gun fires its rounds, one per reload plus the INTERVAL
 *               asked for; guns within a salvo a moment apart
 *   repeat    - REPEAT more volleys (Simplex's loops), each following on the
 *               gun's own rhythm: its first round one gap after the gun's
 *               last of the volley before - no cooldown and no wait for the
 *               splash between volleys. The cooldown is paid once, at the end
 *               (FUNC(finish)), as Simplex pays it after its last loop
 * Each round is aimed by the sheaf type (FUNC(aimPoint)). Fewer rounds left
 * than asked fires what is left. SHOT and SPLASH are called per volley, and a
 * mission of several numbers them (a volley's SHOT can come before the one
 * before it has splashed); the mission finishes once the last round is down.
 * A battery a call for fire tasked by message also files SHOT and SPLASH in
 * its thread (FUNC(threadVolley), 2026-11-01), and its prompt as the last
 * round of the last volley lands - the volley's real length, first round to
 * last, is known here and handed on.
 *
 * A CALL FOR FIRE'S SHAPE (user, 2026-11-02): the options' attitude and
 * length (OPT_ATTITUDE, OPT_LENGTH) aim a linear target along its own line and
 * walk a creeping barrage over every round of the mission, volley after
 * volley. THE GAP JITTERS (2026-11-02, Tun Firesupport by Tuntematon /
 * Armafinland): each gun's next round comes the gap plus or minus
 * JITTER_SHARE of it and JITTER_SHORT over it, so a short gap jitters most -
 * guns are not metronomes.
 *
 * AIMING ERROR AND AIRBURST (user, 2026-11-02, from the Tun Firesupport
 * review): the whole salvo is aimed one offset off the point - the aiming
 * error its mission has left (FUNC(aimError)), drawn once per salvo inside an
 * ellipse along the line of fire (FUNC(scatter)); the options' fuze
 * (OPT_FUZE) bursts the rounds in the air, except an adjusting round's.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target position, ATL <ARRAY>
 * 2: [kind, rounds per gun, sheaf (m), guns (0 all), name, sheaf type, delay, interval, repeat, coordinate, adjust call, attitude (-1 none), length (0 none), fuze ("" impact, FUZE_AIRBURST)] <ARRAY>
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
    ["_sheafType", SHEAF_CONVERGED, [0]], "", ["_interval", 0, [0]], ["_repeat", 0, [0]], "",
    ["_call", ADJ_NONE, [0]], ["_attitude", -1, [0]], ["_length", 0, [0]], ["_fuze", "", [""]]
];
// An adjusting round bursts on impact, as an FDC adjusts with a quick fuze.
private _burst = _fuze isEqualTo FUZE_AIRBURST && _call isNotEqualTo ADJ_ROUND;

// ADJUST FIRE (2026-11-01): an adjusting round is one round from one gun on
// the point itself; an adjust mission's salvo ends in a hold, not the end.
private _held = _call in [ADJ_ROUND, ADJ_FFE];
if (_call isEqualTo ADJ_ROUND) then {
    _rounds = 1;
    _want = 1;
    _sheaf = 0;
    _length = 0;
    _repeat = 0;
};

private _stock = _logic getVariable [QGVAR(stock), []];
private _index = _stock findIf {(_x select 3) isEqualTo _kind};
if (_index < 0) exitWith {[]};
(_stock select _index) params ["", ["_left", 0], ["_cls", ""]];
if (_left isEqualTo 0 || _cls isEqualTo "") exitWith {[]};

private _origin = _logic getVariable [QGVAR(origin), getPosATL _logic];
private _rise = RISE(_origin,_target);
private _ball = [_origin distance2D _target, _logic getVariable [QGVAR(muzzleVelocity), 0], _logic getVariable [QGVAR(highAngle), true], _rise] call FUNC(ballistics);
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
private _jitter = JITTER_SHARE * _gap + JITTER_SHORT / _gap;
// A creeping walk steps over every round of the mission, not one volley's.
private _walk = _sheafType isEqualTo SHEAF_CREEPING && _length > 0;
private _dir = _origin getDir _target;
private _grid = mapGridPosition _target;
// The salvo's aiming error: one offset for all its rounds.
private _aimError = [_logic] call FUNC(aimError);
private _laid = [_target, _dir, _aimError, _aimError * DISP_DEFLECTION_SHARE] call FUNC(scatter);

_logic setVariable [QGVAR(status), STATUS_FIRING, true];
// The salvo's number in the mission - the observer's call it answers.
private _salvo = (_logic getVariable [QGVAR(salvo), 0]) + 1;
_logic setVariable [QGVAR(salvo), _salvo];

// EACH GUN'S OWN CLOCK, kept across the volleys: when its last round left, s
// from now, -1 before its first. Its next round is a jittered gap after it,
// whichever volley that round belongs to.
private _gunAt = [];
for "_g" from 0 to (_guns - 1) do {_gunAt pushBack -1};
private _shot = 0;
private _lastFire = _response;
for "_v" from 0 to (_volleys - 1) do {
    private _start = -1;
    private _end = _response;
    for "_r" from 0 to (_rounds - 1) do {
        for "_g" from 0 to (_guns - 1) do {
            if (_shot < _total) then {
                private _fireAt = _gunAt select _g;
                if (_fireAt < 0) then {
                    _fireAt = _response + _g * VA_GUN_STAGGER;
                } else {
                    _fireAt = _fireAt + ((_gap - _jitter + random (2 * _jitter)) max (JITTER_FLOOR * _gap));
                };
                _gunAt set [_g, _fireAt];
                if (_start < 0 || _fireAt < _start) then {_start = _fireAt};
                _end = _end max _fireAt;
                private _step = [_r, _v * _rounds + _r] select _walk;
                private _steps = [_rounds, _volleys * _rounds] select _walk;
                private _aim = [_laid, _dir, _sheafType, _sheaf, _g, _guns, _step, _steps, _attitude, _length] call FUNC(aimPoint);
                [{_this call FUNC(virtualShot)}, [_logic, _token, _kind, _cls, _aim, _angle, _steep, _tof, _dir, _salvo, _burst], _fireAt] call CBA_fnc_waitAndExecute;
                _shot = _shot + 1;
            };
        };
    };
    if (_start >= 0) then {
        _lastFire = _lastFire max _end;
        private _volleyWord = ["", format ["volley %1 of %2 - ", _v + 1, _volleys]] select (_volleys > 1);
        [_logic, _token, format ["shot, over - %1impact grid %2 in %3 sec", _volleyWord, _grid, round _eta], "high", _start] call FUNC(sayLater);
        [_logic, _token, format ["splash grid %1, over", _grid], "high", _start + _eta - SPLASH_LEAD] call FUNC(sayLater);
        // SHOT and SPLASH in the thread a call for fire tasked it with, and its
        // prompt after the last volley's last round (2026-11-01, step 6).
        [_logic, _token, _call, _start, _eta, _v isEqualTo (_volleys - 1), _end - _start, _v + 1, _volleys] call FUNC(threadVolley);
    };
};

// Hoisted: a comma inside a macro argument reads as an argument separator.
private _callsign = _logic getVariable [QGVAR(callsign), "FIRES"];
private _plan = format ["%1 volleys x %2 rounds x %3 guns, gap %4 s", _volleys, _rounds, _guns, round _gap];
INFO_5("%1 salvo %2: %3, rise %4 m, last round lands in %5 s",_callsign,_salvo,_plan,round _rise,round (_lastFire + _eta));

[{
    params ["_logic", "_token", "_held", "_said"];
    if (_held) exitWith {[_logic, _token, _said] call FUNC(adjustHold)};
    [_logic, _token, _said] call FUNC(finish);
}, [_logic, _token, _held, ["rounds complete, over", ""] select (_call isEqualTo ADJ_ROUND)], _lastFire + _eta + VA_SETTLE] call CBA_fnc_waitAndExecute;

[_shot, _guns, _eta, _volleys]
