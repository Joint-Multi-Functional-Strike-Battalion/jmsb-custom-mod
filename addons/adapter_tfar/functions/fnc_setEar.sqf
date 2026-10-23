#include "script_component.hpp"
/*
 * Author: JMSB
 * Voice hook "setEar", client: the ear a net plays in - TFAR's stereo setting
 * of the channel that carries it (the set's active or additional channel:
 * TFAR_fnc_setSwStereo / setAdditionalSwStereo, setLrStereo /
 * setAdditionalLrStereo). TFAR pans the voice itself.
 *
 * Arguments:
 * 0: Net id <STRING>
 * 1: Ear "L", "B" or "R" <STRING>
 *
 * Return Value:
 * Done <BOOL>
 *
 * Example:
 * ["C2", "L"] call jmfsb_adapter_tfar_fnc_setEar
 *
 * Public: No
 */

params [["_net", "", [""]], ["_ear", EAR_BOTH, [""]]];

private _slot = GVAR(slots) getOrDefault [_net, []];
private _stereo = TFAR_STEREO_EARS find _ear;
if (_slot isEqualTo [] || _stereo < 0) exitWith {false};
_slot params ["_kind", "_radio", "_additional"];

[_radio, _stereo] call ([
    [TFAR_fnc_setLrStereo, TFAR_fnc_setAdditionalLrStereo],
    [TFAR_fnc_setSwStereo, TFAR_fnc_setAdditionalSwStereo]
] select (_kind isEqualTo NODE_SR) select _additional);
[[], -1] call FUNC(poll);
true
