#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "block", client: the cut-off level of the local player, applied
 * at once by fnc_channels (enableChannel, voice only). 0 none; 1 radio
 * silence (EMCON 3): Group and our custom channels closed; 2 unconscious:
 * the Vehicle channel too; 3 dead or out of air: Direct too. Vehicle and
 * Direct are put back as they were when the level falls.
 *
 * Arguments:
 * 0: Level 0..3 <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [2] call jmfsb_adapter_von_fnc_block
 *
 * Public: No
 */

params [["_level", BLOCK_NONE, [0]]];

GVAR(level) = _level;
[] call FUNC(channels);
