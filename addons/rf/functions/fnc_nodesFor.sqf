#include "script_component.hpp"
/*
 * Author: JMSB
 * rf_nodesFor: the nodes a man holds (server). Every node whose holder is
 * the given unit - his radios as the adapters registered them, and any set
 * another mod registered with him as the holder - with the fill each holds.
 * The fill is a copy; changing it changes nothing in the registry.
 *
 * On a client the registry is empty, so this returns [] there; a client reads
 * its own nodes through jmfsb_rf_fnc_link, jmfsb_rf_fnc_reach and
 * jmfsb_rf_fnc_quality.
 *
 * Arguments:
 * 0: Holder <OBJECT>
 * 1: Owner tags to leave out (optional, default []) <ARRAY of STRINGs>
 *
 * Return Value:
 * [[node id, owner, profile id, fill [[net id, key], ...]], ...] <ARRAY>
 *
 * Example:
 * [player, ["jmfsb_drone40"]] call jmfsb_rf_fnc_nodesFor
 *
 * Public: Yes
 */

params [["_holder", objNull, [objNull]], ["_skipOwners", [], [[]]]];

if (isNull _holder) exitWith {[]};

private _out = [];
{
    if ((_y getOrDefault ["holder", objNull]) isNotEqualTo _holder) then {continue};
    private _owner = _y getOrDefault ["owner", ""];
    if (_owner in _skipOwners) then {continue};
    _out pushBack [_x, _owner, _y getOrDefault ["profile", ""], +(_y getOrDefault ["nets", []])];
} forEach GVAR(nodes);

_out
