#include "..\script_component.hpp"
/*
 * Author: YonV
 * Removes a number of one bag class from a unit, where that unit is local,
 * and gives the taker exactly what came off.
 *
 * WHY THIS EXISTS AT ALL. removeItem is a local command: run against a unit
 * that belongs to another machine it returns quietly and changes nothing, and
 * FUNC(doTake) would then hand the player a bag the casualty still has. This is
 * the half that has to travel.
 *
 * GIVEN ONLY WHAT WAS REMOVED (review L3). The taker used to be handed the
 * bags at once, before this ran, so two medics taking from one casualty both
 * got them. The count is taken here, where the removal happens, and the
 * handover goes back to the taker's machine.
 *
 * Arguments:
 * 0: Casualty <OBJECT>
 * 1: Item class <STRING>
 * 2: How many <NUMBER>
 * 3: Taker <OBJECT>
 * 4: Fill order, container codes for EFUNC(common,addItem) <ARRAY>
 * 5: Overflow to the ground <BOOL>
 *
 * Return Value:
 * How many were removed <NUMBER>
 *
 * Example:
 * [_casualty, "jmfsb_medbags_FirstAid", 1, player, [3, 2, 1], true] remoteExecCall ["jmfsb_medbags_fnc_stripBag", _casualty]
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_item", "", [""]],
    ["_count", 1, [0]],
    ["_taker", objNull, [objNull]],
    ["_order", [], [[]]],
    ["_overflow", true, [true]]
];

if (isNull _unit || _item isEqualTo "" || {!local _unit}) exitWith {0};

private _before = {_x isEqualTo _item} count items _unit;
for "_i" from 1 to (_count min _before) do {
    _unit removeItem _item;
};
private _removed = _before - ({_x isEqualTo _item} count items _unit);

if (_removed > 0 && {!isNull _taker}) then {
    [_taker, _item, _removed, _order, _overflow] remoteExecCall [QEFUNC(common,addItem), _taker];
};

_removed
