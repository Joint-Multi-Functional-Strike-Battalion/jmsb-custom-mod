#include "script_component.hpp"
/*
 * Author: JMSB
 * The server end of QGVAR(order): hands an accepted request to the asset
 * type that flies it. The client already refused what it could
 * (FUNC(task)); each order function asks FUNC(available) again here, because
 * two requesters can send for the same aircraft in the same second.
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 * 1: Task token, or "rtb" <STRING>
 * 2: Target position ATL, [] for none <ARRAY>
 * 3: TAC//SUPPORT's parameter array <ARRAY>
 * 4: Who asked <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_logic, "SAD", _pos, [], player] call jmfsb_support_air_fnc_order
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]], ["_task", "", [""]], ["_pos", [], [[]]], ["_prm", [], [[]]], ["_requester", objNull, [objNull]]];

if (!isServer || {isNull _logic}) exitWith {};

INFO_3("order: %1 %2 at %3",_logic getVariable [ARR_2(QGVAR(callsign),"AIR")],_task,_pos);

switch (_logic getVariable [QGVAR(kind), ""]) do {
    case KIND_CAS: {_this call FUNC(casOrder)};
    case KIND_TRANSPORT: {_this call FUNC(transportOrder)};
    case KIND_LOGISTICS: {_this call FUNC(dropOrder)};
    case KIND_QRF: {_this call FUNC(qrfOrder)};
    default {WARNING_1("order: %1 is not an air module",_logic)};
};
