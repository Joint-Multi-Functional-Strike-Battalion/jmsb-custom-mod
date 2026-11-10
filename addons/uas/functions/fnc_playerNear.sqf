#include "script_component.hpp"
/*
 * Author: YonV
 * Is anybody near enough for a patrol over this position to be worth flying?
 *
 * THE ONE PLACE THAT ANSWERS IT, because three ask: the planner filtering its
 * objective list, FUNC(topUp) refusing a launch, and FUNC(standDown) taking
 * one back. Three copies of "which players count" is three chances to forget
 * the headless client.
 *
 * WHO COUNTS: a live player, on any side. Not a headless client - it is a
 * machine, it has no eyes and it stands wherever the mission put it, which on
 * this collection is inside somebody's base and would hold every patrol on the
 * map up forever. Not a corpse either; a dead man is not an audience.
 *
 * Arguments:
 * 0: Position <ARRAY>
 * 1: Range in metres <NUMBER> (optional, default UAS_PLAYER_RANGE)
 *
 * Return Value:
 * Somebody is within range <BOOL>
 *
 * Example:
 * if ([_pos] call jmfsb_uas_fnc_playerNear) then {...}
 *
 * Public: No
 */

params [["_pos", [], [[]]], ["_range", UAS_PLAYER_RANGE, [0]]];

if (_pos isEqualTo []) exitWith {false};

// findIf, not count: the first man inside the ring settles it, and on a full
// server this runs once per objective per planning tick.
(allPlayers select {!(_x isKindOf "HeadlessClient_F")}) findIf {
    alive _x && {(getPosATL _x) distance2D _pos < _range}
} > -1
