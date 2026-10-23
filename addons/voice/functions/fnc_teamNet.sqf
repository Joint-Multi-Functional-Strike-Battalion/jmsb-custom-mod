#include "script_component.hpp"
/*
 * Author: JMSB
 * The TEAM net of a unit, carried on VON's Group channel: his squad's short
 * range net of the PAC plan (jmfsb_voice_fnc_planNet), else one of his own
 * per Arma group, "TEAM <side> <group callsign>" (the side is in the id
 * because callsigns repeat across sides).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Net id, "" when the unit has no group <STRING>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_teamNet
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _group = group _unit;
if (isNull _group) exitWith {""};

private _plan = [_unit, PLAN_SR] call FUNC(planNet);
if (_plan isNotEqualTo "") exitWith {_plan};

format [TEAM_FORMAT, side _group, groupId _group]
