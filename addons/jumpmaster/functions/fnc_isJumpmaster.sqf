#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether the local player may run a jump: a squad leader or an admin by the
 * voice permission table (jmfsb_tacpad_apps_fnc_radioRole; user, 2026-10-30:
 * "for squad leaders only").
 *
 * Arguments:
 * None
 *
 * Return Value:
 * May run a jump <BOOL>
 *
 * Example:
 * [] call jmfsb_jumpmaster_fnc_isJumpmaster
 *
 * Public: No
 */

([] call EFUNC(tacpad_apps,radioRole)) in JUMPMASTER_ROLES
