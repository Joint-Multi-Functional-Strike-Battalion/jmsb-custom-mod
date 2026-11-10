#include "script_component.hpp"
/*
 * Author: YonV
 * Decides what every commander gets and where, then builds it.
 *
 * WHERE IS NEVER ASKED FOR. Each commander's own TAOR and its own objectives
 * are read from ALiVE; a mission maker tunes how many and how open the ground
 * has to be, never which ground.
 *
 * WHAT depends on how the commander fights, also read from ALiVE:
 *   invasion / occupation - a radar cueing launchers set back from it
 *   asymmetric            - men with MANPADS, spread over its objectives
 *
 * WITHOUT ALiVE (user, 2026-11-02: "works with or without") the mission
 * answers the same questions: every side with ground of its own - the
 * module's TAOR field for it, or its jmfsb_taor_<side> markers
 * (EFUNC(common,groundFor)) - is a conventional commander, its faction is the
 * one its men on the map wear (EFUNC(common,sideFaction)) and its objectives
 * are the towns on that ground (EFUNC(common,settlements)). No ground drawn
 * for anyone: the mission's enemy over the whole map, clear of the players'
 * start (AD_FALLBACK_CLEAR).
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Example:
 * [] call jmfsb_airdefence_fnc_plan
 */

if (!isServer) exitWith {};

// A side's ground: the module's own TAOR field when the mission set one, its
// ALiVE commander placements (or, without ALiVE, its jmfsb_taor markers)
// otherwise.
private _fnc_ground = {
    params ["_s"];
    private _set = if (isNil QGVAR(taors)) then {[]} else {
        GVAR(taors) getOrDefault [str _s, []]
    };
    if (_set isNotEqualTo []) exitWith {[+_set, []]};
    [_s] call EFUNC(common,groundFor)
};

// ALiVE loaded with no commanders is not loaded (user, 2026-11-02).
private _withAlive = !isNil QEFUNC(adapter_alive,commanders) && {[] call EFUNC(common,aliveLoaded)};
private _cmds = [];
private _wholeMap = false;
if (_withAlive) then {
    _cmds = call EFUNC(adapter_alive,commanders);
} else {
    {
        if ((([_x] call _fnc_ground) select 0) isNotEqualTo []) then {
            _cmds pushBack [_x, AD_FALLBACK_CTYPE, [_x] call EFUNC(common,sideFaction)];
        };
    } forEach [west, east, independent];
    if (_cmds isEqualTo []) then {
        private _enemy = call EFUNC(common,enemySide);
        _cmds pushBack [_enemy, AD_FALLBACK_CTYPE, [_enemy] call EFUNC(common,sideFaction)];
        _wholeMap = true;
    };
    INFO_2("no ALiVE - air defence for %1 from the mission's own ground (whole map: %2)",_cmds apply {_x select 0},_wholeMap);
};
if (_cmds isEqualTo []) exitWith {
    INFO("no ALiVE commanders - nothing to defend");
};

private _placed = [];

// EVERY INVADING OR DEFENDING SIDE GETS ITS AIR DEFENCE (user, 2026-10-13:
// "be for all invade or defend sides"). It used to be built only for sides
// hostile to the players, after BLUFOR SAMs beside BLUFOR squads were reported
// as wrong; now a conventional commander - invasion or occupation - gets its
// batteries whoever it fights for, and the players' own side is defended too.
// An asymmetric commander friendly to the players still gets no MANPAD teams:
// it is neither invading nor defending.
private _mine = call EFUNC(common,playerSides);

{
    _x params ["_side", "_ctype", "_faction"];

    if (
        !(_ctype in AD_CONVENTIONAL)
        && {_mine isNotEqualTo []}
        && {(_mine findIf {_side getFriend _x >= 0.6}) > -1}
    ) then {
        INFO_1("side %1 is asymmetric and friendly to the players - no MANPAD teams built for it",_side);
        continue;
    };

    ([_side] call _fnc_ground) params ["_taor", "_black"];

    // OTHER SIDES' GROUND IS OFF LIMITS - TO A SIDE THAT DECLARED NONE OF ITS
    // OWN. A side with no TAOR reads as "the whole map", which is how one
    // side's hardware ends up standing inside another's area. EVERY side is
    // asked, not just the ones with commanders: the players' side usually has
    // no commander module, and its TAOR being invisible here is exactly how
    // east hardware turned up on west ground.
    //
    // A side that DID declare one keeps it whole - TAORs may overlap and on an
    // insurgency they are meant to, so subtracting the players' ground from
    // the insurgents' left them nowhere to put a battery. Same rule, same
    // words, as EFUNC(common,taorGate).
    if (_taor isEqualTo []) then {
        private _foreign = [];
        {
            if (_x isEqualTo _side) then {continue};
            _foreign append (([_x] call _fnc_ground) select 0);
        } forEach [west, east, independent];
        {
            if !(_x in _taor) then { _black pushBackUnique _x };
        } forEach _foreign;
    };

    private _objs = [];
    if (_withAlive) then {
        _objs = [_side] call EFUNC(adapter_alive,objectivesFor);
    } else {
        // The towns on this side's ground, as objectives: [id, pos, size, type].
        // On the whole map, none near a player-side man - that is their base.
        private _playerMen = (allPlayers + playableUnits) select {(side group _x) in _mine};
        {
            _x params ["_cpos", "_csize"];
            if (_taor isNotEqualTo [] && {(_taor findIf {_cpos inArea _x}) < 0}) then {continue};
            if ((_black findIf {_cpos inArea _x}) > -1) then {continue};
            if (_wholeMap && {(_playerMen findIf {(_x distance2D _cpos) < AD_FALLBACK_CLEAR}) > -1}) then {continue};
            _objs pushBack [format ["town_%1", mapGridPosition _cpos], _cpos, _csize, "settlement"];
        } forEach (call EFUNC(common,settlements));
    };
    if (_objs isEqualTo []) then {
        INFO_1("side %1 holds no objectives - no air defence",_side);
        continue;
    };

    // Biggest first: the ground worth holding is the ground worth covering.
    private _ranked = _objs apply { [-(_x select 2), _x] };
    _ranked sort true;
    _objs = _ranked apply { _x select 1 };

    private _kit = [_faction, _side] call FUNC(sideKit);

    if (_ctype in AD_CONVENTIONAL) then {
        [_side, _objs, _taor, _black, _kit, _placed, _faction] call FUNC(planBatteries);
    } else {
        [_side, _objs, _taor, _black, _kit, _faction] call FUNC(planManpads);
    };
} forEach _cmds;

INFO_2("%1 battery site(s), %2 MANPAD team(s)",count GVAR(sites),count GVAR(teams));
