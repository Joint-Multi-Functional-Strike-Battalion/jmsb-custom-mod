#include "script_component.hpp"
/*
 * Author: JMSB
 * THE PAC NET PLAN AS TFAR SETS. The plan is jmfsb_pac_fnc_netPlan - the one
 * plan, for VON and TFAR alike - as [id, band, "sr" | "lr" | "a2g", slot].
 * Here each net gets:
 *
 *   - the TFAR set kind that carries it: "sr" nets the handheld, "lr" and
 *     "a2g" nets the long range sets (backpack, vehicle rack);
 *   - a channel (0-based) on that set: its slot when it has one (the tfarNets
 *     plan), else the next channel of its set kind no other net holds, in
 *     plan order (the VON plan's named nets); NO_CHANNEL when the set has no
 *     channel left - such a net is still a net, loaded by an explicit fill;
 *   - its voice kind (team, c2, a2g) and whether the channel is the plan's own
 *     slot (only a slotted net takes the plan's frequency list entry, see
 *     fnc_netFrequency).
 *
 * The same on every machine, since the plan is on every machine. Empty
 * without jmfsb_pac.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [[net id, band, set kind "sr" | "lr", channel, voice kind, slotted], ...] <ARRAY>
 *
 * Example:
 * [] call jmfsb_adapter_tfar_fnc_planNets
 *
 * Public: No
 */

if (isNil QEFUNC(pac,netPlan)) exitWith {[]};

private _plan = [] call EFUNC(pac,netPlan);
private _out = [];
private _taken = createHashMapFromArray [[NODE_SR, []], [NODE_LR, []]];

// slotted nets first, so a named net never takes a slot the plan gave away
{
    _x params [["_id", "", [""]], ["_band", "", [""]], ["_planKind", PLAN_SR, [""]], ["_slot", NO_CHANNEL, [0]]];
    if (_slot <= NO_CHANNEL) then {continue};
    private _set = [NODE_LR, NODE_SR] select (_planKind isEqualTo PLAN_SR);
    (_taken get _set) pushBackUnique _slot;
} forEach _plan;

{
    _x params [["_id", "", [""]], ["_band", "", [""]], ["_planKind", PLAN_SR, [""]], ["_slot", NO_CHANNEL, [0]]];
    if (_id isEqualTo "") then {continue};
    private _set = [NODE_LR, NODE_SR] select (_planKind isEqualTo PLAN_SR);
    private _kind = switch (_planKind) do {
        case PLAN_SR: {KIND_TEAM};
        case PLAN_A2G: {KIND_A2G};
        default {KIND_C2};
    };
    private _slotted = _slot > NO_CHANNEL;
    private _channel = _slot;
    if (!_slotted) then {
        private _count = [LR_CHANNELS, SR_CHANNELS] select (_set isEqualTo NODE_SR);
        private _used = _taken get _set;
        _channel = NO_CHANNEL;
        for "_c" from 0 to (_count - 1) do {
            if !(_c in _used) exitWith {_channel = _c};
        };
        if (_channel > NO_CHANNEL) then {_used pushBack _channel};
    };
    _out pushBack [_id, _band, _set, _channel, _kind, _slotted];
} forEach _plan;

_out
