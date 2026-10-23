#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the RF nodes an operator's own set can hear - the HACK board's
 * NODES IN REACH as RF sees them (docs/DESIGN_TABLET_APPS.md, HACK).
 *
 * THROUGH RF'S PUBLIC CALLS ONLY. The men and vehicles inside hacking reach
 * that are fair game (the same netTargets rule FUNC(scanDevices) applies to
 * nets; never the operator's own group) are asked for the nodes they hold
 * (jmfsb_rf_fnc_nodesFor), and each node is priced from its transmitter into
 * the operator's best set (jmfsb_rf_fnc_budget, target -> operator: what he
 * would intercept). Nothing reads RF's registry.
 *
 * Each budget casts fresh, so the list stops at HACK_RF_MAX_NODES, nearest
 * holders first, and is only asked for while the HACK board is open
 * (QGVAR(rfReachAsk), every few seconds).
 *
 * Arguments:
 * 0: Operator <OBJECT>
 *
 * Return Value:
 * [[holder, node id, profile id, quality 0..1, own key, nets held], ...] <ARRAY>
 *
 * Example:
 * [player] call jmfsb_hacking_fnc_rfReach
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

if (!isServer || {isNull _unit} || {isNil QEFUNC(rf,nodesFor)} || {isNil QEFUNC(rf,budget)}) exitWith {[]};

private _mine = [_unit] call EFUNC(rf,nodesFor);
if (_mine isEqualTo []) exitWith {[]};

private _range = (missionNamespace getVariable [QGVAR(rh_max_range), RH_RANGE_DEF]) max HACK_DRONE_RANGE;
private _mySide = side group _unit;
private _myGroup = group _unit;
private _scope = GVAR(netTargets);

private _holders = (_unit nearEntities [HACK_RF_HOLDER_KINDS, _range]) select {
    private _theirSide = side group _x;
    private _hostile = _theirSide getFriend _mySide < HACK_HOSTILE_BELOW;
    private _civ = _theirSide isEqualTo civilian;
    alive _x
    && {(group _x) isNotEqualTo _myGroup}
    && {switch (_scope) do {
        case 1: {_hostile || _civ};
        case 2: {true};
        default {_hostile && {!_civ}};
    }}
};
_holders = _holders apply {[_unit distance _x, _x]};
_holders sort true;

private _out = [];
{
    _x params ["", "_holder"];
    {
        if (count _out >= HACK_RF_MAX_NODES) then {break};
        _x params ["_id", "", "_profile", ["_fill", [], [[]]]];
        private _best = 0;
        {
            private _b = [_id, _x select 0] call EFUNC(rf,budget);
            _best = _best max (_b param [2, 0]);
        } forEach _mine;
        // A key of its own - not the side's shared one - is a set that hides
        // even from its own side (a decoy, a rekeyed net).
        private _ownKey = (_fill findIf {(_x param [1, ""]) isNotEqualTo ""}) >= 0;
        _out pushBack [_holder, _id, _profile, _best, _ownKey, _fill apply {_x param [0, ""]}];
    } forEach ([_holder] call EFUNC(rf,nodesFor));
    if (count _out >= HACK_RF_MAX_NODES) then {break};
} forEach _holders;

_out
