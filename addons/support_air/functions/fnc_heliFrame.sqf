#include "script_component.hpp"
/*
 * Author: YonV
 * One frame of this addon's flight control on a helicopter (FUNC(heliTake)):
 * the approach to the hover point, the hover, the descent onto the pad and
 * the settle on the ground. Velocity only - the airframe is moved by
 * setVelocityTransformation to where its new velocity takes it this frame, so
 * the men aboard ride it; the limits are script_component.hpp's HELI_
 * defines. The phase is in QGVAR(flight) on the airframe.
 *
 * POSITIONS ARE PositionASL - getPosASL, the airframe's own placing point
 * (its wheels), which is the format setVelocityTransformation takes. Fed
 * getPosWorld, the model centre, it put the airframe the centre's height over
 * the wheels - 2.5 m on a UH-80 - higher than meant EVERY FRAME: 130 m/s
 * straight up with the horizontal track and the wanted vz both reading right
 * (user, 2026-11-06: "launches into the air"; RPT 11:54: 53 m over the
 * terrain, then 733, 1364, 2090 at vz -4).
 *
 *   approach   towards the point at HELI_GAIN of the distance a second, no
 *              faster than the cap, held HELI_CLEARANCE m over whatever is
 *              HELI_LOOK_AHEAD_S s ahead - easing to the point's own height
 *              inside HELI_SLOW_RING m - and slowed while below that. There
 *              (HELI_HOVER_RING, HELI_HOVER_BAND): hover, or land
 *   hover      held on the point
 *   land       held over the pad, coming down at HELI_LAND_GAIN of the height
 *              over what is under it a second, between HELI_TOUCH_VZ and
 *              HELI_LAND_DESCENT_MAX m/s; touching the ground or under
 *              HELI_TOUCH_HEIGHT m: down
 *   down       the velocity damped for HELI_SETTLE_S s with a push into the
 *              ground, then the engine as asked. Engine off: handed back
 *              (FUNC(heliRelease)). Engine on: held there, damped and pushed
 *              down every frame, until the next order or take releases it -
 *              handed back with its engine running, the AI flew it straight
 *              back up to a hover (2026-11-06)
 *
 * On a landing the pilot orders the gear down every HELI_GEAR_S s from inside
 * HELI_SLOW_RING m of the pad.
 *
 * The nose turns to the point while it moves and holds otherwise; the pitch
 * and bank follow the speed and the acceleration within their limits. Lost
 * the airframe (dead, not the server's, a player at the controls, no pilot,
 * cannot move): handed back where it is.
 *
 * Arguments:
 * 0: [helicopter] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(heliFrame), 0, [_veh]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params ["_veh"];

private _st = _veh getVariable [QGVAR(flight), createHashMap];
if (count _st isEqualTo 0) exitWith {[_handle] call CBA_fnc_removePerFrameHandler};
private _pilot = driver _veh;
if (!alive _veh || !local _veh || isNull _pilot || !alive _pilot || isPlayer _pilot || !canMove _veh) exitWith {
    [_veh, "lost the airframe"] call FUNC(heliRelease);
};

private _dt = (diag_deltaTime min HELI_FRAME_MAX) max HELI_FRAME_MIN;
private _phase = _st get "phase";
// getPosASL, never getPosWorld: the point setVelocityTransformation places (see
// the header). It is also the wheels, so the height over the pad below is the
// wheels' height and the touchdown test reads true when they are down.
private _pos = getPosASL _veh;
private _vel = velocity _veh;
// THE ENGINE PUSHES IT ABOUT (user, 2026-11-08: the VTOL "never landed" -
// hanging 9 to 27 m off the pad for two minutes - and the Chinook held 154 m
// over its pad for 30 s while told down at 4 m/s): the flight control flies
// every airframe from where IT put it last frame, and at the speed it gave,
// not from where the rotor's or the engines' thrust moved it since. Knocked
// further than HELI_HOLD_SNAP m - a collision - it starts again from where it
// is.
private _sim = _st getOrDefault ["simPos", []];
if (_sim isNotEqualTo [] && {(_sim distance _pos) < HELI_HOLD_SNAP}) then {
    _pos = _sim;
    _vel = _st getOrDefault ["simVel", _vel];
};

// ON THE GROUND: settled, then the engine as asked.
//
// ENGINE OFF: handed back - an airframe with its engine off stays down.
// ENGINE ON (a pickup, a drop): HELD DOWN until the next order (FUNC(heliOrder))
// or take (FUNC(heliTake)) releases it (user, 2026-11-06: "did not land ...
// hovered at 10 m" - RPT 13:55:05: down, handed back, and the AI pilot, engine
// running and nothing told to stay, lifted it straight back to a hover). The
// push into the ground and the damping go on every frame; the AI's collective
// never gets a frame to climb on.
if (_phase isEqualTo HELI_PHASE_DOWN) exitWith {
    _veh setVelocity [(_vel select 0) * HELI_SETTLE_DAMP, (_vel select 1) * HELI_SETTLE_DAMP, (_vel select 2) min HELI_SETTLE_PUSH];
    if (CBA_missionTime - (_st get "since") < HELI_SETTLE_S) exitWith {};
    if !(_st get "engine") exitWith {
        _veh engineOn false;
        [_veh, "landed"] call FUNC(heliRelease);
    };
    if (_st getOrDefault ["holding", false]) exitWith {};
    _st set ["holding", true];
    _veh engineOn true;
    INFO_2("heliFrame: '%1' down at %2 - engine running, held on the ground until the next order",typeOf _veh,mapGridPosition _veh);
};

// THE GEAR, DOWN AND KEPT DOWN on a landing, from inside HELI_SLOW_RING m of
// the pad: ordered by the pilot every HELI_GEAR_S s (2026-11-06: "never put
// gear down" - one order at the take was all it got, and the AI, flying as far
// as it knows, folds the gear again). An order to a gear already down, or to
// a fixed one, does nothing.
if ((_st get "land") && {CBA_missionTime - (_st getOrDefault ["gearAt", -HELI_GEAR_S]) >= HELI_GEAR_S}) then {
    private _goalNow = _st get "goal";
    if ((_pos distance2D _goalNow) < HELI_SLOW_RING) then {
        _st set ["gearAt", CBA_missionTime];
        _pilot action ["LandGear", _veh];
    };
};

private _goal = _st get "goal";
private _ignore = _st get "ignore";
private _toGoal = [(_goal select 0) - (_pos select 0), (_goal select 1) - (_pos select 1), 0];
private _d2 = vectorMagnitude _toGoal;

// The surface at a point: the highest thing a scan down from the height given
// finds, else the terrain or the sea.
// NOT ITS OWN CREW (2026-11-05, the user's run 20:52: it climbed away over the
// pickup for 120 s): the scan ignores the airframe but the engine returns a
// vehicle's crew as objects of their own, so a door gunner at the airframe's
// own height read as the ground under it, the floor rose with it, and it
// climbed. Hits on the crew, on anything attached to it and on the load are
// skipped; the first other hit is the surface.
private _crew = crew _veh;
private _fnc_surface = {
    params ["_sx", "_sy", "_from"];
    private _terrain = (getTerrainHeightASL [_sx, _sy]) max HELI_SEA_Z;
    private _hits = lineIntersectsSurfaces [[_sx, _sy, _from], [_sx, _sy, (_pos select 2) - HELI_SCAN], _veh, _ignore, true, HELI_SCAN_HITS, "GEOM", "FIRE"];
    private _hit = _hits findIf {
        private _obj = _x select 2;
        !(_obj in _crew) && {(attachedTo _obj) isNotEqualTo _veh} && {(vehicle _obj) isNotEqualTo _veh}
    };
    // Nothing hit: the terrain. (The name for the log is only read when
    // there is a hit - an array literal evaluates both of its halves.)
    if (_hit < 0) exitWith {
        _st set ["hit", ""];
        _terrain
    };
    _st set ["hit", str ((_hits select _hit) select 2)];
    ((_hits select _hit) select 0) select 2
};

// COMING DOWN: how high over what is under it, and the touchdown.
private _over = -1;
if (_phase isEqualTo HELI_PHASE_LAND) then {
    _over = (_pos select 2) - ([_pos select 0, _pos select 1, (_pos select 2) + HELI_SCAN_BODY] call _fnc_surface);
};
if (_phase isEqualTo HELI_PHASE_LAND && {isTouchingGround _veh || _over < HELI_TOUCH_HEIGHT}) exitWith {
    _st set ["phase", HELI_PHASE_DOWN];
    _st set ["since", CBA_missionTime];
    _veh setVelocity [(_vel select 0) * HELI_SETTLE_DAMP, (_vel select 1) * HELI_SETTLE_DAMP, (_vel select 2) min HELI_SETTLE_PUSH];
};

// WANTED VELOCITY. Across: to the point, HELI_GAIN of the distance a second,
// capped. Up: to the wanted height at HELI_GAIN_Z, within the climb and the
// descent - the point's height, or the floor over what is ahead while that is
// higher; coming down, the landing rate by the height over the pad.
private _want = [0, 0, 0];
// LEVEL BRAKING (user, 2026-11-08: "do not ... gain alt to slow down"): never
// faster than a stop at HELI_BRAKE over what is left - the speed it was taken
// at bleeds off along the way in, the height held.
if (_d2 > HELI_NO_DISTANCE) then {_want = _toGoal vectorMultiply ((((HELI_GAIN * _d2) min sqrt (2 * HELI_BRAKE * _d2)) min (_st get "cap")) / _d2)};
private _vz = 0;
private _floor = -1;
if (_phase isEqualTo HELI_PHASE_LAND) then {
    _vz = -(((_over * HELI_LAND_GAIN) max HELI_TOUCH_VZ) min HELI_LAND_DESCENT_MAX);
} else {
    private _ahead = _pos vectorAdd (_vel vectorMultiply HELI_LOOK_AHEAD_S);
    private _ease = ((_d2 / HELI_SLOW_RING) min 1) max 0;
    // The clearance eases away to the goal's own height; what hangs below
    // the airframe (a sling load) never does - it must clear the ground
    // right up to the point.
    _floor = ([_ahead select 0, _ahead select 1, (_pos select 2) + HELI_SCAN_UP] call _fnc_surface) + HELI_CLEARANCE * _ease + (_st getOrDefault ["hang", 0]);
    private _wantZ = (_goal select 2) max _floor;
    private _below = _floor - (_pos select 2);
    if (_below > 0) then {
        _want = _want vectorMultiply (((1 - _below / HELI_CLEARANCE) max HELI_SLOW_SHARE) min 1);
    };
    // A VTOL glides down from its cruise as fast as its ground speed allows
    // (user, 2026-11-08: "vtol landing for pick up was way to slow").
    private _descent = HELI_DESCENT_MAX;
    if (_st getOrDefault ["vtol", false]) then {
        _descent = VTOL_DESCENT_SLOW max ((vectorMagnitude [_vel select 0, _vel select 1, 0]) * VTOL_GLIDE min VTOL_DESCENT_MAX);
    };
    _vz = (((_wantZ - (_pos select 2)) * HELI_GAIN_Z) max (-_descent)) min HELI_CLIMB_MAX;
    // ON A GLIDE PATH, NOT OVER THE POINT AND THEN DOWN (the same RPT: 160 m
    // out at 309 m, overflying and circling the pad for a minute): never
    // faster across the ground than gets it there as it gets down.
    private _high = (_pos select 2) - _wantZ;
    if (_high > HELI_HOVER_BAND) then {
        private _most = _d2 * _descent / _high;
        private _across = vectorMagnitude _want;
        if (_across > _most) then {_want = _want vectorMultiply (_most / _across)};
    };
};
_want set [2, _vz];

// ONE LINE EVERY HELI_LOG_S while it holds the airframe (2026-11-05: the RPT
// could not say why it climbed): where it is against the goal and the floor,
// over the terrain, and what the scan hit.
if (CBA_missionTime - (_st getOrDefault ["loggedAt", -HELI_LOG_S]) >= HELI_LOG_S) then {
    _st set ["loggedAt", CBA_missionTime];
    private _ground = (getTerrainHeightASL _pos) max HELI_SEA_Z;
    private _floorWord = ["-", str (round (_floor - _ground))] select (_floor >= 0);
    INFO_8("heliFrame: '%1' %2 - %3 m out, %4 m over the terrain, goal %5 m, floor %6 m, vz %7 m/s, hit '%8'",typeOf _veh,_phase,round _d2,round ((_pos select 2) - _ground),round ((_goal select 2) - _ground),_floorWord,round _vz,_st getOrDefault [ARR_2("hit","")]);
};

// THE CHANGE THIS FRAME, within HELI_ACCEL.
private _dv = _want vectorDiff _vel;
private _dvMax = HELI_ACCEL * _dt;
private _dvMag = vectorMagnitude _dv;
if (_dvMag > _dvMax) then {_dv = _dv vectorMultiply (_dvMax / _dvMag)};
private _newVel = _vel vectorAdd _dv;
private _accel = _dv vectorMultiply (1 / _dt);

// THERE: the hover, or on down.
if (_phase isEqualTo HELI_PHASE_APPROACH && _d2 < HELI_HOVER_RING && abs ((_pos select 2) - (_goal select 2)) < HELI_HOVER_BAND) then {
    _st set ["phase", [HELI_PHASE_HOVER, HELI_PHASE_LAND] select (_st get "land")];
    _st set ["since", CBA_missionTime];
};

// THE NOSE: to the point while it moves, else held; HELI_YAW_RATE at most.
private _heading = _st get "heading";
private _speed = vectorMagnitude [_newVel select 0, _newVel select 1, 0];
if (_speed > HELI_TURN_SPEED && _d2 > HELI_TURN_DIST) then {
    private _turn = ((_pos getDir _goal) - _heading + HELI_HALF_TURN + HELI_FULL_TURN) mod HELI_FULL_TURN - HELI_HALF_TURN;
    private _most = HELI_YAW_RATE * _dt;
    _heading = (_heading + ((_turn max (-_most)) min _most) + HELI_FULL_TURN) mod HELI_FULL_TURN;
};
// PITCH AND BANK from the speed and the acceleration in the airframe's frame,
// followed at HELI_ATTITUDE_RATE.
private _fwd = [sin _heading, cos _heading, 0];
private _right = [cos _heading, -(sin _heading), 0];
private _wantPitch = ((-(_speed * HELI_PITCH_PER_SPEED) - (_accel vectorDotProduct _fwd) * HELI_PITCH_PER_ACCEL) max (-HELI_PITCH_LIMIT)) min HELI_PITCH_LIMIT;
private _wantBank = (((_accel vectorDotProduct _right) * HELI_BANK_PER_ACCEL) max (-HELI_BANK_LIMIT)) min HELI_BANK_LIMIT;
private _blend = (HELI_ATTITUDE_RATE * _dt) min 1;
private _pitch = (_st get "pitch") + (_wantPitch - (_st get "pitch")) * _blend;
private _bank = (_st get "bank") + (_wantBank - (_st get "bank")) * _blend;
private _dir = [(sin _heading) * cos _pitch, (cos _heading) * cos _pitch, sin _pitch];
private _up = ([-(sin _heading) * sin _pitch, -(cos _heading) * sin _pitch, cos _pitch] vectorMultiply cos _bank) vectorAdd (_right vectorMultiply sin _bank);

// COMMIT: where the new velocity takes it this frame, at that velocity.
private _newPos = _pos vectorAdd (_newVel vectorMultiply _dt);
_veh setVelocityTransformation [_newPos, _newPos, _newVel, _newVel, _dir, _dir, _up, _up, HELI_STATE_NOW];
_veh setVelocity _newVel;
_st set ["simPos", _newPos];
_st set ["simVel", _newVel];
_st set ["heading", _heading];
_st set ["pitch", _pitch];
_st set ["bank", _bank];
