#include "script_component.hpp"
/*
 * Author: JMSB
 * A tick on MANAGE's MEMBERS panel for an RTO net (FUNC(radioMembersPanel)):
 * puts a squad or a player into the draft, or takes it out, and redraws.
 *
 * Arguments:
 * 0: Draft column - DRAFT_COL_SQUADS or DRAFT_COL_UIDS <NUMBER>
 * 1: The callsign or UID <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [DRAFT_COL_UIDS, "7656..."] call jmfsb_tacpad_apps_fnc_radioMembersToggle
 *
 * Public: No
 */

params [["_col", DRAFT_COL_UIDS, [0]], ["_value", "", [""]]];

private _draft = uiNamespace getVariable [QGVAR(radioMembersDraft), []];
if (_draft isEqualTo [] || _value isEqualTo "") exitWith {};

private _list = _draft select _col;
_draft set [_col, [_list + [_value], _list - [_value]] select (_value in _list)];
uiNamespace setVariable [QGVAR(radioMembersDraft), _draft];
{["radio"] call EFUNC(tacpad,openApp)} call CBA_fnc_execNextFrame;
