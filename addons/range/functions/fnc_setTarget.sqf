#include "..\script_component.hpp"
/*
 * Author: YonV
 * Raises or drops a pop-up target.
 *
 * Arguments:
 * 0: Target <OBJECT>
 * 1: TARGET_UP or TARGET_DOWN <NUMBER>
 *
 * Return Value: None
 *
 * Public: No
 */

params [["_target", objNull, [objNull]], ["_state", TARGET_UP, [0]]];

if (isNull _target) exitWith {};

_target animate [TARGET_ANIM, _state];
