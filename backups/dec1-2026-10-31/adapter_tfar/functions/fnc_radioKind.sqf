#include "script_component.hpp"
/*
 * Author: JMSB
 * Which of this player's nodes a TFAR radio is: the short-range set, the
 * long-range backpack, or the long-range rack of his vehicle - the "kind" in
 * the node id (NODE_ID_FORMAT), as fnc_radios names them.
 *
 * Arguments:
 * 0: Radio, as TFAR's tangent events pass it: the SR class, or [object, id] <STRING or ARRAY>
 * 1: TFAR radio type, 0 short range, 1 long range <NUMBER>
 *
 * Return Value:
 * "sr" | "lr" | "veh" <STRING>
 *
 * Example:
 * [_radio, 1] call jmfsb_adapter_tfar_fnc_radioKind
 *
 * Public: No
 */

params [["_radio", "", ["", []]], ["_type", TFAR_TYPE_SR, [0]]];

if (_type == TFAR_TYPE_SR) exitWith {NODE_SR};
if (_radio isEqualTo (player call TFAR_fnc_backpackLr)) exitWith {NODE_LR};
NODE_VEH
