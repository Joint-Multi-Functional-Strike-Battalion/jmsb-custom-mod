#include "script_component.hpp"
/*
 * Author: YonV
 * Server: marks a building for every AiTR, or takes its mark off (user,
 * 2026-11-06: "a way in 3den, zeus and by players to make a building that
 * this is highlighted in ecoti"). The server's list lives in localNamespace,
 * which is not networked, and a copy is published for the draws
 * (FUNC(markPublish)) - the teleport list's shape (review S7).
 *
 * From the Eden / Zeus module (FUNC(moduleMark)), a Zeus's dialog
 * (FUNC(zenMark)) and a player's key (FUNC(markPick)) by remoteExecCall. Any
 * player may mark: it is what he sees and tells. A remote call must come from
 * a machine with a player.
 *
 * Arguments:
 * 0: Building <OBJECT>
 * 1: Colour, an index into MARK_COLOURS; MARK_CLEAR takes the mark off <NUMBER>
 * 2: Label, "" for MARK_DEFAULT_LABEL <STRING> (optional, default "")
 *
 * Return Value:
 * None
 *
 * Example:
 * [_house, 0, "OBJ ALPHA"] remoteExecCall ["jmfsb_ecoti_fnc_markSet", 2]
 *
 * Public: Yes
 */

params [["_building", objNull, [objNull]], ["_colour", MARK_CLEAR, [0]], ["_label", "", [""]]];

if (!isServer || {isNull _building}) exitWith {};
if (isRemoteExecuted && {isNull (([] call EFUNC(common,sender)) select 1)}) exitWith {
    WARNING_1("markSet: refused - machine %1 has no player",remoteExecutedOwner);
};

private _list = (localNamespace getVariable [QGVAR(marks), []]) select {!isNull (_x select 0) && {(_x select 0) isNotEqualTo _building}};
if (_colour >= 0 && {_colour < count MARK_COLOURS}) then {
    // Drawn as structured text: no markup gets in.
    private _text = (toUpper (trim _label) regexReplace ["[<>&]", ""]) select [0, MARK_LABEL_MAX];
    _list pushBack [_building, _colour, [_text, MARK_DEFAULT_LABEL] select (_text isEqualTo "")];
};
localNamespace setVariable [QGVAR(marks), _list];
[] call FUNC(markPublish);
