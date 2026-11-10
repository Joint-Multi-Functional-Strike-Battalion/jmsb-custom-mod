#include "script_component.hpp"
/*
 * Author: YonV
 * THE PRE-SPAWN GATE: may this side put something at this position? Asked by
 * every module system before a computed-position spawn, after wrong-side
 * sightings kept coming back one addon at a time - the answer belongs in one
 * place, not re-derived in each.
 *
 * The rule: inside the side's own ground, and never on somebody else's. The
 * TAOR comes from the caller when it has its own markers (a module attribute),
 * from FUNC(groundFor) otherwise - ALiVE's TAORs with ALiVE, the mission's
 * jmfsb_taor_<side> markers without it.
 *
 * NO TAOR OF ITS OWN MEANS THE WHOLE MAP - ALiVE's own convention, and the
 * hole this gate used to have. It read "no TAOR, no gate" and waved every
 * spawn through, so a side whose commander declares no placements - which on
 * this mission is BLUFOR - could put drones and hardware anywhere, including
 * deep inside the red TAOR. The RPT proved it: not one refusal all mission
 * while west flew nine patrols. Now an undeclared side is still bounded by
 * everyone ELSE's declarations: hostile ground is added to its blacklist, so
 * "anywhere" stops at the enemy's boundary. FUNC(plan) in air defence already
 * did this for itself; it belongs here, where every system gets it.
 *
 * A refusal warns with the caller's tag, so the RPT says which system
 * held its fire and where.
 *
 * Arguments:
 * 0: Side <SIDE>
 * 1: Position <ARRAY>
 * 2: Caller tag for the log <STRING> (optional)
 * 3: TAOR marker names <ARRAY> (optional - the adapter's when absent)
 * 4: Blacklist marker names <ARRAY> (optional)
 * 5: Do not warn on a refusal <BOOL> (optional, default false)
 *
 * QUIET IS FOR BULK. The warning is written for one refused spawn, where it is
 * the only record that a system held its fire. A caller filtering a whole list
 * through the gate - every objective a commander holds, every QRF origin -
 * would turn that into sixty lines a minute saying the same thing, so it says
 * how many it dropped instead. Single-spawn callers stay loud.
 *
 * Return Value:
 * The spawn may go ahead <BOOL>
 *
 * Example:
 * if (!([east, _pos, "uas patrol"] call jmfsb_common_fnc_taorGate)) exitWith {false};
 *
 * Public: Yes
 */

params [
    ["_side", sideUnknown, [sideUnknown]],
    ["_pos", [], [[]]],
    ["_tag", "", [""]],
    ["_taor", [], [[]]],
    ["_black", [], [[]]],
    ["_quiet", false, [false]]
];

if (_pos isEqualTo []) exitWith {true};

// COPIED BEFORE IT IS TOUCHED. params hands back the caller's own array, and
// the foreign ground below is pushed into it - without this, one gated spawn
// would permanently grow its caller's blacklist.
_black = +_black;

// THE SIDE'S GROUND, WITH OR WITHOUT ALiVE (user, 2026-11-02). FUNC(groundFor)
// is the adapter's taorFor when ALiVE is loaded and the mission's own
// jmfsb_taor_<side> / jmfsb_black_<side> markers when it is not - so the gate
// holds on a mission without ALiVE too, instead of waving everything through.
if (_taor isEqualTo [] && {_side isNotEqualTo sideUnknown}) then {
    ([_side] call FUNC(groundFor)) params [["_t", []], ["_b", []]];
    _taor = _t;
    if (_black isEqualTo []) then {_black = +_b};
};

// SOMEBODY ELSE'S GROUND, ASKED ONCE A MINUTE, NOT ONCE A SPAWN. The QRF
// filters a whole list of origins through this gate, and taorFor walks every
// commander's synchronised objects - so the answer is cached. TAOR markers do
// not move during a mission; the refresh only exists so a commander that
// initialises late is picked up.
//
// ONLY FOR A SIDE THAT DECLARED NOTHING. This ran for every side, and that is
// a second rule quietly overriding the mission maker's first one: TAORs are
// allowed to OVERLAP, and on an insurgency they are meant to - this
// collection's Tanoa mission draws the insurgents' green over most of the
// players' blue, because inside the players' half is where insurgents live.
// Subtracting foreign ground from a side that HAS its own left that side with
// the slivers of its TAOR nobody else claimed, which for the insurgents was a
// kilometre of coastline and no drones, batteries or safe houses anywhere they
// were placed to operate.
//
// A declared TAOR is a statement of where that side operates, overlaps
// included, and it wins. The foreign list exists for the side that declared
// NOTHING - which reads as the whole map, and is the hole this gate was
// written to close: that side is still bounded by everybody else's
// declarations.
if (_taor isEqualTo [] && {_side isNotEqualTo sideUnknown}) then {
    private _cache = missionNamespace getVariable [QGVAR(foreignTaorCache), createHashMap];
    (_cache getOrDefault [str _side, [-1e9, []]]) params ["_stamp", "_foreign"];

    if (time - _stamp > 60) then {
        _foreign = [];
        {
            private _other = _x;
            if (_other isEqualTo _side) then {continue};
            // Hostility is asked of the engine rather than assumed from the
            // sides - a mission can set west and independent friendly, and an
            // ally's ground is not a boundary.
            if (_side getFriend _other >= 0.6) then {continue};

            {
                _foreign pushBackUnique _x;
            } forEach (([_other] call FUNC(groundFor)) select 0);
        } forEach [west, east, independent];

        _cache set [str _side, [time, _foreign]];
        missionNamespace setVariable [QGVAR(foreignTaorCache), _cache];
    };

    // A marker this side has claimed as its own is not foreign, whatever
    // another commander also lists - the caller's own declaration wins. Kept
    // for the caller that passes a TAOR in argument 3 while the adapter reads
    // none for it.
    {
        if !(_x in _taor) then { _black pushBackUnique _x };
    } forEach _foreign;
};

if (_taor isEqualTo [] && {_black isEqualTo []}) exitWith {true};

// An empty TAOR is the whole map, so the own-ground half is vacuously true and
// the blacklist - which now carries hostile ground - is what does the work.
private _ok = (_taor isEqualTo [] || {(_taor findIf {_pos inArea _x}) > -1})
    && {(_black findIf {_pos inArea _x}) == -1};

if (!_ok && {!_quiet}) then {
    WARNING_3("taorGate: refused %1 at %2 (%3) - outside the side's ground",_side,mapGridPosition _pos,_tag);
};

_ok
