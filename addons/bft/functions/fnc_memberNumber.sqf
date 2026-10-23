#include "script_component.hpp"
/*
 * Author: JMSB
 * The one number a man carries on every surface: the BFT member mark, the
 * phone's squad list and its map dot, the side devices, TAC//APP. Asked here
 * and nowhere else, so the map and the handset can never disagree about who
 * "3" is.
 *
 * ONE SOURCE, NO NETWORK. The number is his place in the group's own unit
 * order, counted from 1. That order is the engine's and is the same on every
 * machine, so nothing is broadcast and nothing can drift. The leader is first
 * in that order, so the leader is 1 - the same man the squad bar calls 1.
 *
 * It moves when the group changes (someone joins, leaves, dies out of it);
 * every surface reads it fresh each draw, so they move together.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Number, 1 based; 0 when the unit has no group <NUMBER>
 *
 * Example:
 * [player] call jmfsb_bft_fnc_memberNumber
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit || {isNull group _unit}) exitWith {0};

((units group _unit) find _unit) + 1
