#include "script_component.hpp"
/*
 * Author: JMSB
 * TRACE NETWORK: a circle on a live leader's SAFE HOUSE - never on the man.
 *
 * If he has a rotation queued the circle points at where he is GOING, so
 * intel taken from a house he has left still leads somewhere. The ladder
 * tightens per trace against the same leader, which is the same grammar every
 * other product uses.
 *
 * Arguments:
 * 0: Where the hack happened <ARRAY>
 * 1: Asking side <SIDE>
 *
 * Return Value:
 * Anything drawn <BOOL>
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_side", sideUnknown, [sideUnknown]]];

private _up = [];
{
    if ((_x select 2) isEqualTo "up" && {!isNull (_x select 0)}) then {
        _up pushBack [_forEachIndex, _x];
    };
} forEach GVAR(leaders);

if (_up isEqualTo []) exitWith {false};

// The one whose ground this hack happened on, else the nearest.
private _pick = _up select 0;
private _best = 1e9;
{
    private _d = ((_x select 1) select 0) distance2D _pos;
    if (_d < _best) then { _best = _d; _pick = _x };
} forEach _up;

_pick params ["_idx", "_rec"];
_rec params ["_u", "_hi", "", "_tier"];

private _house = GVAR(houses) param [GVAR(nextHouse) getOrDefault [_idx, _hi], objNull];
if (isNull _house) exitWith {false};

private _radii = LEADERS_RADII;
private _radius = _radii select (_tier min (count _radii - 1));
_rec set [3, _tier + 1];

private _bearing = random 360;
private _throw = _radius * LEADERS_OFFSET;
private _centre = (getPosATL _house) vectorAdd
    [sin _bearing * _throw, cos _bearing * _throw, 0];

// By remoteExec from the server, not a CBA event any client could raise
// (review S7). Hacking is optional here: it is the only caller, but check.
if (isNil "jmfsb_hacking_fnc_sendProduct") exitWith {false};
["circle",
    format [QGVAR(trace_%1_%2), _idx, _tier],
    _centre, _radius, "ColorOrange", "", format ["SAFE HOUSE T%1", _tier + 1], _side
] call jmfsb_hacking_fnc_sendProduct;

INFO_3("TRACE NETWORK: leader %1 tier %2, %3 m",_idx + 1,_tier + 1,round _radius);
true
