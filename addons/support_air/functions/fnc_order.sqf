#include "script_component.hpp"
/*
 * Author: JMSB
 * The server end of an order: reached by remoteExec from FUNC(task), it
 * checks who sent it and hands it to the asset type that flies it.
 *
 * THE SERVER TRUSTS NOTHING THE CLIENT SAYS ABOUT WHO ASKED (review S6). The
 * requester is the sending machine's own player (EFUNC(common,sender)), and
 * the tasking tag gate (EFUNC(support,canTask)), the side of the module and
 * the whole of FUNC(check) are run again here for him - a client can call
 * this without passing FUNC(task). This happens at the top, before any
 * delayed work: there the sender is no longer known.
 *
 * Each order function asks FUNC(available) again too, because two
 * requesters can send for the same aircraft in the same second.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Task token, or "rtb" <STRING>
 * 2: Target position ATL, [] for none <ARRAY>
 * 3: TAC//SUPPORT's parameter array <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "SAD", _pos, []] remoteExecCall ["jmfsb_support_air_fnc_order", 2]
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]]];

if (!isServer || {isNull _logic}) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_requester"];
if (isNull _requester) exitWith {
    WARNING_2("order: refused - machine %1 has no player (%2)",_owner,_task);
};
if !(_logic in (missionNamespace getVariable [QGVAR(entities), []])) exitWith {
    WARNING_2("order: refused - %1 from %2 is not an air module on the board",_logic,_requester);
};
// A refusal here goes to the sender alone, not on his side's rail - he may
// not be on the module's side at all.
private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];
([_requester] call EFUNC(support,canTask)) params ["_may", "_gateWhy"];
if (!_may) exitWith {
    WARNING_2("order: refused - %1 may not task: %2",_requester,_gateWhy);
    [_assetId, false, _gateWhy, _requester] call EFUNC(support,ack);
};
([_logic, _task, _pos, _prm, _requester] call FUNC(check)) params ["_ok", "_why", "_at"];
if (!_ok) exitWith {
    WARNING_2("order: refused for %1 - %2",_requester,_why);
    [_assetId, false, _why, _requester] call EFUNC(support,ack);
};

INFO_4("order: %1 %2 at %3 for %4",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_task,_at,_requester);

private _args = [_logic, _task, _at, _prm, _requester];
switch (_logic getVariable [QGVAR(kind), ""]) do {
    case KIND_CAS: {_args call FUNC(casOrder)};
    case KIND_TRANSPORT: {_args call FUNC(transportOrder)};
    case KIND_LOGISTICS: {_args call FUNC(dropOrder)};
    case KIND_QRF: {_args call FUNC(qrfOrder)};
    default {WARNING_1("order: %1 is not an air module",_logic)};
};
