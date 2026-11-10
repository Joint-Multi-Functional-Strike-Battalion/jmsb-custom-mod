#include "script_component.hpp"
/*
 * Author: YonV
 * Client: a short word from the server about a callback (FUNC(srvCallback),
 * FUNC(srvCallbacks)), shown in the upper-right notification. Sent by
 * remoteExec and taken only from the server or this machine
 * (jmfsb_common_fnc_fromServer). This machine's own notes call
 * jmfsb_notify_fnc_notify directly (review R1: no jmfsb_voice_note event).
 *
 * Arguments:
 * 0: Title <STRING>
 * 1: Text <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["CALL BACK", "Too many callbacks pending."] remoteExecCall ["jmfsb_voice_fnc_note", _unit]
 *
 * Public: No
 */

params [["_title", "", [""]], ["_text", "", [""]]];

if (!hasInterface || {!([] call EFUNC(common,fromServer))}) exitWith {};

[_title, _text] call EFUNC(notify,notify);
