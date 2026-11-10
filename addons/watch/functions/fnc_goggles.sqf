#include "script_component.hpp"
/*
 * Author: YonV
 * Whether the world-space hud may draw: the AiTR goggles drawing (ECOTI's own
 * test - powered, the player's AiTR setting on, no map or dialog). Without
 * ECOTI loaded there are no AiTR goggles and nothing is drawn in the world.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Drawing <BOOL>
 *
 * Example:
 * [] call jmfsb_watch_fnc_goggles
 *
 * Public: No
 */

!isNil QEFUNC(ecoti,isActive) && {[] call EFUNC(ecoti,isActive)}
