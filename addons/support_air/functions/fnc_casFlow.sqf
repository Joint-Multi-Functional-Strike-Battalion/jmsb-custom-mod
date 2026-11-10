#include "script_component.hpp"
/*
 * Author: YonV
 * Server: the CAS flow's keys for one strike order (2026-11-09,
 * docs/DESIGN_MESSAGE_TEMPLATES.md tree 3), set on a strike from station's
 * job or a helicopter run's sortie state (FUNC(casRetask), FUNC(srvThread)
 * through FUNC(casOrder) and FUNC(casLaunch)):
 *
 *   rb         RB_ASKED - the READBACK waits for CORRECT (FUNC(threadReply))
 *   control    the TYPE OF CONTROL, 1 2 3, 0 none - Type 3 is CLEARED TO
 *              ENGAGE and ATTACK COMPLETE
 *   leaveAt    the TOT less the dive (EFUNC(cas,totTime)), -1 none - the pass
 *              does not begin before it
 *   remarks    the restrictions the READBACK repeats
 *   ip         IP INBOUND said - a FRAGO is not taken after it
 *   inAsked    IN has asked the clearance for this pass
 *   engaged    cleared to engage (Type 3) - ATTACK COMPLETE after the pass
 *   dry        a CONTINUE's dry pass is under way
 *
 * Arguments:
 * 0: The order (EFUNC(support,readOrder), kind strike) <HASHMAP>
 *
 * Return Value:
 * [key, value] pairs <ARRAY>
 *
 * Example:
 * {_job set _x} forEach ([_order] call jmfsb_support_air_fnc_casFlow)
 *
 * Public: No
 */

params [["_order", createHashMap, [createHashMap]]];

private _tot = [_order getOrDefault ["tot", ""]] call EFUNC(cas,totTime);
[
    ["rb", RB_ASKED],
    ["control", _order getOrDefault ["control", 0]],
    ["leaveAt", [-1, _tot - CAS_TOT_LEAD] select (_tot >= 0)],
    ["remarks", _order getOrDefault ["remarks", ""]],
    ["ip", false],
    ["inAsked", false],
    ["engaged", false],
    ["dry", false]
]
