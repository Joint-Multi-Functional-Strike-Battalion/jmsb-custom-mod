#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_common_fnc_addDebugCommand

Description:
    Registers an admin chat command. Every jmfsb addon registers its own, so the
    dispatcher never has to know what exists.

    Commands are typed into any chat channel as `#jmfsb <name> [args...]` by a
    player holding the admin flag. The message is swallowed - it is never
    broadcast, and a non-admin typing the same thing gets no reply and no hint
    that the surface is there.

    The handler runs on the SERVER by default, which is what most test commands
    want (spawning, registry dumps, forcing module state). Pass _local for the
    ones that must run on the caller's machine - HUD tests, marker clears.

Parameters:
    _name    : STRING - command name, e.g. "ew.zones". Case-insensitive.
    _help    : STRING - one line shown by `#jmfsb help`.
    _code    : CODE   - handler. Receives [_args, _caller]:
                          _args   ARRAY of STRING, whatever followed the name
                          _caller OBJECT, the admin who typed it
                        Return a STRING to reply to the caller, or nil for none.
    _local   : BOOL   - true = run on the caller's machine. Optional, default false.

Returns:
    BOOL - true if registered, false if the name was already taken.

Example:
    ["ew.zones", "list live EW zones", {
        params ["_args", "_caller"];
        format ["%1 zones", count (call EFUNC(jamming,getZones))]
    }] call jmfsb_common_fnc_addDebugCommand

Author:
    JMSB
---------------------------------------------------------------------------- */
params [["_name", "", [""]], ["_help", "", [""]], ["_code", {}, [{}]], ["_local", false, [false]]];

if (_name isEqualTo "") exitWith { false };

// THE TABLE IS NOT NETWORKED (localNamespace, 2026-11-01): in missionNamespace
// any client could publicVariable it and swap a command's code, which the server
// then ran for the next admin who typed that command. Each machine registers its
// own commands at init, so nothing needs to cross the wire.
private _commands = localNamespace getVariable [QGVAR(debugCommands), createHashMap];
localNamespace setVariable [QGVAR(debugCommands), _commands];

private _key = toLower _name;
if (_key in _commands) exitWith {
    diag_log text format ["[jmfsb] debug command '%1' already registered - ignored", _name];
    false
};

_commands set [_key, [_name, _help, _code, _local]];
true
