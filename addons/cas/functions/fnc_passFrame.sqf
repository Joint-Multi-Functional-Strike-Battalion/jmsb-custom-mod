#include "script_component.hpp"
/*
 * Author: YonV
 * One frame of a pass's dive (FUNC(passBegin), from the commit in
 * FUNC(passTick)): the airframe is flown by this addon, not the AI - the way
 * Simplex Support Services flies a strafe (its method, no code of it) - so
 * the nose is on the aim when the trigger is pulled. Velocity only: it is
 * moved by setVelocityTransformation to where its new velocity takes it this
 * frame, so the crew rides it; the PASS_ defines in script_component.hpp say
 * how fast it turns, pitches, banks and closes on the run speed.
 *
 * THE NOSE turns onto the aim (the dummy laser target - a spot that moves is
 * followed) and pitches onto the line of sight until inside the release
 * range, then onto the solution (FUNC(passAim)): the line of sight for a
 * seeker round, the elevation that lands a shell or a bomb on the aim.
 *
 * THE TRIGGER: on the solution within PASS_AIM_TOL deg, held PASS_SETTLE_S
 * s, the store is fired (FUNC(fireAt)) at its own interval until the salvo
 * is down - counted by the Fired handler - or the gun's burst is over; a
 * drift past PASS_HOLD_TOL deg ends the salvo. Pulls that put no round out
 * are tried once as the engine's own fireAtTarget, then given up as dry.
 *
 * BROKEN OFF (FUNC(passEnd)): the ground PASS_LOOK_AHEAD_S s ahead closer
 * than the floor, the nose past PASS_PITCH_LIMIT, the aim passed, the
 * airframe lost. What was released by then counts.
 *
 * Arguments:
 * 0: [aircraft] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(passFrame), 0, [_veh]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params ["_veh"];

private _st = _veh getVariable [QGVAR(pass), createHashMap];
if (count _st isEqualTo 0 || {(_st get "phase") isNotEqualTo PASS_DIVE}) exitWith {[_handle] call CBA_fnc_removePerFrameHandler};
if (!alive _veh || !local _veh || !canMove _veh || isNull driver _veh) exitWith {
    [_veh, "the airframe is lost in the dive", PASS_LOST] call FUNC(passEnd);
};

private _dt = (diag_deltaTime min PASS_FRAME_MAX) max PASS_FRAME_MIN;
private _heli = _st get "heli";
// PositionASL - the airframe's placing point - is what setVelocityTransformation
// moves (2026-11-06: fed getPosWorld, the model centre, the transport
// helicopter's controller lifted it the centre's height over the wheels every
// frame - 130 m/s straight up; support_air heliFrame has the account).
private _pos = getPosASL _veh;
private _dummy = _st get "dummy";
private _aimASL = if (alive _dummy) then {getPosASL _dummy} else {_st get "aimASL"};
private _to2 = [(_aimASL select 0) - (_pos select 0), (_aimASL select 1) - (_pos select 1), 0];
private _d2 = vectorMagnitude _to2;
private _dz = (_aimASL select 2) - (_pos select 2);
private _range = _st get "range";
private _inRange = _d2 <= _range;
private _fired = _st get "fired";

// THE NOSE: the heading onto the aim, the pitch onto the line of sight or
// the solution, the bank with the turn, the speed onto the run speed.
private _heading = _st get "heading";
private _turn = ((_pos getDir _aimASL) - _heading + PASS_HALF_TURN + PASS_FULL_TURN) mod PASS_FULL_TURN - PASS_HALF_TURN;
private _turnStep = ([PASS_TURN_RATE, PASS_HELI_TURN_RATE] select _heli) * _dt;
_heading = (_heading + ((_turn max (-_turnStep)) min _turnStep) + PASS_FULL_TURN) mod PASS_FULL_TURN;

private _pitch = _st get "pitch";
private _speed = _st get "speed";
if (_inRange && {(_st get "solvedAt") < 0 || CBA_missionTime - (_st get "solvedAt") >= PASS_AIM_EVERY}) then {
    _st set ["solution", [_pos, _speed, _aimASL, _st get "initSpeed", _st get "friction", _st get "ttl", _st get "kind"] call FUNC(passAim)];
    _st set ["solvedAt", CBA_missionTime];
};
private _wantPitch = [_dz atan2 _d2, _st get "solution"] select _inRange;
private _pitchDiff = _wantPitch - _pitch;
private _pitchStep = PASS_PITCH_RATE * _dt;
_pitch = ((_pitch + ((_pitchDiff max (-_pitchStep)) min _pitchStep)) max (-PASS_PITCH_LIMIT)) min PASS_PITCH_UP_MAX;

private _bankLimit = [PASS_BANK_LIMIT, PASS_HELI_BANK_LIMIT] select _heli;
private _wantBank = ((_turn * PASS_BANK_PER_DEG) max (-_bankLimit)) min _bankLimit;
private _bankStep = PASS_BANK_RATE * _dt;
private _bank = (_st get "bank") + (((_wantBank - (_st get "bank")) max (-_bankStep)) min _bankStep);

private _speedStep = PASS_ACCEL * _dt;
_speed = _speed + ((((_st get "runSpeed") - _speed) max (-_speedStep)) min _speedStep);

private _dir = [(sin _heading) * cos _pitch, (cos _heading) * cos _pitch, sin _pitch];
private _right = [cos _heading, -(sin _heading), 0];
private _up = ([-(sin _heading) * sin _pitch, -(cos _heading) * sin _pitch, cos _pitch] vectorMultiply cos _bank) vectorAdd (_right vectorMultiply sin _bank);
private _vel = _dir vectorMultiply _speed;
private _newPos = _pos vectorAdd (_vel vectorMultiply _dt);

// BROKEN OFF: the ground ahead, the pitch, the aim behind the nose.
private _ahead = _newPos vectorAdd (_vel vectorMultiply PASS_LOOK_AHEAD_S);
private _floor = ((getTerrainHeightASL _ahead) max BOMB_SEA_Z) + ([PASS_FLOOR_PLANE, PASS_FLOOR_HELI] select _heli);
if ((_ahead select 2) < _floor) exitWith {
    [_veh, format ["pulled out %1 m over the ground", round ((_pos select 2) - (getTerrainHeightASL _pos))]] call FUNC(passEnd);
};
if (_pitch <= -PASS_PITCH_LIMIT) exitWith {[_veh, "the dive went vertical"] call FUNC(passEnd)};
if (_inRange && (_dir vectorDotProduct _to2) < 0) exitWith {
    [_veh, "past the aim", [PASS_MISSED, PASS_FIRED] select (_fired > 0)] call FUNC(passEnd);
};

_veh setVelocityTransformation [_newPos, _newPos, _vel, _vel, _dir, _dir, _up, _up, 1];
_veh setVelocity _vel;
{_st set _x} forEach [["heading", _heading], ["pitch", _pitch], ["bank", _bank], ["speed", _speed]];

// THE TRIGGER.
private _aligned = _inRange && abs _turn < PASS_AIM_TOL && abs _pitchDiff < PASS_AIM_TOL;
if !(_st get "ready") exitWith {
    if (!_aligned) exitWith {_st set ["alignedAt", -1]};
    if ((_st get "alignedAt") < 0) exitWith {_st set ["alignedAt", CBA_missionTime]};
    if (CBA_missionTime - (_st get "alignedAt") < PASS_SETTLE_S) exitWith {};
    _st set ["ready", true];
    _st set ["burstAt", CBA_missionTime];
    INFO_4("pass: '%1' on the solution - %2 m slant, pitch %3, %4 m up",typeOf _veh,round (_pos distance _aimASL),round _pitch,round ((_pos select 2) - (getTerrainHeightASL _pos)));
};

private _held = _inRange && abs _turn < PASS_HOLD_TOL && abs _pitchDiff < PASS_HOLD_TOL;
if (!_held) exitWith {[_veh, "drifted off the solution"] call FUNC(passEnd)};

private _salvo = _st get "salvo";
private _pulls = _st get "pulls";
if (_salvo > 0 && _fired >= _salvo) exitWith {[_veh, "salvo complete"] call FUNC(passEnd)};
if (_salvo < 0 && CBA_missionTime - (_st get "burstAt") >= (_st get "burst")) exitWith {
    [_veh, "burst complete", [PASS_DRY, PASS_FIRED] select (_fired > 0)] call FUNC(passEnd);
};
if (_salvo > 0 && _pulls >= _salvo + PASS_PULL_EXTRA) exitWith {
    [_veh, "the store would not fire any more", [PASS_DRY, PASS_FIRED] select (_fired > 0)] call FUNC(passEnd);
};
// A pull with no round out: the engine's own fireAtTarget, once.
if (_pulls > 0 && _fired isEqualTo 0 && !(_st get "checked") && CBA_missionTime - (_st get "lastPull") >= PASS_FIRE_CHECK_S) then {
    _st set ["checked", true];
    WARNING_2("pass: '%1' pulled %2 and nothing came out - trying fireAtTarget",typeOf _veh,_st get "weapon");
    _veh fireAtTarget [_dummy, _st get "weapon"];
};
if (CBA_missionTime >= (_st get "nextPull")) then {
    [_veh, _st get "weapon", _st get "turret"] call FUNC(fireAt);
    _st set ["pulls", _pulls + 1];
    _st set ["lastPull", CBA_missionTime];
    _st set ["nextPull", CBA_missionTime + (_st get "gap")];
};
