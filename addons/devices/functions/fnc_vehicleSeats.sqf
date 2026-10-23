#include "script_component.hpp"
/*
 * Author: JMSB
 * Everyone aboard a vehicle, by seat: commander first, passengers last, each
 * with the seat the vehicle tablet prints (CMDR, DRV, GNR, PAX) and the state
 * the squad rail reads off a man (OK, WIA, UNCON, KIA).
 *
 * ONE READ FOR BOTH SCREENS. The ON BOARD rail (FUNC(panelOnBoard)) draws it as
 * icons and VEHICLE STATUS (FUNC(appVehicle)) as words, so the two can never
 * put the same man in different seats.
 *
 * fullCrew: [unit, role, cargo index, turret path, person turret]. A person
 * turret is a man firing from a passenger seat, not a gunner.
 *
 * Arguments:
 * 0: The vehicle <OBJECT>
 *
 * Return Value:
 * One entry per man, in seat order: [order <NUMBER>, name <STRING>, seat <STRING>, man <OBJECT>, state <STRING>] <ARRAY>
 *
 * Example:
 * [vehicle player] call jmfsb_devices_fnc_vehicleSeats
 *
 * Public: No
 */

params [["_vehicle", objNull, [objNull]]];
if (isNull _vehicle) exitWith {[]};

private _roles = createHashMapFromArray SEAT_ROLES;
private _order = SEAT_ORDER;

private _seats = (fullCrew _vehicle) apply {
    _x params ["_man", "_role", "", "", ["_personTurret", false]];
    private _seat = if (_personTurret) then {SEAT_PAX} else {_roles getOrDefault [toLower _role, SEAT_PAX]};

    // The squad rail's status, from the same reads. ACE is optional: without
    // its medical the engine's own incapacitated state stands in.
    private _uncon = if (isNil QEFUNC(common,isUnconscious)) then {
        lifeState _man == "INCAPACITATED"
    } else {
        [_man] call EFUNC(common,isUnconscious)
    };
    private _state = switch (true) do {
        case (!alive _man): {CREW_KIA};
        case (_uncon): {CREW_UNCON};
        case (round ((1 - damage _man) * PERCENT) < ONBOARD_WIA_PCT): {CREW_WIA};
        default {CREW_OK};
    };

    [_order find _seat, toUpper name _man, _seat, _man, _state]
};
_seats sort true;

_seats
