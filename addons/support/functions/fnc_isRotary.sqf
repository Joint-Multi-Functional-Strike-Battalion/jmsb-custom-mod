#include "script_component.hpp"
/*
 * Author: YonV
 * Whether a support aircraft takes off, hovers and lands as a helicopter -
 * the scripted hover and landing, a pickup on the ground, a clear pad: a
 * helicopter (not a parachute, which config calls one), or a VTOL (user,
 * 2026-11-08: "vtol are not in the transport list"). A VTOL is a helicopter
 * for that only ("helo only in landing and take off"): beyond VTOL_PLANE_RANGE
 * it flies as a plane (jmfsb_support_air_fnc_moveTo, FUNC(flightHeight)).
 *
 * Arguments:
 * 0: The aircraft, or its class <OBJECT or STRING>
 *
 * Return Value:
 * Flies as a helicopter <BOOL>
 *
 * Example:
 * ["B_T_VTOL_01_infantry_F"] call jmfsb_support_fnc_isRotary
 *
 * Public: Yes
 */

params [["_what", objNull, [objNull, ""]]];

(ROTARY_KINDS findIf {_what isKindOf _x}) >= 0 && {!(_what isKindOf "ParachuteBase")}
