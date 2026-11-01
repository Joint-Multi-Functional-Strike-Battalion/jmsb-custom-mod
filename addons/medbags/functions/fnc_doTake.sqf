#include "..\script_component.hpp"
/*
 * Author: YonV
 * Moves every medical bag the casualty is carrying onto the player.
 *
 * ALL OF THEM, IN ONE PULL. A man working on a casualty under fire should not
 * be reopening an interaction menu five times, and a casualty is not going to
 * use the kit himself while he is out. One activation clears whatever he has.
 *
 * REMOVED FIRST, THEN GIVEN. FUNC(addItem) falls back to the ground when the
 * player has no room for a bag, so a bag can never be destroyed by taking it -
 * worst case it lands at the player's feet. The removal still happens first, so
 * a full player cannot duplicate the bag by taking it twice. That fallback is
 * the Overflow setting: turned off, a bag the player has no room for IS lost,
 * which is the trade that setting names.
 *
 * THE CASUALTY IS NOT NECESSARILY LOCAL. removeItem on a remote unit does
 * nothing at all, so the strip runs where the casualty is and the handover
 * comes back to the player - who is, by definition, local to himself.
 *
 * Arguments:
 * 0: Player <OBJECT>
 * 1: Casualty <OBJECT>
 *
 * Return Value:
 * The bags taken <ARRAY of STRING>
 *
 * Example:
 * [player, cursorObject] call jmfsb_medbags_fnc_doTake;
 *
 * Public: No
 */

params [["_player", objNull, [objNull]], ["_target", objNull, [objNull]]];

if (isNull _player || {isNull _target}) exitWith {[]};

private _carried = items _target;
private _taken = MEDBAG_ITEMS select {_x in _carried};

if (_taken isEqualTo []) exitWith {
    INFO_1("%1 carries no medical bag",_target);
    []
};

// The same fill order and overflow rule the bags themselves unpack under - a
// bag taken off a casualty should not land somewhere different from one taken
// out of your own vest. See initSettings.inc.sqf.
private _order = (GVAR(fillOrder) splitString ",") apply {parseNumber (trim _x)} select {_x in [1, 2, 3]};
if (_order isEqualTo []) then {_order = [3, 2, 1]};

// One count per class, because a casualty can be carrying two of the same bag
// and the action should hand over both. The casualty's machine removes them and
// hands back only what it removed (FUNC(stripBag), review L3), so two medics
// taking at once cannot both get the bag.
{
    private _item = _x;
    private _n = {_x isEqualTo _item} count _carried;

    [_target, _item, _n, _player, _order, GVAR(fillOverflow)] remoteExecCall [QFUNC(stripBag), _target];
} forEach _taken;

INFO_3("%1 took %2 from %3",_player,_taken,_target);

_taken
