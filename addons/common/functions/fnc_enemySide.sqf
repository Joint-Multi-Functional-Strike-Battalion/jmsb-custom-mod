#include "script_component.hpp"
/*
 * Author: JMSB
 * The side the players are fighting, worked out rather than typed.
 *
 * SIDES ARE TYPED ONCE (D59). A module that needs "the enemy" - the jamming
 * site, the drone patrol - used to carry its own Side box, and every one of
 * those boxes was a chance to disagree with the mission. This reads the
 * mission instead: the players' sides from their slots (FUNC(playerSides)),
 * and the first side the mission's relations make hostile to any of them.
 *
 * TWO HOSTILE SIDES: the first in the order east, independent, west wins.
 * Set the side you do not mean as friendly or neutral to the players in the
 * mission's side relations and the answer is exact (user, 2026-10-09).
 *
 * NO PLAYER SLOTS, or nobody hostile: east, the side every one of the old
 * boxes defaulted to, with a warning in the RPT.
 *
 * Arguments: None
 *
 * Return Value:
 * The enemy side <SIDE>
 *
 * Example:
 * private _enemy = call jmfsb_common_fnc_enemySide;
 *
 * Public: Yes
 */

#define ENEMY_ORDER [east, independent, west]
#define HOSTILE_BELOW 0.6

private _players = call FUNC(playerSides);
if (_players isEqualTo []) exitWith {
    WARNING("enemySide: the mission has no player slots - assuming east");
    east
};

private _hostile = ENEMY_ORDER select {
    private _s = _x;
    !(_s in _players) && {_players findIf {(_s getFriend _x) < HOSTILE_BELOW} > -1}
};

if (_hostile isEqualTo []) exitWith {
    WARNING_1("enemySide: no side is hostile to the players (%1) - assuming east",_players);
    east
};

if (count _hostile > 1) then {
    INFO_2("enemySide: %1 are all hostile to the players - using %2",_hostile,_hostile select 0);
};

_hostile select 0
