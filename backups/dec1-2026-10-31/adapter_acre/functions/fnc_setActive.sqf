#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "setActive", client: puts the radio on that net in his hand
 * (acre_api_fnc_setCurrentRadio), so ACRE's own push-to-talk keys it.
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * ["ALPHA"] call jmfsb_adapter_acre_fnc_setActive
 *
 * Public: No
 */

params [["_net", "", [""]]];

private _radioId = GVAR(slots) getOrDefault [_net, ""];
if (_radioId isEqualTo "") exitWith {false};
if !([_radioId] call acre_api_fnc_setCurrentRadio) exitWith {false};
[] call FUNC(voiceView);
true
