#include "script_component.hpp"
/*
 * Author: YonV
 * Whether the player can see AiTR vitals this frame: anyone wearing AiTR
 * goggles that ECOTI is drawing through (jmfsb_ecoti_fnc_isActive - powered,
 * the player's own AiTR setting on, not in the map or a dialog), with ACE
 * medical to read.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Active <BOOL>
 *
 * Example:
 * [] call jmfsb_medic_fnc_aitrOn
 *
 * Public: No
 */

GVAR(ace) && {!isNil QEFUNC(ecoti,isActive)} && {[] call EFUNC(ecoti,isActive)}
