#include "script_component.hpp"
/*
 * Author: JMSB
 * The closest and furthest an asset can put its fires, from its own position
 * - the one pair the range check (FUNC(inRange)), the map rings (FUNC(overlay))
 * and the verdict before CONFIRM (FUNC(preview)) all read.
 *
 *   artillery           the tighter of the module's Minimum / Maximum Range and
 *                       what the charges reach: the full charge's arc at most,
 *                       and at high angle no closer than the lowest charge at
 *                       VA_MAX_ELEV
 *   cruise missiles     CM_MIN_RANGE to the missile's own reach
 *   loitering munitions 0 to what the airframe flies in its transit time
 *
 * Arguments:
 * 0: The module logic <OBJECT>
 *
 * Return Value:
 * [minimum (m), maximum (m)] <ARRAY>
 *
 * Example:
 * [_logic] call jmfsb_support_fires_fnc_gunRanges
 *
 * Public: No
 */

params [["_logic", objNull, [objNull]]];

if (isNull _logic) exitWith {[0, 0]};

switch (_logic getVariable [QGVAR(type), ""]) do {
    case TYPE_ARTY: {
        private _mv = _logic getVariable [QGVAR(muzzleVelocity), VA_DEF_MV];
        private _low = (VA_CHARGES select 0) * _mv;
        private _gunMin = [0, _low * _low * (sin (2 * VA_MAX_ELEV)) / GRAVITY] select (_logic getVariable [QGVAR(highAngle), true]);
        [
            (_logic getVariable [QGVAR(minRange), 0]) max _gunMin,
            (_logic getVariable [QGVAR(maxRange), 0]) min (_mv * _mv / GRAVITY)
        ]
    };
    case TYPE_CRUISE: {[CM_MIN_RANGE, _logic getVariable [QGVAR(reach), 0]]};
    case TYPE_LOITER: {[0, _logic getVariable [QGVAR(reach), 0]]};
    default {[0, 0]};
}
