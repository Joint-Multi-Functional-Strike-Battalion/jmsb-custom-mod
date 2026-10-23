#include "script_component.hpp"
/*
 * Author: JMSB
 * RF's link quality for the local player on one net: the best of his nodes
 * that hold it (jmfsb_rf_fnc_quality on each), or that one node's when a node
 * id is given. QUALITY_UNKNOWN when RF is not loaded, no node of his holds the
 * net, or RF has not answered yet - never zero, which would read as a cut.
 *
 * Arguments:
 * 0: Net id <STRING>
 * 1: Only this node <STRING> (optional, default "" = any of his)
 *
 * Return Value:
 * Quality 0..1, or QUALITY_UNKNOWN <NUMBER>
 *
 * Example:
 * private _data = [RADIO_NET_DATA] call jmfsb_tacpad_apps_fnc_radioRfQuality
 *
 * Public: No
 */

params [["_net", "", [""]], ["_only", "", [""]]];

if (_net isEqualTo "" || {isNil QEFUNC(rf,quality)}) exitWith {QUALITY_UNKNOWN};

private _best = QUALITY_UNKNOWN;
{
    _x params ["_node", "_nets"];
    if (_only isNotEqualTo "" && _node isNotEqualTo _only) then {continue};
    if !(_net in _nets) then {continue};
    private _q = [_node, _net] call EFUNC(rf,quality);
    if (_q > _best) then {_best = _q};
} forEach ([] call FUNC(radioRfNodes));

_best
