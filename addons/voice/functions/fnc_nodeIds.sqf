#include "script_component.hpp"
/*
 * Author: JMSB
 * The RF node ids a player's sets can have (handheld, vehicle seat - no man
 * packs),
 * whether or not he carries them now. Ids are stable across respawn.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Node ids <ARRAY of STRINGs>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_nodeIds
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {[]};
private _uid = getPlayerUID _unit;
NODE_KINDS apply {format [NODE_FORMAT, _uid, _x]}
