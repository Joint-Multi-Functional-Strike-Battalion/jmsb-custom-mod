#include "script_component.hpp"
/*
 * Author: JMSB
 * The block level from which a net can no longer be talked on: the radio
 * nets (TEAM, C2-kind, A2G, CALL) from radio silence, VEH from unconscious,
 * DIRECT only when dead or out of air. Anything else (Global, not one of
 * ours) is never closed here.
 *
 * Arguments:
 * 0: Net id <STRING>
 *
 * Return Value:
 * BLOCK_SILENCE, BLOCK_RADIO, BLOCK_ALL or BLOCK_NEVER <NUMBER>
 *
 * Example:
 * ["C2"] call jmfsb_voice_fnc_blockNeed
 *
 * Public: No
 */

params [["_net", "", [""]]];

private _kind = [_net] call FUNC(netKind);
if (_kind in MESH_KINDS) exitWith {BLOCK_SILENCE};
if (_kind isEqualTo KIND_VEH) exitWith {BLOCK_RADIO};
if (_kind isEqualTo KIND_DIRECT) exitWith {BLOCK_ALL};
BLOCK_NEVER
