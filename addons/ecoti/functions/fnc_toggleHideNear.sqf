#include "script_component.hpp"
/*
 * Author: JMSB
 * The hide-close-boxes key: flips the player's own hideNear setting, so no
 * box is drawn inside hideNearDistance (FUNC(updateCandidates)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Handled <BOOL>
 *
 * Example:
 * [] call jmfsb_ecoti_fnc_toggleHideNear
 *
 * Public: No
 */

private _on = !GVAR(hideNear);
[QGVAR(hideNear), _on, false, "client", true] call CBA_settings_fnc_set;
hintSilent (["AiTR: close boxes shown", format ["AiTR: no boxes inside %1 m", GVAR(hideNearDistance)]] select _on);

true
