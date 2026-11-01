#include "script_component.hpp"
/*
 * Author: JMSB
 * Server: Call Endex, or calls it off, asked for by the Zeus's machine
 * (FUNC(callEndex)) by remoteExec. It was a CBA global event, which carries
 * no sender, so any client could heal every player and make every AI group
 * careless (review S7). Here the server checks the sender holds a curator
 * module or is an admin by the server's own records, then:
 * - sets the Endex flag in its own localNamespace and publishes a copy for
 *   the hold-fire handlers (the Zeus's client used to publish it, so any
 *   client could);
 * - says it to everyone (notify rail, and the hint with the logo);
 * - on a call, sends the local share to every machine by remoteExec
 *   (FUNC(endexLocal)), which takes it only from the server.
 *
 * Arguments:
 * 0: Set player weapons to safe <BOOL>
 * 1: Pacify AI <BOOL>
 * 2: Hint players that fire <BOOL>
 * 3: Heal all players <BOOL>
 * 4: Call it (true) or call it off (false) <BOOL> (optional, default true)
 *
 * Return Value:
 * None
 *
 * Example:
 * [true, true, true, true, true] remoteExecCall ["jmfsb_zenmodules_fnc_endexRequest", 2]
 *
 * Public: No
 */

params [
    ["_weaponsSafe", false, [false]],
    ["_aiPacified", false, [false]],
    ["_holdFireMessage", false, [false]],
    ["_healAllPlayers", false, [false]],
    ["_endex", true, [true]]
];

if (!isServer) exitWith {};

([] call EFUNC(common,sender)) params ["_owner", "_unit"];
if (isNull (getAssignedCuratorLogic _unit) && {!([] call EFUNC(common,senderIsAdmin))}) exitWith {
    WARNING_2("ENDEX","refused - machine %1 (%2) is neither a Zeus nor an admin",_owner,_unit);
};

private _fnc_setFlag = {
    params ["_on"];
    localNamespace setVariable [QEGVAR(Mission,Endex), _on];
    missionNamespace setVariable [QEGVAR(Mission,Endex), _on, true];
    INFO_2("ENDEX","Mission var %1 is set %2",QEGVAR(Mission,Endex),_on);
};

if (!_endex) exitWith {
    if !(localNamespace getVariable [QEGVAR(Mission,Endex), false]) exitWith {
        INFO("ENDEX","No endex in progress");
    };
    ["ENDEX CANCELED", "The endex has been called off - carry on."] call JMFSBFUNC(notify,broadcast);
    // public, so the hold-fire handlers on the clients stop warning
    [false] call _fnc_setFlag;
};

INFO_1("ENDEX","called by %1",_unit);

["ENDEX ENDEX ENDEX", "Debrief - leaders debrief in the channel below."] call JMFSBFUNC(notify,broadcast);

// Stays a hint: the notification panel cannot carry the logo splash.
private _title = "<t color='#ffc61a' size='1.2' shadow='1' shadowColor='#000000' align='center'>ENDEX ENDEX ENDEX!</t><br />";
private _image = format ["<img size='5' image='%1' align='center'/><br /><br />", QPATHTOEF(media,images\logo_512.paa)];
private _text0 = "<t font='PuristaMedium' size='1.1'>Mission complete</t><br /><br />";
private _text1 = "Hold your fire and report to your Squad Leaders for debriefing.<br />";
private _text3 = "<t font='PuristaMedium' size='1.1'>Please safe your weapons if you haven't already!</t>";
parseText (_title + _text0 + _image + _text1 + _text3) remoteExecCall ["hint", TARGET_ALL];

// Set before the share goes out, and public, so the hold-fire handlers see it.
[true] call _fnc_setFlag;

[_weaponsSafe, _aiPacified, _holdFireMessage, _healAllPlayers] remoteExecCall [QFUNC(endexLocal), TARGET_ALL];
