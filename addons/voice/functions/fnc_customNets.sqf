#include "script_component.hpp"
/*
 * Author: JMSB
 * The RTO nets a man is on: every published net whose squads name his
 * group's callsign or whose players name him. Unlike the plan's C2 and A2G
 * nets, of which a man holds one each, he may be on any number of these -
 * FUNC(fill) puts them all in his sets' fill and FUNC(nets) lists them.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Net ids <ARRAY of STRINGs>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_customNets
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];

if (isNull _unit) exitWith {[]};

private _squad = toUpper trim groupId group _unit;
private _uid = getPlayerUID _unit;
(GVAR(customPub) select {
    _squad in (_x select CUSTOM_COL_SQUADS) || {_uid in (_x select CUSTOM_COL_UIDS)}
}) apply {_x select CUSTOM_COL_ID}
