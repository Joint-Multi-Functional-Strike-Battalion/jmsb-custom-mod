#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Puts the tube mask up or takes it down. Run on events only - the vision mode,
 * loadout, weapon, unit, vehicle, view or feature camera changing, the player
 * view changing, and the "NVG full screen" setting changing - never per frame.
 *
 * The mask is up only while every condition holds: the setting is off, the
 * player is alive and the camera (on foot or in his vehicle), not in Zeus,
 * looking through his own goggle (not a turret's optics or his binocular) in
 * its image-intensifier mode, and that goggle is a JMSB full-screen one.
 *
 * Arguments:
 * None (event arguments are ignored)
 *
 * Return Value:
 * Mask up <BOOL>
 *
 * Example:
 * [] call jmfsb_nvg_fnc_updateMask
 *
 * Public: No
 */

if (!hasInterface) exitWith {false};

private _mask = call {
    if (GVAR(showFullScreen)) exitWith {[]};
    if (isNull player || {!alive player}) exitWith {[]};
    if !(cameraOn in [player, vehicle player]) exitWith {[]};
    if (!isNull curatorCamera || {!isNull (findDisplay IDD_ZEUS)}) exitWith {[]};
    if (currentVisionMode player != VISION_MODE_NVG) exitWith {[]};
    // Through a turret's sight the picture is the vehicle's; through the
    // binocular it is the binocular's - ACE draws no goggle border for either.
    if (cameraView == "GUNNER" && {
        (!isNull objectParent player && {!([player] call CBA_fnc_canUseWeapon)})
        || {currentWeapon player isNotEqualTo "" && {currentWeapon player == binocular player}}
    }) exitWith {[]};
    [hmd player] call FUNC(maskTexture)
};

if (_mask isEqualTo []) exitWith {
    [] call FUNC(maskHide);
    false
};

_mask call FUNC(maskShow)
