#include "script_component.hpp"
/*
 * Author: YonV
 * Hook "block": the voice core's cut-off level changed (0 none, 1 radio
 * silence, 2 unconscious, 3 dead or out of air). The mic closes if its net
 * is now blocked (FUNC(mic)); what he hears follows on the next mix tick
 * (FUNC(gainOf)).
 *
 * Arguments:
 * 0: Level <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [2] call jmfsb_adapter_livekit_fnc_block
 *
 * Public: No
 */

params [["_level", BLOCK_NONE, [0]]];

GVAR(level) = _level;
[] call FUNC(mic);
