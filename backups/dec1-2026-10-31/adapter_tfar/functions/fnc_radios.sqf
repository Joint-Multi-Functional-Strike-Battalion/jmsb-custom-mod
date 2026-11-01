#include "script_component.hpp"
/*
 * Author: JMSB
 * The sets this player has, read from TFAR: the active short-range radio, a
 * long-range backpack, and the long-range rack of the vehicle seat he is in
 * (TFAR offers that only to crew seats). Man packs are TFAR's to have (user,
 * 2026-10-21: no man packs is game voice's rule only). One entry each:
 *
 *   [kind, object the antenna is on, profile, channel, monitor channel, on, radio]
 *
 * kind is "sr", "lr" or "veh"; channels are TFAR's 0-based indices,
 * NO_CHANNEL when the radio has no additional (monitor) channel; radio is
 * TFAR's handle for the set (the SR class, or the LR [object, id]), for
 * reading its channels' frequencies (fnc_radioNets).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Sets <ARRAY>
 *
 * Example:
 * [] call jmfsb_adapter_tfar_fnc_radios
 *
 * Public: No
 */

if (isNil "TFAR_fnc_activeSwRadio") exitWith {[]};

private _out = [];

// [nil] param [0, "", [""]] is "" for nil and for anything that is not a
// string, so one comparison covers all three cases the old chain checked.
private _sw = [call TFAR_fnc_activeSwRadio] param [0, "", [""]];
if (_sw isNotEqualTo "") then {
    private _parent = getText (configFile >> "CfgWeapons" >> _sw >> "tf_parent");
    if (_parent isEqualTo "") then {_parent = _sw};
    _out pushBack [
        NODE_SR, player, [NODE_SR, _parent] call FUNC(profileFor),
        _sw call TFAR_fnc_getSwChannel, _sw call TFAR_fnc_getAdditionalSwChannel, [_sw] call TFAR_fnc_radioOn, _sw
    ];
};

private _bag = player call TFAR_fnc_backpackLr;
if (!isNil "_bag" && {_bag isEqualType []}) then {
    _out pushBack [
        NODE_LR, player, [NODE_LR, typeOf (_bag select 0)] call FUNC(profileFor),
        _bag call TFAR_fnc_getLrChannel, _bag call TFAR_fnc_getAdditionalLrChannel, [_bag] call TFAR_fnc_radioOn, _bag
    ];
};

private _rack = player call TFAR_fnc_vehicleLr;
if (!isNil "_rack" && {_rack isEqualType []}) then {
    _out pushBack [
        NODE_VEH, _rack select 0, VEHICLE_PROFILE,
        _rack call TFAR_fnc_getLrChannel, _rack call TFAR_fnc_getAdditionalLrChannel, [_rack] call TFAR_fnc_radioOn, _rack
    ];
};

_out
