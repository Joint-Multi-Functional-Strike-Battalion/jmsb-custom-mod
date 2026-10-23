#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: an RTO (or admin) makes a net (the jmfsb_voice_srvNetAdd event from
 * FUNC(netAdd)). The right is checked here, not trusted from the client -
 * FUNC(canFlash), the same test a FLASH call passes. The name is checked
 * (FUNC(customValid)), the count against the setting, then the net is made in
 * RF like a TEAM net, published, and given its own VON custom channel through
 * the adapter's "reserve" hook; with no channel left it is taken back and
 * refused. Every refusal is told to the caller (FUNC(netFailed)).
 *
 * The channel is asked for after the net is published, because the adapter
 * keys a channel by the net's kind (FUNC(netKind)), which this machine's plan
 * only knows once the net is in it.
 *
 * Arguments:
 * 0: Caller <OBJECT>
 * 1: Name as typed <STRING>
 * 2: Squads on it - callsigns, upper-cased by the caller <ARRAY of STRINGs>
 * 3: Players on it - UIDs <ARRAY of STRINGs>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "RECON 2", ["GHOST 1"], ["7656..."]] call jmfsb_voice_fnc_srvNetAdd
 *
 * Public: No
 */

params [["_caller", objNull, [objNull]], ["_name", "", [""]], ["_squads", [], [[]]], ["_uids", [], [[]]]];

if (!isServer || isNull _caller) exitWith {};

private _fnc_refuse = {
    params ["_reason"];
    [QGVAR(netFailed), [_reason, _name], _caller] call CBA_fnc_targetEvent;
};

if !([_caller] call FUNC(canFlash)) exitWith {[REASON_NOT_RTO] call _fnc_refuse};
([_name] call FUNC(customValid)) params ["_id", "_reason"];
if (_id isEqualTo "") exitWith {[_reason] call _fnc_refuse};
if (count GVAR(customNets) >= GVAR(customNetsMax)) exitWith {[REASON_FULL] call _fnc_refuse};

_squads = (_squads select {_x isEqualType ""}) apply {toUpper trim _x};
_uids = _uids select {_x isEqualType "" && _x isNotEqualTo ""};
GVAR(customNets) set [_id, [_id, _squads arrayIntersect _squads, _uids arrayIntersect _uids, getPlayerUID _caller, name _caller]];
[_id, [["name", _id], ["band", NET_BAND_TEAM], ["source", NET_SOURCE]]] call EFUNC(rf,netSet);
[] call FUNC(srvNetPublish);

// Its channel - an adapter without the hook (none today) is taken at its word.
private _reserved = [_id] call HOOK("reserve");
if (isNil "_reserved") then {_reserved = true};
if (_reserved isNotEqualTo true) exitWith {
    GVAR(customNets) deleteAt _id;
    [] call FUNC(srvNetPublish);
    [REASON_NO_CHANNEL] call _fnc_refuse;
};

INFO_3("RTO net %1 made by %2 (%3 squads)",_id,name _caller,count _squads);
