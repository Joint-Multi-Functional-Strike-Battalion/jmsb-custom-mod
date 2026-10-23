#include "script_component.hpp"
/*
 * Author: JMSB
 * A map point out of TAC//SUPPORT's parameter array, written there by a
 * point row this provider declared (task declaration field 7, support core
 * README) - INGRESS, EGRESS, VIA, LZ, SET DOWN. Anything that is not a
 * position reads as none: the array is shared by every asset, so a slot can
 * hold whatever another screen left in it.
 *
 * Arguments:
 * 0: The parameter array <ARRAY>
 * 1: Slot <NUMBER>
 * 2: A list of points (a VIA row) rather than one <BOOL> (optional, default false)
 *
 * Return Value:
 * [x, y, 0], or [] for none - or, for a list, an array of those <ARRAY>
 *
 * Example:
 * [_prm, 8] call jmfsb_support_air_fnc_readPoint
 *
 * Public: No
 */

params [["_prm", [], [[]]], ["_slot", 0, [0]], ["_many", false, [false]]];

private _fnc_point = {
    if (_this isEqualType [] && {count _this >= 2} && {(_this select 0) isEqualType 0} && {(_this select 1) isEqualType 0}) then {
        [_this select 0, _this select 1, 0]
    } else {
        []
    };
};

private _v = _prm param [_slot, []];

if (!_many) exitWith {_v call _fnc_point};
if !(_v isEqualType []) exitWith {[]};

(_v apply {_x call _fnc_point}) select {_x isNotEqualTo []}
