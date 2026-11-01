#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_common_fnc_debugCommand

Description:
    Dispatches an admin chat command. Called from the chat addon's
    HandleChatMessage hook for every message; returns false immediately for
    anything that is not a `#jmfsb ` command from an admin, so ordinary chat is
    untouched.

    Server-side handlers are reached by remoteExec (FUNC(debugRunServer),
    which checks the sender is an admin) and reply back to the caller alone -
    the point is testing on a live dedicated server without telling the whole
    lobby what you are doing.

Parameters:
    _text   : STRING - the raw chat message.
    _sender : OBJECT - who typed it.

Returns:
    BOOL - true if the message was a command and should be swallowed.

Author:
    JMSB
---------------------------------------------------------------------------- */
params [["_text", "", [""]], ["_sender", objNull, [objNull]]];

if ((toLower _text) select [0, 7] isNotEqualTo DEBUG_PREFIX) exitWith { false };

// Never acknowledge the surface to a non-admin: swallow nothing, say nothing.
// The flag is the server's (FUNC(adminFlags)); the server checks again.
if !(_sender getVariable [QGVAR(isAdmin), false]) exitWith { false };

// Every machine sees the chat line (review B27): only the typer's runs it;
// the others just hide an admin's command.
if (_sender isNotEqualTo player) exitWith { true };

private _parts = (_text select [7]) splitString " ";
if (_parts isEqualTo []) exitWith {
    [format ["%1help for commands", DEBUG_PREFIX]] call FUNC(debugReply);
    true
};

private _name = toLower (_parts deleteAt 0);

// The table is this machine's own (localNamespace, FUNC(addDebugCommand)).
private _commands = localNamespace getVariable [QGVAR(debugCommands), createHashMap];

if (_name isEqualTo "help") exitWith {
    private _lines = [];
    {
        _y params ["_n", "_h"];
        _lines pushBack format ["  %1%2 - %3", DEBUG_PREFIX, _n, _h];
    } forEach _commands;
    _lines sort true;
    [format ["%1 commands:", count _lines]] call FUNC(debugReply);
    { [_x] call FUNC(debugReply) } forEach _lines;
    true
};

private _entry = _commands getOrDefault [_name, []];
if (_entry isEqualTo []) exitWith {
    [format ["unknown command '%1' - try %2help", _name, DEBUG_PREFIX]] call FUNC(debugReply);
    true
};

_entry params ["", "", "_code", "_local"];
diag_log text format ["[jmfsb] debug command '%1' %2 by %3", _name, _parts, name _sender];

if (_local) then {
    private _reply = [_parts, _sender] call _code;
    if (!isNil "_reply") then { [_reply] call FUNC(debugReply) };
} else {
    [_name, _parts] remoteExecCall [QFUNC(debugRunServer), SERVER_OWNER];
};

true
