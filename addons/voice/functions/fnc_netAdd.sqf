#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: asks the server for an RTO net (user, 2026-10-22: "allow rtos to
 * add custom channels"). What a client can tell is refused here with the
 * same words the server would use; the rest - the name, the count, the
 * channel - the server decides (FUNC(srvNetAdd)) and answers through
 * FUNC(netFailed) or by publishing the net, which the chips show within a
 * second (jmfsb_voice_netsChanged).
 *
 * Arguments:
 * 0: Name <STRING>
 * 1: Squads on it - callsigns <ARRAY of STRINGs>
 * 2: Players on it - UIDs <ARRAY of STRINGs>
 *
 * Return Value:
 * Sent <BOOL>
 *
 * Example:
 * ["recon 2", ["GHOST 1"], [getPlayerUID _unit]] call jmfsb_voice_fnc_netAdd
 *
 * Public: Yes
 */

params [["_name", "", [""]], ["_squads", [], [[]]], ["_uids", [], [[]]]];

if (!GVAR(active) || !hasInterface) exitWith {false};
if !([player] call FUNC(canManageNets)) exitWith {
    [REASON_NOT_RTO, _name] call FUNC(netFailed);
    false
};
if ((trim _name) isEqualTo "") exitWith {
    [REASON_BAD_NAME, _name] call FUNC(netFailed);
    false
};

[QGVAR(srvNetAdd), [player, _name, _squads apply {toUpper trim _x}, _uids]] call CBA_fnc_serverEvent;
true
