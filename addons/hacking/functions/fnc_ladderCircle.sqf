#include "script_component.hpp"
/*
 * Author: JMSB
 * ONE SITE AT A TIME, tightening. The shared body behind LOCATE AA and
 * LOCATE ARTILLERY: both used to answer differently and neither did this.
 *
 * The rules, in full, because every one of them is a decision:
 *
 *   ONE target, never the pool. Plotting every battery at once turns a hack
 *   into a map reveal - there is nothing left to hunt.
 *
 *   The NEAREST one when the lock is taken, and then THAT ONE STAYS. The lock
 *   is not re-taken while it lives: walking 500 m must not restart the ladder
 *   on a different battery, or the circle never tightens and the mechanic is
 *   just noise.
 *
 *   Each further hack draws a SMALLER circle on the SAME site - 3000, then
 *   2000, then 1000 by default. The last radius repeats, so a fully worked
 *   site keeps its tight circle instead of jittering.
 *
 *   Always OFF CENTRE, on a bearing fixed when the lock is taken. The throw
 *   shrinks with the radius, so the circles close in from one side and the
 *   real position is inside every one of them. A re-roll per tier would let a
 *   player hack repeatedly and average out the truth.
 *
 *   Only when the site is GONE from the pool does the lock move to the next
 *   nearest - destroy it, and the next one is what you get.
 *
 * Arguments:
 * 0: Candidate sites, [id, position, side] each <ARRAY>
 * 1: Where the hack happened <ARRAY>
 * 2: The side being told <SIDE>
 * 3: Lock store, keyed by side <HASHMAP>
 * 4: Marker key, unique per product <STRING>
 * 5: Label drawn on the circle <STRING>
 *
 * Return Value:
 * Something was drawn <BOOL>
 *
 * Example:
 * [_pool, _pos, west, GVAR(aaLock), "aa", "AIR DEFENCE"] call jmfsb_hacking_fnc_ladderCircle
 */

params [["_pool", [], [[]]], ["_pos", [], [[]]], ["_side", sideUnknown, [sideUnknown]],
        ["_store", createHashMap, [createHashMap]], ["_key", "", [""]], ["_label", "", [""]]];

if (_pool isEqualTo []) exitWith {false};

private _sk = str _side;
(_store getOrDefault [_sk, ["", -1, 0, ""]]) params ["_id", "_tier", "_bearing", "_colour"];

// Is the locked site still standing? The pools are rebuilt from live profiles
// on every read, so a destroyed battery simply is not in this list any more.
private _i = _pool findIf {(_x select 0) isEqualTo _id};

if (_i < 0) then {
    // Take a new lock on the nearest, and roll the bearing once for its whole
    // ladder.
    private _bestD = 1e9;
    {
        private _d = (_x select 1) distance2D _pos;
        if (_d < _bestD) then { _bestD = _d; _i = _forEachIndex };
    } forEach _pool;

    _id = (_pool select _i) select 0;
    _tier = -1;
    _bearing = random 360;
    // Colour is drawn with the lock and KEPT for the whole ladder. Re-rolling
    // it per tier would make one site look like three different products.
    _colour = selectRandom INTEL_CIRCLE_COLOURS;
};

private _at = (_pool select _i) select 1;

private _radii = (([QGVAR(cfg_circle_radii)] call FUNC(hackSetting)) splitString ", ")
    apply { parseNumber _x };
_radii = _radii select {_x > 0};
if (_radii isEqualTo []) then { _radii = [3000, 2000, 1000] };

_tier = (_tier + 1) min (count _radii - 1);
private _radius = _radii select _tier;

// FRACTION FIRST, THEN THE CAP. The setting is a percentage and the cap is a
// fraction, so capping before dividing turned 75% into 0.95% - the circle was
// drawn all but exactly on the target, which is why a "fuzzed" product was
// reading as an exact fix.
private _offset = (([QGVAR(cfg_circle_offset)] call FUNC(hackSetting)) / 100);
_offset = 0 max _offset min INTEL_OFFSET_CAP;

private _throw = _radius * _offset;
private _centre = _at vectorAdd [sin _bearing * _throw, cos _bearing * _throw, 0];

_store set [_sk, [_id, _tier, _bearing, _colour]];

// THE G2 LEARNS WHAT THE PLAYER LEARNED - the circle's centre, not the
// target. Filed as a spot report so the commander's tablet and COP carry it.
if (!isNil "jmfsb_adapter_alive_fnc_reportIntel") then {
    [_side, (_pool select _i) param [2, sideUnknown], _id, _centre, toLower _label] call jmfsb_adapter_alive_fnc_reportIntel;
};

// One marker per product per side, so a new circle REPLACES the last rather
// than leaving a trail of stale ones the player can triangulate from.
["circle",
    format [QGVAR(%1_%2), _key, _sk],
    _centre, _radius, _colour, "",
    format ["%1 T%2", _label, _tier + 1], _side
] call FUNC(sendProduct);

INFO_4("%1: site %2 tier %3, %4 m circle",_label,_id,_tier + 1,round _radius);
true
