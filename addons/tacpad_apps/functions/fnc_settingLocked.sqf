#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether a CBA setting is out of the player's hands - forced by the server or
 * the mission, so a value he writes would not take effect. The settings app
 * draws such a row read-only and FUNC(setSetting) refuses it, rather than
 * showing a change that CBA puts straight back.
 *
 * CBA answers which source wins a setting (client, mission or server); the
 * player's own value is in force only while that is the client's.
 *
 * Arguments:
 * 0: Setting name, the full jmfsb_..._name string <STRING>
 *
 * Return Value:
 * Locked <BOOL>
 *
 * Example:
 * [QEGVAR(devices,phoneZoom)] call jmfsb_tacpad_apps_fnc_settingLocked
 *
 * Public: No
 */

params [["_name", "", [""]]];

if (_name isEqualTo "" || {isNil "CBA_settings_fnc_priority"}) exitWith {false};

private _source = [_name] call CBA_settings_fnc_priority;

_source in ["mission", "server"]
