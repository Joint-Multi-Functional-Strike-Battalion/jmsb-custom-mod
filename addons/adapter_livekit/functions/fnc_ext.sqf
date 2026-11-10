#include "script_component.hpp"
/*
 * Author: YonV
 * Calls the jmsb_voice extension. The one place callExtension is used for it.
 *
 * Arguments:
 * 0: Command <STRING>
 * 1: Arguments <ARRAY> (default: [])
 *
 * Return Value:
 * [result, ran] - the extension's answer, and whether it ran without error
 * (false too when the extension is not loaded) <ARRAY>
 *
 * Example:
 * ["version"] call jmfsb_adapter_livekit_fnc_ext
 *
 * Public: No
 */

params [["_command", "", [""]], ["_args", [], [[]]]];

(VOICE_EXT callExtension [_command, _args]) params [["_result", "", [""]], ["_code", -1, [0]], ["_error", -1, [0]]];
TRACE_4("ext",_command,_result,_code,_error);
[_result, _code isEqualTo VOICE_EXT_OK && _error isEqualTo VOICE_EXT_OK]
