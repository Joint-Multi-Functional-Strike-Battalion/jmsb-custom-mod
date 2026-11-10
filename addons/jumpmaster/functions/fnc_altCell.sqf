#include "script_component.hpp"
/*
 * Author: YonV
 * THE FREEFALL READOUT on the phone's status row (user, 2026-10-30:
 * "altitude and sink rate, so you know when to pull"): height over the
 * ground and the rate of fall while the player falls free - amber from the
 * HALO pull altitude down, red at half of it - and the height alone under
 * a canopy. Nothing on the ground or in an aircraft. Offered to
 * jmfsb_devices as the ALT provider; FUNC(altWatch) puts it first in the
 * row for the jump.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * [icon word, value, state] - jmfsb_devices' cell <ARRAY>
 *
 * Example:
 * [] call jmfsb_jumpmaster_fnc_altCell
 *
 * Public: No
 */

private _me = call CBA_fnc_currentUnit;
if (isNull _me || {!alive _me}) exitWith {[ALT_ICON, "--", JM_STATE_OFF]};

private _veh = objectParent _me;
private _canopy = !isNull _veh && {_veh isKindOf "ParachuteBase"};
if (!isNull _veh && !_canopy) exitWith {[ALT_ICON, "--", JM_STATE_OFF]};

private _agl = (getPosATL _me) select 2;
if (_canopy) exitWith {[ALT_ICON, format ["%1 M CANOPY", round _agl], JM_STATE_OK]};
if (_agl < ALT_MIN_AGL || {isTouchingGround _me}) exitWith {[ALT_ICON, "--", JM_STATE_OFF]};

private _sink = -((velocity _me) select 2);
private _state = switch (true) do {
    case (_agl <= GVAR(haloOpenAltitude) * ALT_PULL_K): {JM_STATE_ALERT};
    case (_agl <= GVAR(haloOpenAltitude)): {JM_STATE_WARN};
    default {JM_STATE_OK};
};

[ALT_ICON, format ["%1 M %2 M/S", round _agl, round _sink], _state]
