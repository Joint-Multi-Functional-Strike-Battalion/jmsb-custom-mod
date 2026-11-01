/*
    Author: JohnnyShootos (Edited by TheTimidShade)

    Description:
        Called locally on client to execute code sent remotely via admin panel

    Parameters:
        0: STRING - Code to compile and execute on local client
        
    Returns:
        NONE
*/

#include "\z\jmfsb\addons\adminpanel\script_component.hpp"

params [["_code", "", [""]], ["_owner", -1, [0]], ["_target", objNull, [objNull]]];

// WHO MAY RUN CODE HERE (review S3, 2026-10-31). Any client could remoteExec
// this at the server. Now: on the server the sender must be an admin by the
// server's own records; on a client only this machine or the server may send.
// Code for another player's machine goes to the server first (_target), which
// checks the admin and forwards it, so a client never has to judge one.
if (isServer && {!([] call EFUNC(common,senderIsAdmin))}) exitWith {
    WARNING_1("compileAndExec refused: machine %1 is not an admin",remoteExecutedOwner);
};
if (!isServer && {!([] call EFUNC(common,fromServer))}) exitWith {
    WARNING_1("compileAndExec refused: from machine %1, not the server",remoteExecutedOwner);
};

// WHO ASKED. remoteExecutedOwner is the machine that sent this, and it is the
// machine the answer has to go back to - the console showing the return value is
// not necessarily the console that has this code local.
if (isServer && {isRemoteExecuted}) then {_owner = remoteExecutedOwner};
if (_owner < 0) then {_owner = remoteExecutedOwner};
if (_owner isEqualTo 0) then {_owner = clientOwner};

if (!isNull _target && {!local _target}) exitWith {
    [_code, _owner] remoteExec ["admp_fnc_compileAndExec", _target];
};

private _compiledCode = compile _code;

// CALL, NOT SPAWN, so there IS a return value. Spawning threw the result away,
// which is why the panel could run code and never show what came back. Code that
// genuinely needs to suspend spawns itself - that still works inside a call, and
// it is the caller saying so rather than this deciding for them.
private _result = call _compiledCode;
private _line = format ["%1  %2", [profileName, "server"] select isDedicated, _result];

if (_owner isEqualTo clientOwner) then {
    [_line] call FUNC(execLog);
} else {
    [_line] remoteExecCall [QFUNC(execLog), _owner];
};
