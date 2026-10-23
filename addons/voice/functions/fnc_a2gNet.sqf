#include "script_component.hpp"
/*
 * Author: JMSB
 * The A2G-kind net of a unit, carried on the A2G channel (VON Custom 2), ""
 * when he is on none. As with C2, one VON channel can carry several such
 * nets: the mesh volume is worked out on the speaker's own net.
 *
 * A2G IS PILOTS (user, 2026-10-20). A man in a pilot or copilot seat (his
 * jmfsb_voice_air, set by FUNC(airSeat) on seat changes only) is on his
 * squad's air-to-ground net of the PAC plan, else the plan's first a2g net,
 * else the default A2G. A man on the ground is on A2G as the plan lists him:
 * his squad's a2g net; with no a2g net in the plan at all (no pac, the old
 * tfarNets plan, a VON plan without an a2g row) the default plan puts
 * everyone on A2G; a plan with a2g nets that does not name his squad puts him
 * on none.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * Net id, "" for none <STRING>
 *
 * Example:
 * [player] call jmfsb_voice_fnc_a2gNet
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

private _plan = [_unit, PLAN_A2G] call FUNC(planNet);
if (_plan isNotEqualTo "") exitWith {_plan};

private _planA2g = GVAR(plan) select {(_x param [2, ""]) isEqualTo PLAN_A2G};
if (_unit getVariable [QGVAR(air), false]) exitWith {(_planA2g param [0, []]) param [0, NET_A2G]};
["", NET_A2G] select (_planA2g isEqualTo [])
