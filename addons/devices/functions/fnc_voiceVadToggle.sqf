#include "script_component.hpp"
/*
 * Author: YonV
 * The voice activation key - numpad 7 in the numpad standard (user,
 * 2026-10-24: "toggle voice activation"): flips the VON adapter's own player
 * setting (jmfsb_adapter_von_vad) and says which way it went. Without the
 * adapter it says so instead.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Acted <BOOL>
 *
 * Example:
 * [] call jmfsb_devices_fnc_voiceVadToggle
 *
 * Public: No
 */

if (isNil QEGVAR(adapter_von,vad)) exitWith {
    // No addon name on the screen (tablet review 2026-11-01, 2.1).
    ["VOICE", "Voice activation needs the game voice adapter, which is not loaded."] call EFUNC(notify,notify);
    false
};

private _on = !EGVAR(adapter_von,vad);
if (isNil "CBA_settings_fnc_set") then {
    EGVAR(adapter_von,vad) = _on;
} else {
    [QEGVAR(adapter_von,vad), _on, false, "client", true] call CBA_settings_fnc_set;
};

["VOICE", ["Voice activation OFF - push to talk.", "Voice activation ON - set Arma's VON to voice activation too (Options > Audio)."] select _on] call EFUNC(notify,notify);
true
