#include "..\script_component.hpp"
/*
 * Author: YonV
 * Whether a pop-up target is down, or on its way down or up.
 *
 * Arguments:
 * 0: Target <OBJECT>
 *
 * Return Value:
 * Down <BOOL>
 *
 * Public: No
 */

params [["_target", objNull, [objNull]]];

(_target animationPhase TARGET_ANIM) > 0
