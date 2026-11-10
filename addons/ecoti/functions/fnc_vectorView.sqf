#include "script_component.hpp"
/*
 * Author: YonV
 * Is the player looking through a Vector right now? On foot, in the optics
 * view, with a Vector-family rangefinder (the unit's [JMSB] Vector Designator,
 * or any other ACE Vector) raised. The clip-on then reaches out to the Vector
 * range instead of the eye ranges (user, 2026-10-24: "if you use our vector
 * push it out to 750 meters").
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Looking through a Vector <BOOL>
 *
 * Example:
 * [] call jmfsb_ecoti_fnc_vectorView
 *
 * Public: No
 */

if (isNull player || {!isNull objectParent player}) exitWith {false};
if (cameraView isNotEqualTo "GUNNER") exitWith {false};

private _bino = binocular player;
if (_bino isEqualTo "" || {currentWeapon player isNotEqualTo _bino}) exitWith {false};

_bino isKindOf [VECTOR_BASE_CLASS, configFile >> "CfgWeapons"]
