#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: the same threat warning to every player of a side - a new jammer,
 * spoofer or drone link one of its sensors heard is the whole side's news,
 * because its tracks are shared on the side.
 *
 * Arguments:
 * 0: Side, as str side <STRING>
 * 1: Kind <STRING>
 * 2: Detail <STRING>
 * 3: What to do <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["WEST", "JAMMER", "VHF JAMMER HEARD", "DF IT"] call jmfsb_ew_fnc_warnSide
 *
 * Public: No
 */

params [["_side", "", [""]], ["_kind", "", [""]], ["_detail", "", [""]], ["_advice", "", [""]]];

{
    if ((str side group _x) isEqualTo _side) then {
        [_x, _kind, _detail, _advice] call FUNC(warn);
    };
} forEach (allPlayers - entities "HeadlessClient_F");
