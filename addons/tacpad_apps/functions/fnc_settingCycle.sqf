#include "script_component.hpp"
/*
 * Author: JMSB
 * Steps a LIST CBA setting to the next or previous of its values, wrapping at
 * either end - the settings app's previous / next pair.
 *
 * Arguments:
 * 0: Setting name, the full jmfsb_..._name string <STRING>
 * 1: The setting's values, in its own order <ARRAY>
 * 2: Direction, 1 for next and -1 for previous <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [QEGVAR(devices,keyF1), ["", "comms", "squad"], 1] call jmfsb_tacpad_apps_fnc_settingCycle
 *
 * Public: No
 */

params [["_name", "", [""]], ["_values", [], [[]]], ["_dir", 1, [0]]];

private _count = count _values;
if (_count isEqualTo 0) exitWith {};

private _index = (_values find (missionNamespace getVariable [_name, _values select 0])) max 0;

[_name, _values select ((_index + _dir + _count) % _count)] call FUNC(setSetting);
