#include "script_component.hpp"
/*
 * Author: YonV
 * Does the device own its keys outright? In the F-row layout (GVAR(keyLayout))
 * every device keybind answers true even when it had nothing to do, so the
 * engine's own F1-F10 action - selecting squad members, the command menu -
 * never fires (user, 2026-11-08: "we do not need to select team members no ai
 * its all players"). The numpad layout keeps the old answers.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Owned <BOOL>
 *
 * Example:
 * ([0] call jmfsb_devices_fnc_overlayButton) || {[] call jmfsb_devices_fnc_keyOwned}
 *
 * Public: Yes
 */

GVAR(keyLayout) isNotEqualTo KEY_LAYOUT_NUMPAD
