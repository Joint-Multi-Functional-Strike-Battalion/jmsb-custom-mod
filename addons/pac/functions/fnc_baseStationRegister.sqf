#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: (re)registers one base station in RF with the fill as the plan has
 * it now - every net id of FUNC(netPlan), plus DATA and the default plan's C2
 * (BASE_EXTRA_NETS; a net RF does not have is simply not meshed) - each under
 * its side's key, relay and TX on. FUNC(baseStation) calls it when the station
 * is made and FUNC(netPlanSync) again for every station when the plan
 * changes. RF's register is idempotent by id: the node keeps its state.
 *
 * Arguments:
 * 0: Base station id (FUNC(baseStation)) <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["base_1"] call jmfsb_pac_fnc_baseStationRegister
 *
 * Public: No
 */

params [["_id", "", [""]]];

if (!isServer || isNil QEFUNC(rf,register)) exitWith {};

private _entry = GVAR(baseStations) getOrDefault [_id, []];
if (_entry isEqualTo []) exitWith {};
_entry params ["_object", "_side", "_owner"];
if (isNull _object) exitWith {};

private _nets = (([] call FUNC(netPlan)) apply {_x select 0}) + BASE_EXTRA_NETS;
_nets = _nets arrayIntersect _nets;

[_object, BASE_PROFILE, _nets, _id, _owner, objNull, _side] call EFUNC(rf,register);
[_id, [["relay", true], ["tx", true]]] call EFUNC(rf,setState);
