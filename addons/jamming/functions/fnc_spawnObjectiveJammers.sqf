#include "script_component.hpp"
/*
 * Author: YonV
 * Jammer sites at each commander's objectives (new.md section 1.3).
 *
 * A data site at the biggest objectives and a radio site at the rest - the size
 * of the ground being guarded decides which service goes quiet around it. The
 * terminal IS the zone: hack it or destroy it and the zone dies immediately and
 * permanently, which is what makes it worth walking to. One GPS uplink on the
 * whole map, at the first commander's biggest objective.
 *
 * Every terminal joins the hacking tower pool through the jamming registry, so
 * they are hackable with no further wiring.
 *
 * IT IS SPREAD ACROSS FRAMES, and that is not a nicety. Placing every site in
 * one blocking loop froze the 14:48 run for 3m47s: thirty-one commanders on
 * that mission, eight sites each, and every site does a findSite search and a
 * createVehicle. The work is unchanged - it is drained a few per frame now, so
 * a big order of battle costs a longer wait instead of a dead server.
 *
 * The cost that actually caused that freeze was registering all 248 sites as
 * ALiVE objectives; that is gone, and only the uplink is registered - see
 * FUNC(spawnJammerSite). This is the belt to that braces: the search and the
 * spawn were always going to scale with the objective count, and nothing had
 * ever bounded them per frame.
 *
 * Arguments: None
 *
 * Return Value:
 * Sites QUEUED <NUMBER> - not placed. Placing finishes frames later, and the
 * drain logs the final count when it empties.
 *
 * Public: No
 */

if (!isServer) exitWith {0};
if (isNil QEFUNC(adapter_alive,commanders)) exitWith {0};

// ---------------------------------------------------------------- the plan --
// Built first, placed later. Deciding WHAT to build is cheap - it is reading
// objective lists - so it stays in one pass; building it is what gets drained.
private _jobs = [];
private _gpsDone = false;

{
    _x params ["_side"];

    private _objs = [_side] call EFUNC(adapter_alive,objectivesFor);
    if (_objs isEqualTo []) then {continue};

    // biggest first - those are the ones worth denying data over
    private _ranked = _objs apply { [-(_x select 2), _x] };
    _ranked sort true;
    _objs = _ranked apply { _x select 1 };

    // THE CAP IS THE REAL BOUND, not the share. A percentage has no ceiling: on
    // a map where a commander holds 173 objectives, 30% is 52 emitters. The
    // share still shapes a small map; the cap is what stops a big one - and on
    // a mission with thirty-one commanders the cap is the only thing there is.
    private _want = (ceil ((count _objs) * GVAR(objectiveShare) / 100)) min GVAR(maxPerSide);

    {
        if (_forEachIndex >= _want) exitWith {};
        _x params ["", "_pos", "_size"];

        // RADIO OR DATA, by size. The biggest objectives get the DATA site on
        // the larger radius, the rest RADIO on the smaller - the right way
        // round: a squad can shout to its neighbour long before it can raise
        // the TOC, so data should be denied over more ground than voice. A
        // player who can still talk but cannot send a report then knows which
        // of the two masts to go looking for.
        // The DOMAIN still follows objective size - the bigger half of a
        // commander's ground loses data, the rest loses voice - but the
        // REACH is rolled per site between the module's two bounds, so two
        // masts of the same kind are not the same problem.
        private _big = _forEachIndex < ceil (_want / 2);
        private _lo = GVAR(smallRadius) min GVAR(largeRadius);
        private _hi = GVAR(smallRadius) max GVAR(largeRadius);
        _jobs pushBack [
            _side, _pos, _size,
            [DOM_RADIO, DOM_DATA] select _big,
            _lo + random (_hi - _lo)
        ];
    } forEach _objs;

    // ONE GPS UPLINK ON THE WHOLE MAP (user, 2026-08-31), not one per
    // commander. A comms net is many masts; a satellite constellation is
    // steered from one place, and one uplink is what makes destroying it mean
    // something. The first commander with ground gets it and nobody else does.
    //
    // Queued FIRST so it is standing before the masts: it is the only site that
    // also registers an ALiVE objective and starts a drift loop, and a player
    // dropping in early should meet the system that cannot be walked out of.
    if (GVAR(gpsEnable) && {!_gpsDone}) then {
        _jobs insert [0, [[_side, (_objs select 0) select 1, 0, DOM_GPS, 0]]];
        _gpsDone = true;
    };
} forEach (call EFUNC(adapter_alive,commanders));

INFO_1("%1 jammer site(s) queued",count _jobs);
if (_jobs isEqualTo []) exitWith {0};

// --------------------------------------------------------------- the drain --
// JAM_SPAWN_PER_TICK a frame, then hand the rest to the next one. The queue,
// the avoid list and the running total live in the handler's own args, so
// nothing global is left behind if the mission ends mid-drain.
private _queued = count _jobs;

[{
    params ["_args", "_handle"];
    _args params ["_queue", "_at", "_placed"];

    if (_queue isEqualTo []) exitWith {
        [_handle] call CBA_fnc_removePerFrameHandler;
        // ONE broadcast for the whole batch - see FUNC(publishZones). At the
        // end, never per site: publishing per zone is what put twelve thousand
        // registry entries on the wire in a single frame once before.
        [] call FUNC(publishZones);
        INFO_1("%1 jammer site(s) up",_placed select 0);
    };

    for "_i" from 1 to JAM_SPAWN_PER_TICK do {
        if (_queue isEqualTo []) exitWith {};
        (_queue deleteAt 0) params ["_side", "_pos", "_size", "_domain", "_radius"];

        private _id = "";

        if (_domain isEqualTo DOM_GPS) then {
            // The uplink brings its own radius and its own placement rule: it
            // stands at the objective centre, because it is a fixed strategic
            // installation meant to be found, not a mast tucked beside a wall.
            ([_side, _pos] call FUNC(spawnGpsUplink)) params ["_upId"];
            _id = _upId;
        } else {
            // A comms mast belongs BESIDE a building, so the clear radius is cut
            // right down: the default rejected every candidate in a town and
            // failed sixty-odd times in one run. The ring is widened for the
            // same reason - an objective's footprint is often wall to wall.
            private _spots = [[], 1, createHashMapFromArray [
                ["centre", _pos],
                ["maxRange", ((_size max 120) min 400)],
                ["footprint", 2],
                ["clearRadius", 3],
                ["separation", 150],
                ["avoid", _at],
                ["avoidRadius", 150]
            ]] call EFUNC(common,findSite);

            // Still nowhere: put it near the objective rather than skipping. An
            // objective with no jammer because the ground is cluttered is a
            // silently missing system; one standing in an awkward spot is not.
            if (_spots isEqualTo []) then {
                _spots = [_pos getPos [30 + random 60, random 360]];
            };

            ([_side, _spots select 0, _domain, _radius] call FUNC(spawnJammerSite)) params ["_sid"];
            _id = _sid;
            if (_id isNotEqualTo "") then { _at pushBack (_spots select 0) };
        };

        if (_id isNotEqualTo "") then { _placed set [0, (_placed select 0) + 1] };
    };
}, 0, [_jobs, [], [0]]] call CBA_fnc_addPerFrameHandler;

_queued
