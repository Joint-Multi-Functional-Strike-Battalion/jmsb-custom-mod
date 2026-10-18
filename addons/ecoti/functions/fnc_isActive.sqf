#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether ECOTI is drawing this frame. Every condition has to hold; the moment
 * one fails the overlay goes with it.
 *
 * AiTR enabled (the player's own setting), powered on, the player alive and the camera (on foot or in his vehicle), not
 * in Zeus, the map not open, and wearing an NVG that opts in with jmfsb_ecoti_enabled = 1:
 *
 *   in NVG mode always
 *   in day mode too when it also says jmfsb_ecoti_day = 1 - the AiTR goggles
 *   (compatibility/aitr_goggles_*, user 2026-10-17: "work with or without nvg's")
 *
 * Never in thermal, which already shows heat.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Active <BOOL>
 *
 * Example:
 * [] call jmfsb_ecoti_fnc_isActive
 *
 * Public: Yes
 */

if (!GVAR(aitr) || {!GVAR(powered)}) exitWith {false};
if (isNull player || {!alive player}) exitWith {false};
if !(cameraOn in [player, vehicle player]) exitWith {false};
if (!isNull curatorCamera || {!isNull (findDisplay IDD_ZEUS)}) exitWith {false};
// Not over the map (user, 2026-10-17) - the boxes are of the world in front of him.
if (visibleMap) exitWith {false};
private _mode = currentVisionMode player;
if (_mode == VISION_MODE_TI) exitWith {false};

private _hmd = hmd player;
if (_hmd isEqualTo "") exitWith {false};

// [opted in, in day mode too], read once per goggle class.
private _flags = GVAR(nvgCache) get _hmd;
if (isNil "_flags") then {
    private _config = configFile >> "CfgWeapons" >> _hmd;
    _flags = [getNumber (_config >> QGVAR(enabled)) > 0, getNumber (_config >> QGVAR(day)) > 0];
    GVAR(nvgCache) set [_hmd, _flags];
};
_flags params ["_optedIn", "_day"];

_optedIn && {_mode == VISION_MODE_NVG || _day}
