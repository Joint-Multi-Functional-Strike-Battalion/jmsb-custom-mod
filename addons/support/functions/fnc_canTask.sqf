#include "script_component.hpp"
/*
 * Author: JMSB
 * THE TASKING TAG GATE - may this man task support assets? The Support
 * tasking tag setting through EFUNC(messaging,tagMatch), default empty
 * (everyone). Moved here from TAC//SUPPORT so FUNC(request) and the screen ask
 * the same question.
 *
 * THE GATE ONLY COUNTS WHEN THE TAG NAMES SOMEBODY IN THIS MISSION. A "JFO"
 * tag met a mission that flags nobody isJFO, so the screen refused to open for
 * anybody, forever, behind one easy-to-miss notify. A tag that matches no
 * player and no playable slot is a misconfiguration, not a gate: it fails
 * OPEN, loudly in the RPT.
 *
 * Arguments:
 * 0: Unit <OBJECT> (optional, default player)
 *
 * Return Value:
 * 0: May task <BOOL>
 * 1: Why not, "" when he may <STRING>
 *
 * Example:
 * [player] call jmfsb_support_fnc_canTask
 *
 * Public: Yes
 */

params [["_unit", player, [objNull]]];

private _gate = GVAR(tag);
if (_gate isEqualTo "" || {[_unit, _gate] call EFUNC(messaging,tagMatch)}) exitWith {[true, ""]};

private _named = (allPlayers + (playableUnits select {!isPlayer _x}))
    findIf {[_x, _gate] call EFUNC(messaging,tagMatch)} > -1;
if (!_named) exitWith {
    WARNING_1("canTask: tag '%1' names nobody in this mission - failing open",_gate);
    [true, ""]
};

WARNING_2("canTask: gate refused %1 - tasking is held by '%2'",_unit,_gate);
[false, format ["Tasking is held by %1.", toUpper _gate]]
