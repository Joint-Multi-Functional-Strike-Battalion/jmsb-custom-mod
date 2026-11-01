#include "script_component.hpp"
/*
 * Author: JMSB
 * TUNE HIS SETS FROM THE NET PLAN - the TFAR path of
 * jmfsb_players_fnc_setRadioChannel (at login, on joining a group, on respawn,
 * on a radio reset). Every set he carries is loaded with the plan's fill
 * (fnc_fill: each plan net's frequency, fnc_netFrequency, on its plan
 * channel); his own squad's net goes on the set's last channel when the plan
 * had no channel left for it; and they become the sets' active channels: his
 * TEAM net on the handheld, his long range net on the backpack / rack. The
 * handheld is the picked set.
 *
 * Arguments:
 * 0: His short range (TEAM) net, "" none <STRING>
 * 1: His long range net, "" none <STRING>
 *
 * Return Value:
 * Nets loaded <ARRAY of STRING>
 *
 * Example:
 * ["ALPHA", "LR 1"] call jmfsb_adapter_tfar_fnc_tune
 *
 * Public: Yes
 */

params [["_srNet", "", [""]], ["_lrNet", "", [""]]];

if (!hasInterface || {isNull player} || {isNil "TFAR_fnc_activeSwRadio"}) exitWith {[]};

private _plan = [] call FUNC(planNets);
private _fills = [];
{
    _x params ["_kind", "_mine"];
    private _count = [LR_CHANNELS, SR_CHANNELS] select (_kind isEqualTo NODE_SR);
    private _nets = [];
    _nets resize _count;
    _nets = _nets apply {""};
    {
        _x params ["_id", "", "_set", "_channel"];
        if (_set isEqualTo _kind && _channel > NO_CHANNEL && _channel < _count) then {_nets set [_channel, _id]};
    } forEach _plan;
    if (_mine isNotEqualTo "" && !(_mine in _nets)) then {_nets set [_count - 1, _mine]};
    _fills pushBack _nets;
} forEach [[NODE_SR, _srNet], [NODE_LR, _lrNet]];

private _loaded = _fills call FUNC(fill);
if (_srNet isNotEqualTo "") then {[_srNet, NODE_SR] call FUNC(selectNet)};
if (_lrNet isNotEqualTo "") then {[_lrNet, NODE_LR] call FUNC(selectNet)};
GVAR(activeKind) = NODE_SR;
[[], -1] call FUNC(poll);
INFO_3("tuned from the net plan: team %1, long range %2, loaded %3",_srNet,_lrNet,_loaded);
_loaded
