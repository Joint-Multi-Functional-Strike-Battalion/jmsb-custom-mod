#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the danger-close check of a strike card (DESIGN_SUPPORT_MESSAGING
 * 5.3, user 2026-11-01): the provider refuses, the way a real pilot does - no
 * double-press SEND, no UI.
 *
 * Friendlies are the side's own units and crewed vehicles round the target -
 * on the server every one of them is known, which is what the side's blue
 * force tracker shows. Under the card's threshold (its `dangerClose` option,
 * else DANGER_CLOSE_CAS m - FUNC(readOrder)), or the requester's own Line 6
 * range under it, without the DANGER CLOSE tick: CANTCO
 * "DANGER CLOSE NOT ACKNOWLEDGED". Ticked, it is his call and the strike goes.
 *
 * Arguments:
 * 0: The order, from FUNC(readOrder) <HASHMAP>
 * 1: The side whose friendlies count <SIDE>
 *
 * Return Value:
 * 0: May strike <BOOL>
 * 1: Why not, "" when it may <STRING>
 * 2: The nearest friendly, m from the target; -1 none inside the threshold <NUMBER>
 *
 * Example:
 * ([_order, west] call jmfsb_support_fnc_dangerClose) params ["_ok", "_why"]
 *
 * Public: Yes
 */

params [["_order", createHashMap, [createHashMap]], ["_side", sideUnknown, [sideUnknown]]];

private _target = _order getOrDefault ["target", []];
if (count _target < 2) exitWith {[false, WHY_NO_TARGET, -1]};

private _threshold = _order getOrDefault ["dangerClose", DANGER_CLOSE_CAS];
private _near = (_target nearEntities [FRIENDLY_KINDS, _threshold]) select {
    alive _x && {(side group _x) isEqualTo _side}
};
private _nearest = -1;
if (_near isNotEqualTo []) then {
    _nearest = round selectMin (_near apply {_x distance2D _target});
};

private _stated = _order getOrDefault ["friendlies", -1];
private _close = _nearest >= 0 || (_stated >= 0 && _stated < _threshold);
if (_close && !(_order getOrDefault ["dcTick", false])) exitWith {
    [false, WHY_DANGER_CLOSE, _nearest]
};

[true, "", _nearest]
