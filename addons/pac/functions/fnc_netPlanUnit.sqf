#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_netPlanUnit

Description:
    A man's net of the plan by kind - FUNC(netPlanSquad) for his squad, and
    under the VON comm plan his ROLE and SKILLS as well (user, 2026-10-21:
    "add c2 to all tl's and atl's and all of the hcc, a2g to all with the jfo
    skill").

    A VON net row is [net, kind, [squads], [roles], [skills]]. He is on the
    FIRST row of the kind that names his squad (his group's callsign), his
    role id (jmfsb_groups' YMF_role; a "<id>_t" testing copy answers to its
    base id) or a skill he holds (jmfsb_pac_skillIds). A row of the old three
    columns lists squads only. With no VON rows, and for the TEAM net ("sr"),
    the answer is the squad's (FUNC(netPlanSquad)).

Parameters:
    0: Unit <OBJECT>
    1: Kind "sr" | "lr" | "a2g" <STRING> (optional, default "sr")

Returns:
    Net id, "" when the plan has none for him <STRING>

Example:
    [player, "lr"] call jmfsb_pac_fnc_netPlanUnit

Author:
    JMSB
---------------------------------------------------------------------------- */

params [["_unit", objNull, [objNull]], ["_kind", NET_KIND_SR, [""]]];

if (isNull _unit || {isNull group _unit}) exitWith {""};
private _squad = toUpper trim groupId group _unit;

private _von = missionNamespace getVariable ["jmfsbFR_radio_vonNets", []];
if !(_von isEqualType []) then {_von = []};
_von = _von select {_x isEqualType [] && {(_x param [0, ""]) isEqualType ""} && {trim (_x param [0, ""]) isNotEqualTo ""}};
if (_von isEqualTo [] || _kind isEqualTo NET_KIND_SR) exitWith {[_squad, _kind] call FUNC(netPlanSquad)};
if (count _von > VON_MAX_NETS) then {_von resize VON_MAX_NETS};

private _role = toLower (_unit getVariable ["YMF_role", ""]);
private _suffix = count ROLE_TEST_SUFFIX;
if (count _role > _suffix && {(_role select [count _role - _suffix]) isEqualTo ROLE_TEST_SUFFIX}) then {
    _role = _role select [0, count _role - _suffix];
};
private _skills = (_unit getVariable [QGVAR(skillIds), []]) apply {toLower _x};

private _fnc_names = {
    params ["_row", "_col", "_fold"];
    ((_row param [_col, [], [[]]]) select {_x isEqualType ""}) apply {_x call _fold}
};
private _want = [VON_KIND_C2, VON_KIND_A2G] select (_kind isEqualTo NET_KIND_A2G);
private _at = _von findIf {
    (toLower (_x param [1, "", [""]])) isEqualTo _want
    && {
        _squad in ([_x, VON_COL_SQUADS, {toUpper trim _this}] call _fnc_names)
        || {_role isNotEqualTo "" && {_role in ([_x, VON_COL_ROLES, {toLower trim _this}] call _fnc_names)}}
        || {(([_x, VON_COL_SKILLS, {toLower trim _this}] call _fnc_names) findIf {_x in _skills}) >= 0}
    }
};
if (_at < 0) exitWith {""};
toUpper trim ((_von # _at) # 0)
