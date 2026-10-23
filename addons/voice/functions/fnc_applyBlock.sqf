#include "script_component.hpp"
/*
 * Author: JMSB
 * Client, every frame and on the player's Killed / Respawn: the cut-offs.
 * When the block level (fnc_blockLevel) changes the adapter is told (its
 * "block" hook closes or reopens the channels), a transmission the new level
 * closes is ended (his key-up goes out), and when the level falls the PTT is
 * put back on the active net, so the channel state is what it was before.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] call jmfsb_voice_fnc_applyBlock
 *
 * Public: No
 */

([] call FUNC(blockLevel)) params ["_level", "_reason"];
GVAR(blockReason) = _reason;
if (_level isEqualTo GVAR(level)) exitWith {};

private _was = GVAR(level);
GVAR(level) = _level;
[_level] call HOOK("block");
TRACE_3("block level",_was,_level,_reason);

if (GVAR(keyNet) isNotEqualTo "" && {_level >= ([GVAR(keyNet)] call FUNC(blockNeed))}) then {
    [false] call FUNC(transmit);
};
if (_level < _was) then {[GVAR(activeNetId)] call HOOK("setActive")};
[QGVAR(netsChanged), []] call CBA_fnc_localEvent;
