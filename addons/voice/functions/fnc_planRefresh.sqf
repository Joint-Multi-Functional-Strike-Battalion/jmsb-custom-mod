#include "script_component.hpp"
/*
 * Author: JMSB
 * Re-reads the PAC net plan (jmfsb_pac_fnc_netPlan) into this machine's cache:
 * the voice kind of every plan net, which net carries which plan slot (VON
 * nets have none), and - emptied on every refresh - the per-squad answers of
 * jmfsb_pac_fnc_netPlanSquad (fnc_planNet). The plan is the one plan - voice
 * builds no second one: a plan short range net ("sr") is a squad's TEAM net
 * (VON Group channel), a long range net ("lr") a C2-kind net (the C2
 * channel), an air-to-ground net ("a2g") an A2G-kind net (the A2G channel).
 * pac makes the plan's nets in RF itself (jmfsb_pac_fnc_netPlanSync).
 * Without pac the cache is empty and every group gets its own TEAM net and
 * everyone the default C2 and A2G.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_voice_fnc_planRefresh
 *
 * Public: No
 */

GVAR(planSquad) = createHashMap;

private _plan = if (isNil QEFUNC(pac,netPlan)) then {[]} else {[] call EFUNC(pac,netPlan)};
// THE RTO's NETS RIDE ALONG (user, 2026-10-22: "allow rtos to add custom
// channels"): one row per net the server published, typed custom below, so
// netKind, the chips, the mesh and the roster know them like any plan net.
// The published list changes seldom and this runs every second, so the merge
// is cheap and needs no event of its own.
_plan = _plan + (GVAR(customPub) apply {[_x select CUSTOM_COL_ID, NET_BAND_TEAM, PLAN_CUSTOM, PLAN_CUSTOM_SLOT]});
if (_plan isEqualTo GVAR(plan)) exitWith {};
GVAR(plan) = _plan;

private _kinds = createHashMap;
private _slots = createHashMap;
{
    _x params ["_id", "", "_setKind", ["_slot", PLAN_NO_SLOT]];
    private _kind = switch (_setKind) do {
        case PLAN_SR: {KIND_TEAM};
        case PLAN_A2G: {KIND_A2G};
        case PLAN_CUSTOM: {KIND_CUSTOM};
        default {KIND_C2};
    };
    _kinds set [_id, _kind];
    if (_slot isEqualType 0 && {_slot > PLAN_NO_SLOT}) then {_slots set [_setKind + str _slot, _id]};
} forEach _plan;
GVAR(planKinds) = _kinds;
GVAR(planSlots) = _slots;
