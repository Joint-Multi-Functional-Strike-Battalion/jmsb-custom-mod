#include "script_component.hpp"
/*
 * Author: JMSB
 * LOAD THE FILL: programs this player's TFAR sets from nets, never from
 * numbers. Every short-range set he carries gets the short-range fill, his
 * long-range backpack and the rack of the crew seat he is in get the
 * long-range fill (fnc_program; each net's frequency from fnc_netFrequency).
 * fnc_tune calls this at login, join and respawn; fnc_poll programs a new set
 * with the plan's fill itself (setting "Fill new sets from the plan").
 *
 * Nets that are not in the plan are remembered for this player
 * (GVAR(fillNets)), so their channels read back as nets (fnc_radioNets) and
 * RF hears about them on the next poll, which runs at once. RF only grades
 * nets it knows - the plan's; another net is carried at TFAR's own range.
 *
 * The active and additional channel are not moved: picking the net to talk on
 * is fnc_selectNet.
 *
 * Arguments:
 * 0: Short-range net id per channel, first = channel 1; "" leaves a channel <ARRAY> (default: the plan's)
 * 1: Long-range net id per channel <ARRAY> (default: the plan's)
 *
 * Return Value:
 * Nets loaded, short and long range, each once <ARRAY of STRING>
 *
 * Example:
 * [["ALPHA", "C2", "A2G"], ["LR 1", "LR 2"]] call jmfsb_adapter_tfar_fnc_fill
 * [] call jmfsb_adapter_tfar_fnc_fill
 *
 * Public: Yes
 */

params [["_srNets", [], [[]]], ["_lrNets", [], [[]]]];

if (!hasInterface || {isNull player} || {isNil "TFAR_fnc_radiosList"}) exitWith {[]};

private _plan = [] call FUNC(planNets);
{
    _x params ["_kind", "_nets"];
    private _known = GVAR(fillNets) getOrDefault [_kind, []];
    {
        private _id = _x;
        if !(_id isEqualType "") then {continue};
        if (_id isEqualTo "") then {continue};
        if ((_plan findIf {(_x select 0) isEqualTo _id && {(_x select 2) isEqualTo _kind}}) < 0) then {
            _known pushBackUnique _id;
        };
    } forEach _nets;
    GVAR(fillNets) set [_kind, _known];
} forEach [[NODE_SR, _srNets], [NODE_LR, _lrNets]];

private _loaded = [];
{
    _loaded append ([_x, NODE_SR, _srNets, _plan] call FUNC(program));
} forEach (player call TFAR_fnc_radiosList);

{
    if (!isNil "_x" && {_x isEqualType []}) then {
        _loaded append ([_x, NODE_LR, _lrNets, _plan] call FUNC(program));
    };
} forEach [player call TFAR_fnc_backpackLr, player call TFAR_fnc_vehicleLr];

_loaded = _loaded arrayIntersect _loaded;
[[], -1] call FUNC(poll);
INFO_1("fill loaded: %1",_loaded);
_loaded
