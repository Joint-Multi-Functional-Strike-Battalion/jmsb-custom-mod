#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "setEar", client: the ear the radio on that net plays in - its
 * ACRE spatial zone (acre_api_fnc_setRadioSpatial: LEFT, CENTER, RIGHT).
 *
 * Arguments:
 * 0: Net id <STRING>
 * 1: Ear "L", "B" or "R" <STRING>
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * ["ALPHA", "L"] call jmfsb_adapter_acre_fnc_setEar
 *
 * Public: No
 */

params [["_net", "", [""]], ["_ear", EAR_BOTH, [""]]];

private _radioId = GVAR(slots) getOrDefault [_net, ""];
private _at = ACRE_SPATIAL findIf {(_x select 1) isEqualTo _ear};
if (_radioId isEqualTo "" || _at < 0) exitWith {false};
if !([_radioId, (ACRE_SPATIAL select _at) select 0] call acre_api_fnc_setRadioSpatial) exitWith {false};
[] call FUNC(voiceView);
true
