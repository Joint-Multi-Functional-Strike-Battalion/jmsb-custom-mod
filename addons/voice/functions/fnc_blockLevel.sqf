#include "script_component.hpp"
/*
 * Author: JMSB
 * Client: how far the local player is cut off from transmitting, and why.
 * Dead, or unable to breathe (underwater without a rebreather): nothing, not
 * even Direct. Unconscious (lifeState "INCAPACITATED", which ACE's
 * unconsciousness sets too): no radio, the Vehicle intercom included; Direct
 * stays. Radio silence (EMCON 3 on one of his nodes): no radio nets.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [level 0..3 (BLOCK_NONE .. BLOCK_ALL), reason ("" for none)] <ARRAY>
 *
 * Example:
 * [] call jmfsb_voice_fnc_blockLevel
 *
 * Public: No
 */

if (isNull player) exitWith {[BLOCK_NONE, ""]};
if (!alive player) exitWith {[BLOCK_ALL, REASON_DEAD]};
if (!isAbleToBreathe player) exitWith {[BLOCK_ALL, REASON_NO_AIR]};
if ((lifeState player) isEqualTo LIFE_INCAPACITATED) exitWith {[BLOCK_RADIO, REASON_UNCONSCIOUS]};
if (GVAR(blocked)) exitWith {[BLOCK_SILENCE, REASON_SILENCE]};
[BLOCK_NONE, ""]
