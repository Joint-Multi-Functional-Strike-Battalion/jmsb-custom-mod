#include "script_component.hpp"
/*
 * Author: JMSB
 * Launches one cruise missile and flies it to the target.
 *
 * A REAL PROJECTILE THE WHOLE WAY. The missile ammo class itself leaves the
 * launcher at the module's position and is steered every tick: straight up
 * off the rail, then along route points every CM_LEG metres on the track to
 * the target, terrain-following at the cruise altitude (it climbs for the
 * ground CM_LOOKAHEAD seconds ahead, not the ground it is over). Inside
 * CM_TERMINAL it pops up, and inside CM_DIVE it dives onto the target.
 *
 * IT CAN BE SHOT DOWN. Anything that kills the projectile - the air defence
 * intercept, which this reports it to (FUNC(threat)), or an active protection
 * system that sees it coming (it is a MissileCore in the world, like any
 * other) - ends it, and it is counted as lost. Its own timeToLive ending is
 * the same: out of fuel. The first missile of a salvo to come within
 * SPLASH_LEAD seconds of the target calls SPLASH.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Target position, ATL <ARRAY>
 * 2: Mission token <NUMBER>
 *
 * Return Value: None
 *
 * Example:
 * [_logic, _pos, 1] call jmfsb_support_fires_fnc_flyCruise
 *
 * Public: No
 */

params ["_logic", "_target", "_token"];

if (isNull _logic || {(_logic getVariable [QGVAR(token), -1]) isNotEqualTo _token}) exitWith {};

private _left = _logic getVariable [QGVAR(left), 0];
if (_left < 1) exitWith {[_logic, _token] call FUNC(sortieDone)};
_logic setVariable [QGVAR(left), _left - 1, true];
// Counted for the per-missile cooldown (FUNC(finish)).
_logic setVariable [QGVAR(fired), (_logic getVariable [QGVAR(fired), 0]) + 1];

private _cls = _logic getVariable [QGVAR(cls), CM_CLASS_DEF];
private _warhead = _logic getVariable [QGVAR(warhead), ""];
private _speed = _logic getVariable [QGVAR(speed), 250];

private _from = getPosASL _logic;
_from set [2, ((getTerrainHeightASL _from) max 0) + CM_RAIL_HEIGHT];
private _tgt = AGLToASL [_target select 0, _target select 1, 0];

// The track, as route points every CM_LEG metres up to the terminal ring.
private _route = [];
private _bearing = _from getDir _tgt;
for "_s" from CM_LEG to ((_from distance2D _tgt) - CM_TERMINAL) step CM_LEG do {
    _route pushBack (_from getPos [_s, _bearing]);
};

// A submunition warhead opens at its own trigger distance, not on the target.
private _fuze = CM_FUZE;
if (_warhead isNotEqualTo "" && {_warhead isKindOf ["SubmunitionCore", configFile >> "CfgAmmo"]}) then {
    _fuze = _fuze max getNumber (configFile >> "CfgAmmo" >> _warhead >> "triggerDistance");
};

private _missile = createVehicle [_cls, ASLToAGL _from, [], 0, "CAN_COLLIDE"];
if (isNull _missile) exitWith {
    WARNING_1("'%1' could not be created - missile not launched",_cls);
    [_logic, _token, "misfire"] call FUNC(sortieDone);
};
_missile setPosASL _from;
_missile setVectorDirAndUp [[0, 0, 1], [0, 1, 0]];
_missile setVelocity [0, 0, CM_BOOST_SPEED];

[QGVAR(say), [_logic, "missile away", "normal"]] call CBA_fnc_globalEvent;

[{
    params ["_args", "_handle"];
    _args params ["_m", "_logic", "_route", "_tgt", "_speed", "_alt", "_warhead", "_fuze", "_boostUntil", "_side", "_token", "_reported"];

    if (isNull _m) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        [_logic, _token, "missile lost - shot down or hit short"] call FUNC(sortieDone);
    };

    if (CBA_missionTime < _boostUntil) exitWith {
        _m setVelocity [0, 0, CM_BOOST_SPEED];
    };

    private _p = getPosASL _m;
    private _d = _p vectorDistance _tgt;
    // A tick at cruise speed is longer than the fuze ring, so a missile the
    // next tick would find already in the ground is set off now - put on the
    // ring first, so it goes off where it would have.
    private _reach = _fuze + _speed * CM_TICK * FUZE_LOOKAHEAD_TICKS;
    if (_d <= _reach || {(_p select 2) <= ((getTerrainHeightASL _p) max 0) + 1}) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        if (_d > _fuze && _d <= _reach) then {
            _m setPosASL (_tgt vectorAdd ((_tgt vectorFromTo _p) vectorMultiply _fuze));
        };
        [_m, _warhead] call FUNC(detonate);
        [_logic, _token, format ["impact at grid %1", mapGridPosition ASLToAGL _tgt]] call FUNC(sortieDone);
    };

    if (!_reported && {_d / _speed <= CM_REPORT_TTI}) then {
        [_m, _side, _tgt] call FUNC(threat);
        _args set [11, true];
    };

    // SPLASH, once per salvo, from whichever missile gets there first.
    if (_d / _speed <= SPLASH_LEAD && {(_logic getVariable [QGVAR(splashed), -1]) isNotEqualTo _token}) then {
        _logic setVariable [QGVAR(splashed), _token];
        [QGVAR(say), [_logic, format ["splash grid %1, over", mapGridPosition ASLToAGL _tgt], "high"]] call CBA_fnc_globalEvent;
    };

    private _d2 = _p distance2D _tgt;
    private _turn = CM_TURN;
    private _want = switch (true) do {
        case (_d2 <= CM_DIVE): {
            _turn = CM_TURN_TERMINAL;
            _p vectorFromTo _tgt
        };
        case (_d2 <= CM_TERMINAL): {
            _turn = CM_TURN_TERMINAL;
            _p vectorFromTo [_tgt select 0, _tgt select 1, (_tgt select 2) + _alt + CM_POPUP]
        };
        default {
            // route points already reached fall off the front of the track
            while {_route isNotEqualTo [] && {(_p distance2D (_route select 0)) < CM_LEG / 2}} do {
                _route deleteAt 0;
            };
            private _wp = _route param [0, _tgt];
            private _flat = _p vectorFromTo [_wp select 0, _wp select 1, _p select 2];
            private _ahead = _p vectorAdd (_flat vectorMultiply (_speed * CM_LOOKAHEAD));
            private _floor = (getTerrainHeightASL _p) max (getTerrainHeightASL _ahead) max 0;
            private _climb = (((_floor + _alt) - (_p select 2)) / (_speed * CM_LOOKAHEAD)) max -0.5 min 0.5;
            vectorNormalized [_flat select 0, _flat select 1, _climb]
        };
    };

    private _cur = vectorNormalized (velocity _m);
    if (_cur isEqualTo [0, 0, 0]) then {_cur = _want};
    private _dir = vectorNormalized (_cur vectorAdd (_want vectorMultiply (_turn * CM_TICK)));

    _m setVectorDir _dir;
    _m setVelocity (_dir vectorMultiply _speed);
}, CM_TICK, [
    _missile, _logic, _route, _tgt, _speed, _logic getVariable [QGVAR(altitude), 60], _warhead, _fuze,
    CBA_missionTime + CM_BOOST_TIME, _logic getVariable [QGVAR(side), west], _token, false
]] call CBA_fnc_addPerFrameHandler;
