#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: sets who is on one of the RTO nets - both lists replaced
 * (FUNC(srvNetMembers) on the server). Refused here only for what a client
 * can tell; the server answers the rest through FUNC(netFailed) or the
 * publication.
 *
 * Arguments:
 * 0: Net id <STRING>
 * 1: Squads on it - callsigns <ARRAY of STRINGs>
 * 2: Players on it - UIDs <ARRAY of STRINGs>
 *
 * Return Value:
 * Sent <BOOL>
 *
 * Example:
 * ["RECON 2", ["GHOST 1"], []] call jmfsb_voice_fnc_netMembers
 *
 * Public: Yes
 */

params [["_id", "", [""]], ["_squads", [], [[]]], ["_uids", [], [[]]]];

if (!GVAR(active) || !hasInterface || _id isEqualTo "") exitWith {false};
if !([player] call FUNC(canManageNets)) exitWith {
    [REASON_NOT_RTO, _id] call FUNC(netFailed);
    false
};

[QGVAR(srvNetMembers), [player, _id, _squads apply {toUpper trim _x}, _uids]] call CBA_fnc_serverEvent;
true
