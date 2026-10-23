#include "script_component.hpp"
/*
 * Author: JMSB
 * The C2-kind net of a unit, carried on the C2 channel (VON Custom 1): his
 * net of the PAC plan (his squad's, or under the VON comm plan the first c2
 * row naming his squad, role or a skill of his), else the default plan's C2.
 * UNDER A VON COMM PLAN THERE IS NO DEFAULT (user, 2026-10-21: C2 is the
 * TLs, ATLs and HQ): a man no c2 row names is on no C2 net - "". One
 * VON channel can carry several such nets: the mesh volume is worked out on
 * the speaker's own net, so a listener not on it hears nothing.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Net id, "" for none <STRING>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_c2Net
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _plan = [_unit, PLAN_LR] call FUNC(planNet);
if (_plan isNotEqualTo "") exitWith {_plan};
// A VON plan's nets carry no slot; the tfarNets plan's always do.
private _von = (GVAR(plan) findIf {(_x param [3, 0]) isEqualTo PLAN_NO_SLOT}) >= 0;
["", NET_C2] select !_von
