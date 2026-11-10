#include "script_component.hpp"
/*
 * Author: YonV
 * The server end of an order: reached by remoteExecCall from FUNC(task), it
 * checks who sent it and books the delivery (FUNC(deliver)) or recalls it.
 *
 * THE SERVER TRUSTS NOTHING THE CLIENT SAYS ABOUT WHO ASKED (review S6). The
 * requester is the sending machine's own player (EFUNC(common,sender)), and
 * the tasking tag gate (EFUNC(support,canTask)), the side of the module and
 * the whole of FUNC(check) - the cart and the capacity included - are run
 * again here for him. This happens at the top, before any delayed work:
 * there the sender is no longer known.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Task token, or "rtb" <STRING>
 * 2: Delivery point ATL, [] for none <ARRAY>
 * 3: TAC//SUPPORT's parameter array <ARRAY>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "AIRDROP", _pos, []] remoteExecCall ["jmfsb_support_logistics_fnc_order", 2]
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
    WARNING_2("order: refused - %1 from %2 is not a logistics module on the board",_logic,_requester);
};
// A refusal here goes to the sender alone, not on his side's rail - he may
// not be on the module's side at all.
private _assetId = format ["%1:%2", SUPPORT_KIND, _logic getVariable [QGVAR(id), -1]];
([_requester] call EFUNC(support,canTask)) params ["_may", "_gateWhy"];
if (!_may) exitWith {
    WARNING_2("order: refused - %1 may not task: %2",_requester,_gateWhy);
    [_assetId, false, _gateWhy, _requester] call EFUNC(support,ack);
};
([_logic, _task, _pos, _prm, _requester] call FUNC(check)) params ["_ok", "_why", "_at", "_cart"];
if (!_ok) exitWith {
    WARNING_2("order: refused for %1 - %2",_requester,_why);
    [_assetId, false, _why, _requester] call EFUNC(support,ack);
};

if (_task isEqualTo TASK_RTB) exitWith {
    INFO_2("order: %1 recalled by %2",_logic getVariable [ARR_2(QGVAR(callsign),DEF_CALLSIGN)],_requester);
    _logic setVariable [QGVAR(abort), true, true];
};

INFO_5("order: %1 %2 %3 at %4 for %5",_logic getVariable [ARR_2(QGVAR(callsign),DEF_CALLSIGN)],_task,_cart,_at,_requester);

[_logic, _task, _at, _prm, _requester, _cart] call FUNC(deliver);
