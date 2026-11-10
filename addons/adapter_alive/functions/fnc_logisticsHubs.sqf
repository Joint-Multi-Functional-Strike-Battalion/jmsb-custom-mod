#include "script_component.hpp"
/*
 * Author: YonV
 * Every logistics hub LOGCOM runs supply from, as a hunt pool.
 *
 * ALiVE's supply network is ALIVE_ML_supplyNetwork (mil_logistics
 * fnc_ML.sqf:3181-3206, 14077-14107): an ALiVE hash keyed by FACTION, each
 * value a list of nodes [position, [deliveredProfileIDs], isHQ?]. The HQ node
 * is seeded from the commander's module position; every completed delivery
 * adds its destination as a node, merged with any node within 500 m. That is
 * the whole of "where their supply comes from", and it is exactly what a raid
 * on the rear should be pointed at.
 *
 * LOGCOM's own validity rule is kept (fnc_ML.sqf:1311-1320): a node counts
 * while it is the HQ or while at least one thing it delivered is still alive
 * in the profile system. A hub whose every delivery is dead is a hub the
 * enemy has stopped using.
 *
 * Side comes from the faction (ALiVE_fnc_factionSide), which is what LOGCOM
 * keys on - never from what stands there.
 *
 * Arguments: None
 *
 * Return Value:
 * [[id <STRING>, pos <ARRAY>, side <SIDE>, isHQ <BOOL>], ...] <ARRAY>
 * id is "hub_" + faction + "_" + index in that faction's node list.
 *
 * Example:
 * call jmfsb_adapter_alive_fnc_logisticsHubs
 *
 * Public: Yes
 */

if (!GVAR(ready) || {isNil "ALIVE_ML_supplyNetwork"}) exitWith {[]};
if !(ALIVE_ML_supplyNetwork isEqualType [] && {count ALIVE_ML_supplyNetwork > HASH_VALUES}) exitWith {[]};

private _out = [];
{
    private _faction = _x;
    private _nodes = (ALIVE_ML_supplyNetwork select HASH_VALUES) select _forEachIndex;
    if !(_nodes isEqualType []) then {continue};
    private _side = _faction call ALiVE_fnc_factionSide;

    {
        if !(_x isEqualType [] && {count _x >= 2}) then {continue};
        _x params ["_at", ["_delivered", [], [[]]], ["_isHQ", false, [false]]];
        if !(_at isEqualType [] && {count _at >= 2}) then {continue};

        private _live = _isHQ;
        if (!_live) then {
            _live = (_delivered findIf {
                private _p = [ALIVE_profileHandler, "getProfile", _x] call ALIVE_fnc_profileHandler;
                !isNil "_p"
            }) > -1;
        };
        if (!_live) then {continue};

        _out pushBack [format ["hub_%1_%2", _faction, _forEachIndex], _at, _side, _isHQ];
    } forEach _nodes;
} forEach (ALIVE_ML_supplyNetwork select HASH_KEYS);

_out
