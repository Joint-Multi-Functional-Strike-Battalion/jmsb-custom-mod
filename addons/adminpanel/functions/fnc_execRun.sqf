#include "script_component.hpp"
/*
 * Author: YonV
 * RUN - fires the code box at whichever target was last chosen.
 *
 * THE THREE TARGET BUTTONS ARE NOW A CHOICE, NOT THREE TRIGGERS. SERVER, LOCAL
 * and REMOTE each ran the box immediately, which meant the only way to change
 * your mind about where code was going was to have already sent it somewhere.
 * They select; RUN sends. Ctrl+Enter in the box does the same thing.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_adminpanel_fnc_execRun
 *
 * Public: No
 */

// Server by default. It is the machine an admin means nine times in ten, and it
// is the one whose state the other two cannot fix.
[missionNamespace getVariable [QGVAR(execTarget), 1]] call admp_fnc_executeOnMachine;
