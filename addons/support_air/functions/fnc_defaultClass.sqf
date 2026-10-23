#include "script_component.hpp"
/*
 * Author: JMSB
 * The vanilla aircraft a module with a blank class flies, by asset type and
 * side. A mission maker who wants "some CAS" and does not care which gets CAS.
 *
 * Arguments:
 * 0: Asset type - KIND_CAS, KIND_TRANSPORT, KIND_LOGISTICS, KIND_QRF <STRING>
 * 1: Side <SIDE>
 *
 * Return Value:
 * Vehicle class <STRING>
 *
 * Example:
 * ["cas", west] call jmfsb_support_air_fnc_defaultClass
 *
 * Public: No
 */

params [["_kind", "", [""]], ["_side", west, [west]]];

private _i = [west, east, independent] find _side;
if (_i < 0) then {_i = 0};

private _table = switch (_kind) do {
    case KIND_CAS: {["B_Plane_CAS_01_dynamicLoadout_F", "O_Plane_CAS_02_dynamicLoadout_F", "I_Plane_Fighter_03_dynamicLoadout_F"]};
    case KIND_TRANSPORT: {["B_Heli_Transport_01_F", "O_Heli_Light_02_unarmed_F", "I_Heli_Transport_02_F"]};
    default {["B_Heli_Transport_03_unarmed_F", "O_Heli_Transport_04_covered_F", "I_Heli_Transport_02_F"]};
};

_table select _i
