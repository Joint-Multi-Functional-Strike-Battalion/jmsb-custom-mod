#include "script_component.hpp"
/*
 * Author: YonV
 * Chooses which machine the code box will run on, and says so.
 *
 * REMOTE names the man it means. "Remote" on its own is how code ends up on the
 * wrong client - the strip reads REMOTE  YONV, and if nothing is selected in
 * the player list it reads REMOTE  NONE and RUN will refuse.
 *
 * Arguments:
 * 0: Target - 0 selected client, 1 server, 2 local <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [1] call jmfsb_adminpanel_fnc_execTarget
 *
 * Public: No
 */

params [["_target", 1, [0]]];

GVAR(execTarget) = _target;

[] call FUNC(execTabs);
