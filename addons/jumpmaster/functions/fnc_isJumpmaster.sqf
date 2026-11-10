#include "script_component.hpp"
/*
 * Author: YonV
 * Whether the local player may ask for a jump: a squad leader or an admin by
 * the voice permission table (jmfsb_tacpad_apps_fnc_radioRole; user,
 * 2026-10-30: "for squad leaders only"). Since 2026-11-02 it gates the jump
 * aircraft's row (FUNC(assets)): nobody else sees it in TAC//MSG's TO picker
 * or @ list. The server asks its own question of the card (FUNC(srvThread)).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * May ask for a jump <BOOL>
 *
 * Example:
 * [] call jmfsb_jumpmaster_fnc_isJumpmaster
 *
 * Public: No
 */

([] call EFUNC(tacpad_apps,radioRole)) in JUMPMASTER_ROLES
