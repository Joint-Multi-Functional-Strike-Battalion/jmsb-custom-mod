#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: an ACM casualty evacuation on a player's machine (the
 * ACM_casualtyEvacuated handler in FUNC(eventHandlers)) - the original unit
 * leaves its slot in the dynamic groups.
 *
 * Reached by remoteExec (review R1). It was the "YMF_casualtyEvacuatedserver"
 * CBA event, so any client could have any player taken out of his group. The
 * original unit must be the sender's own player or no player at all - the
 * body the evacuation left behind.
 *
 * Arguments:
 * 0: The unit after the evacuation <OBJECT>
 * 1: The original unit <OBJECT>
 *
 * Return Value:
 * None
 *
 * Example:
 * [_unit, _originalUnit] remoteExecCall ["jmfsb_init_fnc_srvEvacuated", 2]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_originalUnit", objNull, [objNull]]];

if (!isServer || {isNull _originalUnit}) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_sender"];
if (isPlayer _originalUnit && _originalUnit isNotEqualTo _sender) exitWith {
    WARNING_2("CasualtyEvac","refused - machine %1 named player %2",_owner,name _originalUnit);
};

// Server side, so this was never a message anyone could read - it is a log line, and says so.
SHOW_SERVER_INFO("CasualtyEvac",FORMAT_2("Unit %1 has been evacuated. Original unit: %2",_unit,_originalUnit));
[_originalUnit] call EFUNC(groups,removeFromGroup);
