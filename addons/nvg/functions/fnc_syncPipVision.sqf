#include "..\script_component.hpp"
/*
 * Author: JMSB
 * Puts a CBA scripted scope's picture-in-picture view in the goggle's mode
 * (user, 2026-10-17: "when you have nvgs on the scope nvg should also be on").
 * CBA renders the magnified view of its PiP scopes (the Vortex M157 on the
 * rifles among them) through its own camera and pins that to normal vision -
 * cba_optics_fnc_restartCamera sets setPiPEffect [0] and nothing changes it -
 * so at night the scope was a black disc inside a green goggle view.
 *
 * The goggles see through every scope (compatibility/nvg_optics_*, which leaves
 * a scope mode no visionMode of its own), so the player's vision mode in the
 * sight IS the goggle's: day, NVG or thermal. This gives the PiP the same. It
 * runs only while aiming down a sight; CBA restarting its camera puts the view
 * back to normal, so it is set again each tick rather than once.
 *
 * Arguments (CBA per-frame handler):
 * 0: Arguments <ARRAY> - unused
 * 1: Handle <NUMBER> - unused
 *
 * Return Value:
 * None
 *
 * Example:
 * [[], 0] call jmfsb_nvg_fnc_syncPipVision
 *
 * Public: No
 */

if (cameraView != "GUNNER") exitWith {};
if (isNull (missionNamespace getVariable [CBA_PIP_CAMERA, objNull])) exitWith {};

CBA_PIP_TARGET setPiPEffect [[PIP_NORMAL, PIP_NVG, PIP_TI] select ((currentVisionMode player) min PIP_TI)];
