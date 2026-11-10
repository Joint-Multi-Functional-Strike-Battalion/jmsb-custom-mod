#include "script_component.hpp"
/*
 * Author: YonV
 * SHARE (F2, user, 2026-11-08: "f2 puts on ever medic skilled player in 5 m"):
 * puts a watched target on the same profile of every other player within
 * SLOT_SHARE_RANGE that the test accepts - on each one's own machine
 * (FUNC(slotShared)) - and tells the sharer how many it reached.
 *
 * Arguments:
 * 0: Profile id <STRING>
 * 1: Target <OBJECT>
 * 2: Who may take it, {params ["_unit"]; bool} <CODE> (default: anyone)
 *
 * Return Value:
 * Players it went to <NUMBER>
 *
 * Example:
 * ["medical", _patient, {params ["_unit"]; [_unit] call jmfsb_medic_fnc_isMedic}] call jmfsb_watch_fnc_slotShare
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_target", objNull, [objNull]], ["_test", {true}, [{}]]];

if (isNull _target || {!(_id in GVAR(profiles))}) exitWith {0};

private _near = (allPlayers - [player]) select {
    alive _x && {(_x distance player) <= SLOT_SHARE_RANGE} && {[_x] call _test}
};
{
    [QGVAR(slotShared), [_id, _target, name player], _x] call CBA_fnc_targetEvent;
} forEach _near;

private _name = toUpper ((GVAR(profiles) get _id) getOrDefault ["name", _id]);
private _what = [[_target] call FUNC(contactName), name _target] select (_target isKindOf "CAManBase");
[NOTE_TITLE, [
    format ["%1: no one within %2 m to share with.", _name, SLOT_SHARE_RANGE],
    format ["%1: %2 shared with %3.", _name, _what, (_near apply {name _x}) joinString ", "]
] select (_near isNotEqualTo []), NOTE_COLOUR] call EFUNC(notify,notify);

count _near
