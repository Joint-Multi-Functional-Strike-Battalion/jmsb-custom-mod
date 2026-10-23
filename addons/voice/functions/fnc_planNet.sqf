#include "script_component.hpp"
/*
 * Author: JMSB
 * A unit's net of the PAC plan by kind - short range (his TEAM net), long
 * range (his C2-kind net) or air-to-ground - for the squad named by his
 * group's callsign - and, under the VON comm plan, his role and skills
 * (2026-10-21). With jmfsb_pac_fnc_netPlanUnit (the VON plan and the old
 * tfarNets slots alike) its answer is used, cached per squad, role, skills and
 * kind until the next plan refresh, and only when the plan lists that net (pac makes
 * the plan's nets in RF; a name it does not list is no plan net). Without
 * it: the tfarNets row named after his callsign gives the slot, else the
 * plan's fallback slot, and the net is the plan net on that slot (squads
 * sharing a slot share its net); that plan has no air-to-ground nets.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Plan kind "sr" | "lr" | "a2g" <STRING>
 *
 * Return Value:
 * Net id, "" when the plan has none for him <STRING>
 *
 * Example:
 * [player, "lr"] call jmfsb_voice_fnc_planNet
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_kind", PLAN_SR, [""]]];

if (count GVAR(planKinds) == 0 || isNull group _unit) exitWith {""};
private _callsign = toUpper groupId group _unit;

if (!isNil QEFUNC(pac,netPlanUnit)) exitWith {
    private _key = format ["%1|%2|%3|%4", _callsign, _unit getVariable ["YMF_role", ""], _unit getVariable [QEGVAR(pac,skillIds), []], _kind];
    private _net = GVAR(planSquad) get _key;
    if (isNil "_net") then {
        _net = [_unit, _kind] call EFUNC(pac,netPlanUnit);
        if (!(_net isEqualType "") || {!(_net in GVAR(planKinds))}) then {_net = ""};
        GVAR(planSquad) set [_key, _net];
    };
    _net
};

if (_kind isEqualTo PLAN_A2G) exitWith {""};
private _rows = missionNamespace getVariable [PLAN_ROWS_VAR, []];
if !(_rows isEqualType []) then {_rows = []};
private _i = _rows findIf {_x isEqualType [] && {toUpper (_x param [0, ""]) isEqualTo _callsign}};

private _slot = PLAN_NO_SLOT;
if (_i >= 0) then {
    _slot = (_rows select _i) param [[PLAN_COL_LR, PLAN_COL_SR] select (_kind isEqualTo PLAN_SR), PLAN_NO_SLOT];
} else {
    _slot = missionNamespace getVariable [[PLAN_FALLBACK_LR, PLAN_FALLBACK_SR] select (_kind isEqualTo PLAN_SR), PLAN_NO_SLOT];
};
if (!(_slot isEqualType 0) || {_slot <= PLAN_NO_SLOT}) exitWith {""};

GVAR(planSlots) getOrDefault [_kind + str _slot, ""]
