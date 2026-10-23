#include "script_component.hpp"
/*
 * Author: JMSB
 * The people a thread's CALL button rings (user, 2026-10-21: "add to the
 * tac/msg app a call as a reply button"): the players among a thread's
 * authors and participants, by uid - in game, alive, and not the caller.
 *
 * Arguments:
 * 0: Uids on the thread <ARRAY of STRINGs>
 *
 * Return Value:
 * Units to ring <ARRAY of OBJECTs>
 *
 * Example:
 * [["7656..."]] call jmfsb_tacpad_fnc_readerCallUnits
 *
 * Public: No
 */

params [["_uids", [], [[]]]];

private _me = getPlayerUID player;
allPlayers select {
    alive _x && {getPlayerUID _x in _uids} && {getPlayerUID _x isNotEqualTo _me}
}
