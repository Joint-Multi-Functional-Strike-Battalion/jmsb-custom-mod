#include "script_component.hpp"
/*
 * Author: YonV
 * Which sides the players are on.
 *
 * THE ENEMY SYSTEMS NEED TO KNOW WHO IS NOT THE ENEMY. JMSB's threat systems
 * are named for what they are - "Enemy Drones", air defence to be found and
 * killed - and they were arming every commander ALiVE reported, the players'
 * own side included. The RPT: nine WEST patrols and seven GUER ones flying
 * against a BLUFOR mission, and a BLUFOR SAM site built beside a BLUFOR
 * squad. Threats aimed at the people who are meant to meet them.
 *
 * PLAYABLE SLOTS, NOT CONNECTED PLAYERS. On a dedicated server this is read at
 * mission start, when nobody has joined yet - allPlayers alone would come back
 * empty and every side would read as hostile.
 *
 * An empty answer means the mission has no player slots at all, and callers
 * treat it as "no restriction" rather than switching themselves off.
 *
 * Arguments: None
 *
 * Return Value:
 * Sides with players on them <ARRAY of SIDE>
 *
 * Example:
 * private _mine = call jmfsb_common_fnc_playerSides;
 *
 * Public: Yes
 */

private _out = [];

{
    private _s = side group _x;
    if (_s in [west, east, independent] && {!(_s in _out)}) then {
        _out pushBack _s;
    };
} forEach ((allPlayers - (entities "HeadlessClient_F")) + playableUnits);

_out
