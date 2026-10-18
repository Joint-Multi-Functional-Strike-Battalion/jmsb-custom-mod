#include "script_component.hpp"
/*
 * Author: JMSB
 * Whether the player's goggle fills the whole screen, so ECOTI's thermal window
 * should too (user, 2026-10-17). The same test jmfsb_nvg puts its tube mask
 * up on: a JMSB full-screen goggle (jmfsb_nvg_fullScreen = 1 in its config)
 * with that player's "NVG full screen" setting on. Any other goggle is seen
 * through ACE's tubes, and the window stays round.
 *
 * Read softly - without jmfsb_nvg loaded nothing is full screen.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Full screen <BOOL>
 *
 * Example:
 * [] call jmfsb_ecoti_fnc_isFullScreen
 *
 * Public: No
 */

if !(missionNamespace getVariable [QEGVAR(nvg,showFullScreen), false]) exitWith {false};

private _hmd = hmd player;
private _full = GVAR(fullScreenCache) get _hmd;
if (isNil "_full") then {
    _full = getNumber (configFile >> "CfgWeapons" >> _hmd >> QEGVAR(nvg,fullScreen)) > 0;
    GVAR(fullScreenCache) set [_hmd, _full];
};

_full
