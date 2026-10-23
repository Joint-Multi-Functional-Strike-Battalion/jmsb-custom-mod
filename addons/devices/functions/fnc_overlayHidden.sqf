#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether something on screen means the walking view must not be there:
 * the player is dead, he is looking down a sight or through a scope (the
 * GUNNER view - user, 2026-10-21: "phone needs to hide when using a scope"),
 * an arsenal is open (ACE's or the vanilla one), or he is in a spectator
 * (ACE's or the vanilla one). Dialogs and the map are
 * FUNC(overlayTick)'s own test; these are the screens that are displays, not
 * dialogs, and slip past `dialog`.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Hidden <BOOL>
 *
 * Example:
 * [] call jmfsb_devices_fnc_overlayHidden
 *
 * Public: No
 */

!alive player
|| {cameraView isEqualTo CAMERA_VIEW_SIGHT}
|| {!isNull findDisplay IDD_ACE_ARSENAL}
|| {!isNull (uiNamespace getVariable ["RscDisplayArsenal", displayNull])}
|| {missionNamespace getVariable ["ace_spectator_isSet", false]}
|| {!isNull findDisplay IDD_EG_SPECTATOR}
|| {!isNull (uiNamespace getVariable ["RscDisplayEGSpectator", displayNull])}
