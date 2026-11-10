#include "script_component.hpp"
/*
 * Author: YonV
 * The CAS REQUEST's lines the game fills (docs/DESIGN_MESSAGE_TEMPLATES.md,
 * the true 9-line, 2026-11-09), worked out from the card being written - the
 * IP / BP (line 1) and the target (line 6), as the composer holds them (a
 * picked position, a marker's position or a typed grid, all read by
 * EFUNC(messaging,fieldPos)):
 *
 *   ipHeading         line 2, the bearing from the IP to the target - "075 DEG"
 *   ipDistance        line 3, the distance from the IP to the target - "4200 M"
 *   targetElevation   line 4, the ground at the target, metres above sea level
 *   friendlies        line 8, where the sender is from the target - "SW 450 M"
 *                     (his GPS when EW is loaded); the server still measures
 *                     the nearest friendlies itself
 *
 * "" when a point it needs is not there yet. FUNC(composeAutoFill) leaves a
 * line the player typed over alone and follows the points when they change.
 *
 * Arguments:
 * 0: The source <STRING>
 *
 * Return Value:
 * The line's text, "" for none <STRING>
 *
 * Example:
 * ["ipHeading"] call jmfsb_tacpad_fnc_autoCas
 *
 * Public: No
 */

params [["_source", "", [""]]];

private _fnc_point = {
    params ["_key"];
    private _v = GVAR(composeValues) getOrDefault [_key, ""];
    if !(_v isEqualTypeAny [[], ""]) exitWith {[]};
    if (_v isEqualTo "") exitWith {[]};
    [_v] call EFUNC(messaging,fieldPos)
};

private _target = [CAS_TARGET_KEY] call _fnc_point;
if (_target isEqualTo []) exitWith {""};

switch (_source) do {
    case AUTO_IP_HEADING: {
        private _ip = [CAS_IP_KEY] call _fnc_point;
        if (_ip isEqualTo []) exitWith {""};
        format [CAS_DEGREES_FORMAT, [round (_ip getDir _target), AUTO_BEARING_DIGITS] call CBA_fnc_formatNumber]
    };
    case AUTO_IP_DISTANCE: {
        private _ip = [CAS_IP_KEY] call _fnc_point;
        if (_ip isEqualTo []) exitWith {""};
        format [CAS_METRES_FORMAT, round (_ip distance2D _target)]
    };
    case AUTO_TARGET_ELEVATION: {
        format [CAS_METRES_FORMAT, round (getTerrainHeightASL [_target select 0, _target select 1])]
    };
    case AUTO_FRIENDLIES: {
        private _here = if (isNil QEFUNC(ew,gpsHere)) then {getPosATL player} else {[] call EFUNC(ew,gpsHere)};
        if (_here isEqualTo []) exitWith {""};
        private _dir = _target getDir _here;
        private _word = CAS_COMPASS select ((round (_dir / CAS_COMPASS_STEP)) mod (count CAS_COMPASS));
        format [CAS_FRIENDLIES_FORMAT, _word, round (_target distance2D _here)]
    };
    default {""};
}
