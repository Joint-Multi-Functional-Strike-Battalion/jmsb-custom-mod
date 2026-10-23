#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_pac_fnc_netPlanSync

Description:
    Server: makes every net of the plan (FUNC(netPlan)) in RF, at mission
    start and again whenever the plan changes (FUNC(radioApply)). RF makes
    the per-side keys when a net is created and keeps them when it is set
    again. DATA is RF's own and is not made here. Does nothing without RF.
    When the plan changed, every base station (FUNC(baseStation)) is
    registered again with the new plan's nets.

Parameters:
    None

Returns:
    Nothing

Example:
    [] call jmfsb_pac_fnc_netPlanSync

Author:
    JMSB
---------------------------------------------------------------------------- */

if (!isServer) exitWith {};
if (isNil QEFUNC(rf,netSet) || isNil QEGVAR(rf,nets)) exitWith {};

private _plan = [] call FUNC(netPlan);
if (_plan isEqualTo (missionNamespace getVariable [QGVAR(netPlanSent), []])) exitWith {};
GVAR(netPlanSent) = _plan;

{
    _x params ["_id", "_band"];
    [_id, [["name", _id], ["band", _band], ["source", "PAC radio plan"]]] call EFUNC(rf,netSet);
} forEach _plan;
INFO_1("%1 voice nets from the radio plan",count _plan);

// the base stations hold every plan net: give them the new plan's
{
    [_x] call FUNC(baseStationRegister);
} forEach (keys GVAR(baseStations));
