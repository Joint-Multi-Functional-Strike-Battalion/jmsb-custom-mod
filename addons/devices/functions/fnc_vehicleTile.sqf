#include "script_component.hpp"
/*
 * Author: JMSB
 * The VEHICLE live tile, which opens VEHICLE STATUS - on the vehicle tablet
 * and nowhere else. A tile provider for jmfsb_tacpad_apps' band
 * (jmfsb_tacpad_apps_tileProviders, registered in XEH_preInit): it answers no
 * tile at all unless the vehicle tablet is up and its app is registered, so
 * the large and UAV tablets, the phone and the native map's band never show it.
 *
 * Value is the vehicle's overall condition (100% less the worst part group),
 * the qualifier its fuel, the detail whichever of the two is worse - the worst
 * group by name, or FUEL LOW (damage wins a tie). Alert when a group is red or
 * the tank nearly dry, warn when one is amber or the tank is low, rest
 * otherwise - the tile band's own vocabulary.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Tile entries, [] or one [appId, kicker, qualifier, value, detail, state] <ARRAY>
 *
 * Example:
 * [] call jmfsb_devices_fnc_vehicleTile
 *
 * Public: No
 */

if (isNull (uiNamespace getVariable [QGVAR(display), displayNull])) exitWith {[]};
if (GVAR(device) isNotEqualTo VEHICLE_DEVICE || {isNull GVAR(vehicle)}) exitWith {[]};
if !(VEHICLE_APP in EGVAR(tacpad,appHandlers)) exitWith {[]};

private _vehicle = GVAR(vehicle);
private _damage = [_vehicle] call FUNC(vehicleDamage);
([_vehicle] call FUNC(vehicleFuel)) params ["_fuel"];

private _worst = ["", 0];
{
    _x params ["_label", "_damageOf"];
    if (_damageOf > (_worst select 1)) then {_worst = [_label, _damageOf]};
} forEach _damage;
_worst params ["_worstLabel", "_worstDamage"];

// 0 green, 1 amber, 2 red - for the state, and for which the detail names.
private _damageLevel = (parseNumber (_worstDamage >= DAMAGE_WARN)) + (parseNumber (_worstDamage >= DAMAGE_ALERT));
private _fuelLevel = (parseNumber (_fuel < FUEL_WARN)) + (parseNumber (_fuel < FUEL_ALERT));

private _state = switch (true) do {
    case (!alive _vehicle || {(_damageLevel max _fuelLevel) >= 2}): {"alert"};
    case ((_damageLevel max _fuelLevel) >= 1): {"warn"};
    default {"rest"};
};

[[
    VEHICLE_APP,
    "VEHICLE",
    format ["FUEL %1%2", round (_fuel * PERCENT), "%"],
    format ["%1%2", round ((1 - _worstDamage) * PERCENT), "%"],
    switch (true) do {
        case (!alive _vehicle): {"DESTROYED"};
        case (_fuelLevel > _damageLevel): {format ["FUEL LOW %1%2 - PRESS FOR STATUS", round (_fuel * PERCENT), "%"]};
        case (_damageLevel > 0): {format ["%1 %2%3 - PRESS FOR STATUS", _worstLabel, round ((1 - _worstDamage) * PERCENT), "%"]};
        default {"ALL GREEN - PRESS FOR STATUS"};
    },
    _state
]]
