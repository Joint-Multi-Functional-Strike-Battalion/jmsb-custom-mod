#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "setMute", client: mutes or unmutes the radio on that net -
 * its ACRE volume (acre_api_fnc_setRadioVolume) to 0, and back to what it was
 * (full when nothing was kept).
 *
 * Arguments:
 * 0: Net id <STRING>
 * 1: Muted <BOOL>
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * ["ALPHA", true] call jmfsb_adapter_acre_fnc_setMute
 *
 * Public: No
 */

params [["_net", "", [""]], ["_muted", true, [true]]];

private _radioId = GVAR(slots) getOrDefault [_net, ""];
if (_radioId isEqualTo "") exitWith {false};

if (_muted) then {
    private _volume = [_radioId] call acre_api_fnc_getRadioVolume;
    if (_volume > VOLUME_MUTED) then {GVAR(volumes) set [_radioId, _volume]};
    [_radioId, VOLUME_MUTED] call acre_api_fnc_setRadioVolume;
} else {
    [_radioId, GVAR(volumes) getOrDefault [_radioId, VOLUME_FULL]] call acre_api_fnc_setRadioVolume;
    GVAR(volumes) deleteAt _radioId;
};
[] call FUNC(voiceView);
true
