#include "script_component.hpp"
/*
 * Author: YonV
 * Who FOLLOW can walk to: the BFT picture's friendlies
 * (jmfsb_bft_fnc_friendlies; the player's own group without BFT), nearest
 * first, each with the label the row shows - his member number and name,
 * and the vehicle he is in - his group, and his distance from the GPS fix.
 * A man in a vehicle is how a vehicle is followed.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[unit, label, group id, distance m (-1 with no fix)], ...] <ARRAY>
 *
 * Example:
 * private _contacts = [] call jmfsb_pointman_fnc_contacts
 *
 * Public: No
 */

private _me = call CBA_fnc_currentUnit;
if (isNull _me) exitWith {[]};

private _men = if (isNil QEFUNC(bft,friendlies)) then {units group _me} else {[] call EFUNC(bft,friendlies)};
private _here = [] call FUNC(gpsPos);

private _rows = [];
{
    if (_x isEqualTo _me || {!alive _x}) then {continue};
    private _n = if (isNil QEFUNC(bft,memberNumber)) then {0} else {[_x] call EFUNC(bft,memberNumber)};
    private _label = format ["%1 %2", _n, (toUpper name _x) select [0, FOLLOW_NAME_MAX]];
    private _veh = objectParent _x;
    if (!isNull _veh) then {
        _label = format ["%1 IN %2", _label, toUpper getText (configOf _veh >> "displayName")];
    };
    private _dist = if (_here isEqualTo []) then {-1} else {_here distance2D _x};
    // Distance first so the sort is by it; the row is put back in order below.
    _rows pushBack [_dist, _x, _label, groupId group _x];
} forEach _men;
_rows sort true;

_rows apply {[_x select 1, _x select 2, _x select 3, _x select 0]}
