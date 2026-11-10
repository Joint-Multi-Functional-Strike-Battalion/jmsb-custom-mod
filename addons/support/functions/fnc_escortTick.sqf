#include "script_component.hpp"
/*
 * Author: YonV
 * The watch on one lead's drone escorts, every ESCORT_TICK seconds
 * (FUNC(escort); DESIGN_SUPPORT_MESSAGING 1.2, user, 2026-11-01: "cover,
 * engage, flares, defend and protect").
 *
 * FLY WITH IT. Each escort keeps station on its wing slot - beside and behind
 * the lead, aimed ESCORT_LEAD_TIME of its speed ahead - so it flies the lead's
 * route, its off-map hold and its way home. It is steered at a point along the
 * lead's heading beyond the slot and paced by a speed cap that follows the
 * lead and closes the gap (2026-11-06: re-sent to the slot itself, the AI
 * braked for it every tick and fell behind). A lead that is holding (landed,
 * hovering, on its stand) is orbited instead.
 * The height stays the escort's own stacked one (FUNC(flyAt) at the start).
 *
 * NEVER ACROSS (2026-11-05, the user's RPT 16:23: the two MQ-8Bs with RAVEN
 * flew into each other). The left slots go to the escorts furthest left of
 * the lead's heading, whichever they are, so none crosses over the lead to
 * swap sides; an orbiting escort is aimed ESCORT_ORBIT_STEP degrees on round
 * the lead from where it is, all the same way round, so it keeps its own
 * pace and side - the old slot stepped round on its own, outran the drones
 * and drew both through the middle at one height.
 *
 * ENGAGE WHAT THREATENS IT. First whoever fired a missile at the lead or an
 * escort (FUNC(escortMissile)); else the nearest enemy the lead's pilot or the
 * escorts know round the lead, the task point or the lead's next waypoint.
 * The escort is revealed it, let loose (RED, COMBAT) and sent at it - a rotary
 * drone to a standoff, a fixed-wing one over it for its own passes - but never
 * further than its leash from the lead: there it breaks off and comes back.
 * With nothing to hit it flies its slot weapons free (YELLOW).
 *
 * ALL ATTACK (user, 2026-11-02; FUNC(escortAttack)): while the lead's escorts
 * are sent at a target area, those still armed fly that attack
 * (FUNC(escortStrike)) and only the rest fly with the lead.
 *
 * FLARES, THE BACKSTOP. A missile of the other side inside ESCORT_MISSILE_SCAN
 * of the lead or an escort raises the same alarm IncomingMissile does, for
 * the shot whose handler did not fire here.
 *
 * THE END. Lead removed at the end of its sortie (home, or the provider's
 * FUNC(escortEnd)): the escorts go with it. Lead lost: they fly back to where
 * they were made and are removed there. A lost escort is not replaced; the
 * watch stops when none is left.
 *
 * Arguments:
 * 0: [lead, escorts, state] <ARRAY>
 * 1: PFH handle <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [FUNC(escortTick), ESCORT_TICK, [_lead, _escorts, _st]] call CBA_fnc_addPerFrameHandler
 *
 * Public: No
 */

params [["_args", [], [[]]], ["_handle", -1, [0]]];
_args params ["_lead", "_escorts", "_st"];

private _alive = _escorts select {alive _x};
// AN ESCORT DOWN is said in the lead's thread (user, 2026-11-05).
private _had = _st getOrDefault ["alive", count _escorts];
if (count _alive < _had && alive _lead) then {
    [EVENT_AIRCRAFT, [_lead, format [EVENT_ESCORT_DOWN, count _alive], true]] call CBA_fnc_localEvent;
};
_st set ["alive", count _alive];
if (_alive isEqualTo []) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
};

// THE SORTIE IS OVER and the lead was removed with it: so are they.
if (isNull _lead) exitWith {
    [_handle] call CBA_fnc_removePerFrameHandler;
    [objNull, _alive] call FUNC(escortEnd);
};

private _side = _st get "side";

// THE LEAD IS DOWN: home to where they were made, removed there.
if (!alive _lead) exitWith {
    private _home = _st get "home";
    if ((_st get "phase") isNotEqualTo "home") then {
        _st set ["phase", "home"];
        _st set ["homeBy", CBA_missionTime + ESCORT_HOME_TIME];
        INFO_1("escorts of '%1': the lead is down - going home",typeOf _lead);
        {
            private _grp = group effectiveCommander _x;
            _grp setCombatMode "YELLOW";
            _grp setSpeedMode "FULL";
            _x limitSpeed ESCORT_NO_SPEED_CAP;
            _x doMove _home;
        } forEach _alive;
    };
    private _late = CBA_missionTime > (_st get "homeBy");
    private _done = _alive select {_late || _x distance2D _home < ESCORT_HOME_RING};
    if (_done isNotEqualTo []) then {[objNull, _done] call FUNC(escortEnd)};
};

private _heli = _st get "heli";
private _wing = [ESCORT_WING_PLANE, ESCORT_WING_HELI] select _heli;
private _trail = [ESCORT_TRAIL_PLANE, ESCORT_TRAIL_HELI] select _heli;
private _orbit = [ESCORT_ORBIT_PLANE, ESCORT_ORBIT_HELI] select _heli;
private _cover = [ESCORT_COVER_PLANE, ESCORT_COVER_HELI] select _heli;
private _leash = [ESCORT_LEASH_PLANE, ESCORT_LEASH_HELI] select _heli;

// THE BACKSTOP: a missile of the other side near the lead or an escort.
{
    private _aircraft = _x;
    private _incoming = (_aircraft nearObjects [ESCORT_MISSILE_KIND, ESCORT_MISSILE_SCAN]) select {
        private _from = (getShotParents _x) param [0, objNull];
        !isNull _from && (_side getFriend (side _from)) < ESCORT_FRIEND_LIMIT
    };
    if (_incoming isNotEqualTo []) then {
        [_aircraft, (getShotParents (_incoming select 0)) select 0] call FUNC(escortMissile);
    };
} forEach ([_lead] + _alive);

// ALL ATTACK (user, 2026-11-02; FUNC(escortAttack)): the escorts the attack
// has this tick are on their targets (FUNC(escortStrike)); the rest - and all
// of them once it is over - fly with the lead below.
private _attack = _lead getVariable [QGVAR(escortAttack), createHashMap];
if (count _attack > 0) then {
    private _striking = [_lead, _alive, _attack] call FUNC(escortStrike);
    // On a target, not on station: the cap comes off.
    {_x limitSpeed ESCORT_NO_SPEED_CAP} forEach _striking;
    _alive = _alive - _striking;
};
if (_alive isEqualTo []) exitWith {};

// THE THREAT. The shooter first, while he lives and is inside the leash.
private _threat = objNull;
(_lead getVariable [QGVAR(escortShooter), [objNull, -1]]) params [["_shooter", objNull, [objNull]], ["_shotAt", -1, [0]]];
if (alive _shooter && CBA_missionTime - _shotAt < ESCORT_SHOOTER_TIME && _shooter distance2D _lead < _leash) then {
    _threat = _shooter;
};
if (isNull _threat) then {
    private _grp = group driver _lead;
    private _centres = [getPosATL _lead];
    private _point = _st get "point";
    if (_point isNotEqualTo []) then {_centres pushBack _point};
    if (!isNull _grp) then {
        private _next = waypointPosition [_grp, currentWaypoint _grp];
        if (_next isNotEqualTo [0, 0, 0]) then {_centres pushBack _next};
    };
    private _eyes = ([driver _lead] + (_alive apply {effectiveCommander _x})) select {alive _x};
    private _known = [];
    {
        private _centre = _x;
        {
            _known append (_x targets [true, _cover, [], ESCORT_KNOWN_AGE, _centre]);
        } forEach _eyes;
    } forEach _centres;
    _known = (_known arrayIntersect _known) select {alive _x};
    private _byRange = _known apply {[_x distance2D _lead, _x]};
    _byRange sort true;
    _threat = (_byRange param [0, [0, objNull]]) select 1;
};

// THE SLOTS: beside and behind a moving lead, round a holding one - never
// across it (2026-11-05). Left to right as they are now, so the left slots go
// to the escorts already on the left.
private _speed = speed _lead;
private _dir = getDir _lead;
private _holding = _speed < ESCORT_SLOW_SPEED;
private _ahead = _lead getPos [(_speed / ESCORT_KMH_PER_MS) * ESCORT_LEAD_TIME, _dir];
private _byLeft = _alive apply {[(_lead worldToModel (ASLToAGL getPosASL _x)) select 0, _x]};
_byLeft sort true;
_byLeft = _byLeft apply {_x select 1};
private _lefts = ceil (count _byLeft / 2);

{
    private _esc = _x;
    private _k = _byLeft find _esc;
    private _left = _k < _lefts;
    private _rank = [_k - _lefts + 1, _lefts - _k] select _left;
    private _grp = group effectiveCommander _esc;
    private _slot = if (_holding) then {
        _lead getPos [_orbit, (_lead getDir _esc) + ESCORT_ORBIT_STEP]
    } else {
        (_ahead getPos [_trail, _dir + 180]) getPos [_wing * _rank, _dir + 90 * ([1, -1] select _left)]
    };
    private _leashed = _esc distance2D _lead > _leash;

    if (!isNull _threat && !_leashed) then {
        _grp reveal [_threat, ESCORT_REVEAL];
        _grp setCombatMode "RED";
        _grp setBehaviour "COMBAT";
        _grp setSpeedMode "FULL";
        _esc limitSpeed ESCORT_NO_SPEED_CAP;
        {
            _x doTarget _threat;
            _x doFire _threat;
        } forEach ((crew _esc) select {alive _x});
        _esc doMove ([getPosATL _threat, _threat getPos [ESCORT_STANDOFF_HELI, _threat getDir _esc]] select _heli);
    } else {
        _grp setCombatMode "YELLOW";
        _grp setBehaviour "AWARE";
        if (_holding) exitWith {
            _grp setSpeedMode "NORMAL";
            _esc limitSpeed ESCORT_NO_SPEED_CAP;
            _esc doMove _slot;
        };
        // ON STATION: steered past the slot along the lead's heading, paced
        // by the cap - the lead's speed plus the gap to the slot along it.
        private _gap = (_slot vectorDiff (getPosATL _esc)) vectorDotProduct [sin _dir, cos _dir, 0];
        private _floor = _speed * ESCORT_SPEED_FLOOR;
        if (!_heli) then {
            _floor = _floor max (getNumber (configOf _esc >> "landingSpeed") * ESCORT_STALL_MARGIN);
        };
        _grp setSpeedMode "FULL";
        _esc limitSpeed ((_speed + _gap * ESCORT_CLOSE_GAIN) max _floor);
        _esc doMove (_slot getPos [(_speed / ESCORT_KMH_PER_MS) * ESCORT_STEER_TIME, _dir]);
    };
} forEach _alive;
