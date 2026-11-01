#define DEBUG_MODE
#include "script_component.hpp"
/*
 * Author: CPL.Brostrom.A, CPL.Dunn.W
 * This module function can disable ai set player weapon to safe and print some hints and spam the chat with ENDEX. 
 *
 * Arguments:
 * 0: modulePos <POSITION>
 * 1: objectPos <OBJECT>
 * 
 *
 * Example:
 * [getPos logic, this] call  jmfsb_zenmodules_fnc_callEndex;
 *
 * Public: No
 */

params ["_modulePos", "_objectPos"];

[
    "Call Endex", 
    [
        ["CHECKBOX", ["Call Endex", "False will end the endex"], true, false],
        ["CHECKBOX", ["Set Player Weapons To Safe", ""], true, false],
        ["CHECKBOX", ["Pacify AI", ""], true, false],
        ["CHECKBOX", ["Hint Players That Fire", ""], true, false],
        ["CHECKBOX", ["Heal all players", ""], true, false]
    ], 
    {
        params ["_arg", "_pos"];
        _arg params [
            "_endex",
            "_weaponsSafe",
            "_aiPacified",
            "_holdFireMessage",
            "_healAllPlayers"
        ];
        _pos params ["_modulePos"];

        // The server decides, sets the Endex flag, says it to everyone and
        // sends each machine its share - safety, healing, hold-fire, AI
        // orders - after checking this machine is a Zeus or an admin (review
        // S7). The flag and the notices used to be set from here, so any
        // client could set them.
        [_weaponsSafe, _aiPacified, _holdFireMessage, _healAllPlayers, _endex] remoteExecCall [QFUNC(endexRequest), SERVER_OWNER];
        if (!_endex) exitWith {
            ["Endex call-off sent"] call zen_common_fnc_showMessage;
        };

        // The server checks this sender too (review S7).
        [] remoteExecCall [QEFUNC(init,srvAttendance), SERVER_OWNER];

        ["Endex called"] call zen_common_fnc_showMessage;
    },
    {},
    [_modulePos]
] call zen_dialog_fnc_create;
