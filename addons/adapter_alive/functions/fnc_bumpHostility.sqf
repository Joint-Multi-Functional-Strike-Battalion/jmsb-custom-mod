#include "script_component.hpp"
/*
 * Author: YonV
 * Raises the civilian population's hostility toward a side, in the settlement
 * nearest a position.
 *
 * ALiVE'S CIVILIAN SYSTEM ALREADY KEEPS THIS LEDGER, per settlement cluster and
 * per side, and its own population reacts to it - which is the whole reason to
 * write into it rather than to keep a second opinion of our own. JMSB's job is
 * to say what happened and where; what a town does about it is ALiVE's.
 *
 * IT IS HERE BECAUSE OF THE SEAM. This was written inline in jmfsb_hacking,
 * naming ALIVE_clustersCivSettlement and ALiVE_fnc_hashGet/hashSet directly -
 * a second addon that could not survive ALiVE being absent, which is exactly
 * what the adapter exists to prevent. The caller now says "somebody saw this"
 * and does not know whether anyone is keeping score.
 *
 * SERVER ONLY, in the sense that it must run where the civilian system reads the
 * ledger. It does not check that itself - the caller's event does.
 *
 * Arguments:
 * 0: Position, 2D or 3D <ARRAY>
 * 1: Side, as ALiVE stores it - "WEST", "EAST", "GUER", "CIV" <STRING>
 * 2: How much to add, clamped to 100 <NUMBER>
 *
 * Return Value:
 * The settlement's new hostility toward that side, or -1 if nothing was
 * written - no ALiVE, no index for this map, or no cluster near enough <NUMBER>
 *
 * Example:
 * [getPosATL player, "WEST", 5] call jmfsb_adapter_alive_fnc_bumpHostility
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_sideStr", "", [""]], ["_by", 0, [0]]];

if (_pos isEqualTo [] || _sideStr isEqualTo "" || _by <= 0) exitWith {-1};
if (isNil "ALiVE_fnc_hashGet" || {isNil "ALiVE_fnc_hashSet"}) exitWith {-1};

private _hash = missionNamespace getVariable "ALIVE_clustersCivSettlement";
if (isNil "_hash") exitWith {-1};

// NEAREST, NOT CONTAINING. A cluster carries a size, but a hack seen from the
// edge of a village is still seen by that village - and taking the nearest means
// there is always an answer on a map ALiVE has indexed at all.
private _best = [];
private _bestD = 1e9;
{
    if !(_x isEqualType []) then {continue};

    private _c = [_x, "center", []] call ALiVE_fnc_hashGet;
    if (_c isEqualTo []) then {continue};

    private _d = _c distance2D _pos;
    if (_d < _bestD) then {
        _bestD = _d;
        _best = _x;
    };
} forEach (_hash select HASH_VALUES);

if (_best isEqualTo []) exitWith {-1};

// A cluster indexed before the civilian module built its hostility hash has no
// ledger to write into, and inventing one here would hand ALiVE a shape it did
// not make.
private _hh = [_best, "hostility", []] call ALiVE_fnc_hashGet;
if (_hh isEqualTo []) exitWith {-1};

private _now = (([_hh, _sideStr, 0] call ALiVE_fnc_hashGet) + _by) min 100;
[_hh, _sideStr, _now] call ALiVE_fnc_hashSet;

_now
