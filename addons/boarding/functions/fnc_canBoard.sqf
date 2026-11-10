#include "script_component.hpp"
/*
 * Author: YonV
 * Is there anything for this boarding point to do right now?
 *
 * The action is hidden rather than shown-and-refusing: a button that is there
 * when it cannot work teaches players to distrust it. It needs somebody in
 * range on foot and a seat to put them in.
 *
 * Arguments:
 * 0: The module <OBJECT>
 * 1: The player pressing <OBJECT>
 *
 * Return Value:
 * Bool
 *
 * Example:
 * [_logic, player] call jmfsb_boarding_fnc_canBoard
 */

params [["_logic", objNull, [objNull]], ["_player", objNull, [objNull]]];

if (isNull _logic || {isNull _player}) exitWith {false};

private _range = _logic getVariable [QGVAR(range), BOARD_RANGE_DEF];
private _at = getPosATL _logic;

// somebody on foot within reach - the presser counts even when the module is
// set to leave them behind, because "load everyone but me" is still work
private _anyone = (allPlayers - entities "HeadlessClient_F") findIf {
    alive _x && {isNull objectParent _x} && {(_at distance2D _x) <= _range}
} > -1;
if (!_anyone) exitWith {false};

([_logic] call FUNC(seatsFor)) isNotEqualTo []
