#include "script_component.hpp"
/* ----------------------------------------------------------------------------
Function: jmfsb_common_fnc_debugReply

Description:
    Prints a debug-command reply to the caller. System chat, never the
    jmfsb_notify stack - the stack is for players, this is for whoever is
    testing.

Parameters:
    _text   : STRING - the line.
    _target : OBJECT - who to tell. Optional, default the local player.

Author:
    JMSB
---------------------------------------------------------------------------- */
params [["_text", "", [""]], ["_target", objNull, [objNull]]];

if (isNull _target || {_target isEqualTo player}) exitWith {
    // Printed only for this machine's own call or the server's (review R1): a
    // client cannot write "[jmfsb]" lines into another player's chat.
    if (hasInterface && {[] call FUNC(fromServer)}) then { systemChat format ["[jmfsb] %1", _text] };
};

[_text, objNull] remoteExec [QFUNC(debugReply), _target];
