#include "script_component.hpp"
/*
 * Author: YonV
 * Puts each side's patrols over the ENEMY's objectives, as PROFILES.
 *
 * Reconnaissance flies where the enemy is. Every side used to orbit its own
 * ground, which meant west drones over west towns and east drones over east
 * ones - two air forces watching their own people and never meeting anybody.
 * A side's eyes belong over the ground it is trying to see into, and that is
 * also where its drones become something players have to deal with.
 *
 * The module can put them back over their own ground (overwatch) for missions
 * that want that, and a side with no enemy objectives on the map falls back
 * to its own rather than losing its air.
 *
 * A profiled drone is not a flying object - it is a record that walks the map
 * and becomes real only when players are near enough for ALiVE to spawn it.
 * That is the whole reason patrols are profiled rather than flown: an empty
 * map costs nothing, and the drone a section actually meets was always there.
 *
 * Arguments: None
 *
 * Return Value: None
 *
 * Public: No
 */


// THIS MODULE IS CALLED "ENEMY DRONES". It was arming every commander ALiVE
// reported, the players' own side included - the RPT shows nine WEST patrols
// and seven GUER ones up against a BLUFOR mission, which is where the blue
// drones the user photographed over the red TAOR came from. A side friendly to
// the players gets none.
private _mine = call EFUNC(common,playerSides);

// THE SIDES SOMEBODY DREW A PATROL FOR. This walked ALiVE's commander list and
// took each one's faction with it. The airframe is the module's own field now,
// and an empty one falls through to FUNC(factionUav) scanning by side - so the
// faction string this used to carry has nothing left to say.
//
// Shaped [side, "", faction] because the body below unpacks a commander entry
// and there was no reason to rewrite it around a different one.
private _sides = [];
{
    private _zSide = _x # 0;
    if ((_sides findIf {(_x # 0) isEqualTo _zSide}) < 0) then {
        _sides pushBack [_zSide, "", ""];
    };
} forEach (missionNamespace getVariable [QGVAR(zones), []]);

if (_sides isEqualTo []) exitWith {};


{
    _x params ["_side", "", "_faction"];

    if (_mine isNotEqualTo [] && {(_mine findIf {_side getFriend _x >= 0.6}) > -1}) then {
        if !(_side in GVAR(friendlySaid)) then {
            GVAR(friendlySaid) pushBack _side;
            INFO_1("%1 is friendly to the players - no enemy drones flown for it",_side);
        };
        continue;
    };

    // THE ZONES SOMEBODY PLACED FOR THIS SIDE. This was forty lines deciding
    // whether a side patrolled its own ALiVE objectives or its enemies', and
    // then gating every one of them through EFUNC(common,taorGate) because an
    // attacker's objective list reaches into enemy territory - green patrols
    // orbiting inside the red TAOR is what that looked like when a commander
    // declared no markers.
    //
    // A PLACED ZONE IS THE DECLARATION, so there is nothing left to decide and
    // nothing to gate. See FUNC(moduleDronePatrol).
    private _objs = [_side] call FUNC(zonesFor);

    // NOBODY THERE, NOTHING FLYING. A patrol exists to be met, and one
    // orbiting a base four kilometres from the nearest player is an airframe,
    // a crew and an AI pilot being simulated for an audience of nobody. The
    // ground is not given up - it is simply not patrolled until somebody is
    // close enough for the patrol to mean something, and FUNC(standDown)
    // takes them back when everybody leaves.
    private _all = count _objs;
    _objs = _objs select {[_x select 1] call FUNC(playerNear)};

    // Hoisted: a comma inside a macro argument reads as an argument separator.
    private _far = _all - (count _objs);
    if (_far > 0) then {
        INFO_3("%1: %2 of %3 objective(s) have no player within range - not patrolled",_side,_far,_all);
    };

    if (_objs isEqualTo []) then {continue};

    // EACH ZONE TO ITS OWN COUNT. This was one shared per-side ceiling filled a
    // drip at a time, with stand-down credits and a seeded first-fill, because
    // patrols were spread over a commander's whole objective list and had to be
    // rationed between them. One module is one patrol now: a zone asking for two
    // airframes gets two, and what another zone is doing is not its business.
    {
        _x params ["", "_pos", "", "_index", "_class", "_count"];

        // The supply cap, which only ever reduces - see FUNC(ceilingFor).
        _count = [_side, _count] call FUNC(ceilingFor);
        if (_count < 1) then {continue};

        // WHAT THIS ZONE ALREADY HAS. Counted off the tag FUNC(topUp) stamps,
        // not off the side ledger - two zones for one side are two patrols.
        private _have = count ((GVAR(patrols) getOrDefault [str _side, []]) select {
            !isNull _x && {alive _x} && {(_x getVariable [QGVAR(zone), -1]) isEqualTo _index}
        });

        for "_i" from 1 to (_count - _have) do {
            [_side, _faction, _pos, _class, _index] call FUNC(topUp);
        };
    } forEach _objs;

    // Hoisted: a comma inside a macro argument reads as an argument separator.
    private _up = [_side] call FUNC(livePatrols);
    INFO_2("side %1: %2 patrol(s) up",_side,_up);
} forEach _sides;
