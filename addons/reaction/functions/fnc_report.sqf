#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: a client reports that its own player was noticed - a detectable
 * key-up (FUNC(onTransmit)) or a hack that failed on his tablet (jmfsb_hacking)
 * - and it goes through the one detection roll (FUNC(roll)).
 *
 * Review R1: this was the jmfsb_reaction_event CBA event, and any client could
 * raise it naming any unit to bring the enemy's reply down on him. Now the
 * unit must be the sender's own and the source one a client may report; the
 * server's own sources (drones, DF fixes, a remote hack's failure) call
 * FUNC(roll) directly.
 *
 * Arguments:
 * 0: The player <OBJECT>
 * 1: Source tag - "radio", "burnthrough" or "hack" <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "radio"] remoteExecCall ["jmfsb_reaction_fnc_report", 2]
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]], ["_source", "", [""]]];

if (!isServer || isNull _unit) exitWith {};
if !([_unit] call EFUNC(common,senderIs)) exitWith {
    WARNING_2("report: refused - machine %1 named %2",remoteExecutedOwner,_unit);
};
if !(_source in REACT_CLIENT_SOURCES) exitWith {
    WARNING_2("report: refused - machine %1 sent source '%2'",remoteExecutedOwner,_source);
};

[_unit, _source] call FUNC(roll);
