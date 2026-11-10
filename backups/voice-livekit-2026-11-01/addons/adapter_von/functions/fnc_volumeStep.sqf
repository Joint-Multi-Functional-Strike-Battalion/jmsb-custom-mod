#include "script_component.hpp"
/*
 * Author: YonV
 * Radio voice volume up or down by one step (user, 2026-10-24: "need a volume
 * on the in game voip"). Writes the player's own CBA setting, so Addon Options,
 * the RADIO app and the keys all move the same knob; the setting's own change
 * handler re-applies every speaker's volume.
 *
 * Arguments:
 * 0: Step, signed, in volume units 0..1 <NUMBER>
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [0.1] call jmfsb_adapter_von_fnc_volumeStep
 *
 * Public: No
 */

params [["_delta", 0, [0]]];

private _next = 0 max (VOLUME_FULL min (round ((GVAR(masterVolume) + _delta) * PERCENT) / PERCENT));
if (_next isEqualTo GVAR(masterVolume)) exitWith {true};

if (isNil "CBA_settings_fnc_set") then {
    GVAR(masterVolume) = _next;
    GVAR(talkCh) = createHashMap;
} else {
    [QGVAR(masterVolume), _next, false, "client", true] call CBA_settings_fnc_set;
};

[NOTE_TITLE, format [NOTE_VOLUME, round (_next * PERCENT)]] call EFUNC(notify,notify);
true
